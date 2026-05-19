import Foundation
import Combine

class GhostDetectionEngine: ObservableObject {
    @Published var detections: [GhostReading] = []
    @Published var currentThreat: ThreatLevel = .low
    @Published var isEntityDetected = false
    @Published var detectionCount = 0
    @Published var scanProgress: Double = 0

    private var sensorManager: SensorManager?
    private var timer: Timer?
    private var baselineMagnetic: Double?
    private var baselinePressure: Double?
    private var calibrationSamples = 0
    private let calibrationTarget = 20

    // Thresholds for detection
    private let emfThreshold = 0.35
    private let audioThreshold = 0.4
    private let pressureThreshold = 0.25
    private let vibrationThreshold = 0.3

    func bind(to sensorManager: SensorManager) {
        self.sensorManager = sensorManager
    }

    func startDetection() {
        baselineMagnetic = nil
        baselinePressure = nil
        calibrationSamples = 0
        detections = []
        detectionCount = 0

        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.analyze()
        }
    }

    func stopDetection() {
        timer?.invalidate()
        timer = nil
        isEntityDetected = false
        currentThreat = .low
    }

    private func analyze() {
        guard let sm = sensorManager else { return }
        let snap = sm.snapshot

        // Calibration phase
        if calibrationSamples < calibrationTarget {
            if baselineMagnetic == nil {
                baselineMagnetic = snap.magneticMagnitude
                baselinePressure = snap.pressure
            } else {
                baselineMagnetic = (baselineMagnetic! * Double(calibrationSamples) + snap.magneticMagnitude) / Double(calibrationSamples + 1)
                if snap.pressure > 0 {
                    baselinePressure = (baselinePressure! * Double(calibrationSamples) + snap.pressure) / Double(calibrationSamples + 1)
                }
            }
            calibrationSamples += 1
            scanProgress = Double(calibrationSamples) / Double(calibrationTarget)
            return
        }

        scanProgress = 1.0

        var signals: [GhostSignalType] = []
        var maxIntensity: Double = 0

        // EMF check
        if sm.emfLevel > emfThreshold {
            signals.append(.emf)
            maxIntensity = max(maxIntensity, sm.emfLevel)
        }

        // EVP check
        if sm.audioLevel > audioThreshold {
            signals.append(.evp)
            maxIntensity = max(maxIntensity, sm.audioLevel)
        }

        // Pressure check
        if sm.pressureLevel > pressureThreshold {
            signals.append(.pressure)
            maxIntensity = max(maxIntensity, sm.pressureLevel)
        }

        // Vibration check
        if sm.vibrationLevel > vibrationThreshold {
            signals.append(.vibration)
            maxIntensity = max(maxIntensity, sm.vibrationLevel)
        }

        // Generate detection if any signal crosses threshold
        if !signals.isEmpty {
            let type: GhostSignalType = signals.count >= 2 ? .multiSensor : signals[0]
            let intensity = signals.count >= 2 ? min(maxIntensity * 1.3, 1.0) : maxIntensity

            let reading = GhostReading(
                timestamp: Date(),
                type: type,
                intensity: intensity,
                angle: Double.random(in: 0..<(2 * .pi)),
                distance: Double.random(in: 0.2...0.9),
                description: generateDescription(type: type, intensity: intensity)
            )

            detections.append(reading)
            if detections.count > 50 {
                detections.removeFirst()
            }
            detectionCount += 1

            isEntityDetected = intensity > 0.5
            currentThreat = reading.threatLevel
        } else {
            // Decay threat level
            if currentThreat != .low {
                isEntityDetected = false
                currentThreat = .low
            }
        }
    }

    private func generateDescription(type: GhostSignalType, intensity: Double) -> String {
        let descriptions: [GhostSignalType: [String]] = [
            .emf: [
                "Electromagnetic field distortion detected",
                "Abnormal magnetic fluctuation",
                "EMF spike - possible entity presence",
                "Strong electromagnetic anomaly"
            ],
            .evp: [
                "Audio anomaly captured",
                "Unexplained sound pattern",
                "EVP frequency detected",
                "Anomalous audio signature"
            ],
            .pressure: [
                "Barometric pressure drop",
                "Atmospheric disturbance",
                "Sudden pressure change detected",
                "Cold spot indicator"
            ],
            .vibration: [
                "Unexplained vibration detected",
                "Physical disturbance sensed",
                "Motion anomaly detected",
                "Kinetic energy fluctuation"
            ],
            .multiSensor: [
                "WARNING: Multiple sensor anomaly",
                "ALERT: Multi-spectrum detection",
                "CAUTION: Strong entity signature",
                "DANGER: Full spectrum contact"
            ]
        ]

        let options = descriptions[type] ?? ["Unknown signal detected"]
        return options.randomElement() ?? options[0]
    }
}
