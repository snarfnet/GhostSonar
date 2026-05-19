import AVFoundation
import AudioToolbox

class SoundGenerator {
    static let shared = SoundGenerator()

    private var audioEngine: AVAudioEngine?
    private var playerNode: AVAudioPlayerNode?
    private var isPlaying = false

    // Generate sonar ping sound
    func playSonarPing() {
        let sampleRate: Double = 44100
        let duration: Double = 0.3
        let frequency: Double = 1200
        let frameCount = Int(sampleRate * duration)

        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1),
              let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(frameCount)) else { return }

        buffer.frameLength = AVAudioFrameCount(frameCount)
        let data = buffer.floatChannelData![0]

        for i in 0..<frameCount {
            let t = Double(i) / sampleRate
            let envelope = exp(-t * 8) // Fast decay
            let signal = sin(2 * .pi * frequency * t) * envelope * 0.3
            data[i] = Float(signal)
        }

        playBuffer(buffer, format: format)
    }

    // Generate creepy ambient drone
    func playCreepyDrone(duration: Double = 2.0) {
        let sampleRate: Double = 44100
        let frameCount = Int(sampleRate * duration)

        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1),
              let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(frameCount)) else { return }

        buffer.frameLength = AVAudioFrameCount(frameCount)
        let data = buffer.floatChannelData![0]

        for i in 0..<frameCount {
            let t = Double(i) / sampleRate
            let envelope = sin(.pi * t / duration) * 0.15
            // Low frequency drone with dissonant harmonics
            let f1 = sin(2 * .pi * 55 * t)
            let f2 = sin(2 * .pi * 58 * t) * 0.7 // Slightly detuned
            let f3 = sin(2 * .pi * 110.5 * t) * 0.3
            let noise = Double.random(in: -0.05...0.05) // Subtle noise
            data[i] = Float((f1 + f2 + f3 + noise) * envelope)
        }

        playBuffer(buffer, format: format)
    }

    // Detection alert sound
    func playDetectionAlert(threat: ThreatLevel) {
        let sampleRate: Double = 44100
        let duration: Double = threat == .critical ? 1.0 : 0.5
        let frameCount = Int(sampleRate * duration)

        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1),
              let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(frameCount)) else { return }

        buffer.frameLength = AVAudioFrameCount(frameCount)
        let data = buffer.floatChannelData![0]

        for i in 0..<frameCount {
            let t = Double(i) / sampleRate
            let progress = t / duration

            switch threat {
            case .low:
                let freq = 800.0
                data[i] = Float(sin(2 * .pi * freq * t) * exp(-t * 6) * 0.2)
            case .medium:
                let freq = 600 + progress * 400
                data[i] = Float(sin(2 * .pi * freq * t) * exp(-t * 4) * 0.25)
            case .high:
                let freq = 400 + sin(t * 20) * 200
                let envelope = exp(-t * 3) * 0.3
                data[i] = Float(sin(2 * .pi * freq * t) * envelope)
            case .critical:
                // Alarm-like sound
                let freq = 300 + sin(t * 8) * 300
                let pulse = sin(t * 12) > 0 ? 1.0 : 0.3
                data[i] = Float(sin(2 * .pi * freq * t) * 0.35 * pulse)
            }
        }

        playBuffer(buffer, format: format)
    }

    private func playBuffer(_ buffer: AVAudioPCMBuffer, format: AVAudioFormat) {
        stopAll()

        audioEngine = AVAudioEngine()
        playerNode = AVAudioPlayerNode()
        guard let engine = audioEngine, let player = playerNode else { return }

        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: format)

        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            try engine.start()
            player.play()
            player.scheduleBuffer(buffer) { [weak self] in
                DispatchQueue.main.async {
                    self?.isPlaying = false
                }
            }
            isPlaying = true
        } catch {
            // Sound playback failed
        }
    }

    func stopAll() {
        playerNode?.stop()
        audioEngine?.stop()
        isPlaying = false
    }
}
