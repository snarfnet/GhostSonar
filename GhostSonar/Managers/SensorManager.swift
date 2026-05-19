import Foundation
import CoreMotion
import AVFoundation
import Combine

class SensorManager: ObservableObject {
    @Published var snapshot = SensorSnapshot()
    @Published var isScanning = false
    @Published var emfLevel: Double = 0
    @Published var audioLevel: Double = 0
    @Published var pressureLevel: Double = 0
    @Published var vibrationLevel: Double = 0

    private let motionManager = CMMotionManager()
    private let altimeter = CMAltimeter()
    private var audioEngine: AVAudioEngine?
    private var pressureHistory: [Double] = []
    private let pressureWindowSize = 20

    func startScanning() {
        isScanning = true
        startMagnetometer()
        startAccelerometer()
        startBarometer()
        startAudioCapture()
    }

    func stopScanning() {
        isScanning = false
        motionManager.stopMagnetometerUpdates()
        motionManager.stopAccelerometerUpdates()
        motionManager.stopGyroUpdates()
        altimeter.stopRelativeAltitudeUpdates()
        audioEngine?.stop()
        audioEngine = nil
    }

    // MARK: - Magnetometer (EMF)
    private func startMagnetometer() {
        guard motionManager.isMagnetometerAvailable else { return }
        motionManager.magnetometerUpdateInterval = 0.05

        motionManager.startMagnetometerUpdates(to: .main) { [weak self] data, _ in
            guard let self, let data else { return }
            let field = data.magneticField
            let magnitude = sqrt(field.x * field.x + field.y * field.y + field.z * field.z)

            self.snapshot.magneticField = (field.x, field.y, field.z)
            self.snapshot.magneticMagnitude = magnitude

            // Normalize: Earth's field ~25-65 µT, anomalies go higher
            let normalized = min(max((magnitude - 20) / 100, 0), 1.0)
            self.emfLevel = normalized
        }
    }

    // MARK: - Accelerometer + Gyro (Vibration)
    private func startAccelerometer() {
        guard motionManager.isAccelerometerAvailable else { return }
        motionManager.accelerometerUpdateInterval = 0.05

        motionManager.startAccelerometerUpdates(to: .main) { [weak self] data, _ in
            guard let self, let data else { return }
            let a = data.acceleration
            // Remove gravity (~1.0), detect vibrations
            let magnitude = abs(sqrt(a.x * a.x + a.y * a.y + a.z * a.z) - 1.0)
            self.snapshot.accelerationMagnitude = magnitude
            self.vibrationLevel = min(magnitude * 5, 1.0)
        }

        if motionManager.isGyroAvailable {
            motionManager.gyroUpdateInterval = 0.05
            motionManager.startGyroUpdates(to: .main) { [weak self] data, _ in
                guard let self, let data else { return }
                let g = data.rotationRate
                self.snapshot.gyroMagnitude = sqrt(g.x * g.x + g.y * g.y + g.z * g.z)
            }
        }
    }

    // MARK: - Barometer (Pressure)
    private func startBarometer() {
        guard CMAltimeter.isRelativeAltitudeAvailable() else { return }

        altimeter.startRelativeAltitudeUpdates(to: .main) { [weak self] data, _ in
            guard let self, let data else { return }
            let pressure = data.pressure.doubleValue // kPa

            self.pressureHistory.append(pressure)
            if self.pressureHistory.count > self.pressureWindowSize {
                self.pressureHistory.removeFirst()
            }

            self.snapshot.pressure = pressure

            // Detect pressure changes
            if self.pressureHistory.count >= 2 {
                let delta = abs(pressure - self.pressureHistory[0])
                self.snapshot.pressureDelta = delta
                self.pressureLevel = min(delta * 50, 1.0) // Amplify small changes
            }
        }
    }

    // MARK: - Audio (EVP)
    private func startAudioCapture() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.record, mode: .measurement)
            try session.setActive(true)
        } catch {
            return
        }

        audioEngine = AVAudioEngine()
        guard let audioEngine else { return }

        let inputNode = audioEngine.inputNode
        let format = inputNode.outputFormat(forBus: 0)

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
            guard let self else { return }
            let channelData = buffer.floatChannelData?[0]
            let frameLength = Int(buffer.frameLength)
            guard let data = channelData, frameLength > 0 else { return }

            // RMS level
            var sum: Float = 0
            for i in 0..<frameLength {
                sum += data[i] * data[i]
            }
            let rms = sqrt(sum / Float(frameLength))
            let db = 20 * log10(max(rms, 1e-7))
            let normalized = Double(min(max((db + 50) / 50, 0), 1.0))

            // Simple peak frequency detection
            var maxVal: Float = 0
            var maxIdx = 0
            for i in 0..<frameLength {
                let absVal = abs(data[i])
                if absVal > maxVal {
                    maxVal = absVal
                    maxIdx = i
                }
            }

            DispatchQueue.main.async {
                self.snapshot.audioLevel = normalized
                self.snapshot.audioFreqPeak = Double(maxIdx) * format.sampleRate / Double(frameLength)
                self.audioLevel = normalized
            }
        }

        do {
            try audioEngine.start()
        } catch {
            // Audio capture failed
        }
    }
}
