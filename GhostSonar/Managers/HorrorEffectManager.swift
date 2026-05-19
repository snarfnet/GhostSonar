import SwiftUI
import AVFoundation
import AudioToolbox
import Combine

class HorrorEffectManager: ObservableObject {
    @Published var screenShake: CGFloat = 0
    @Published var glitchActive = false
    @Published var redFlashOpacity: Double = 0
    @Published var staticNoiseOpacity: Double = 0
    @Published var heartbeatScale: CGFloat = 1.0
    @Published var scanlineOffset: CGFloat = 0
    @Published var interferenceLines = false
    @Published var screenFlicker = false
    @Published var horrorTextVisible = false
    @Published var horrorText = ""

    private var audioPlayer: AVAudioPlayer?
    private var ambientPlayer: AVAudioPlayer?

    private let horrorMessages = [
        "IT SEES YOU",
        "DON'T LOOK BEHIND",
        "RUN",
        "IT'S HERE",
        "HELP ME",
        "GET OUT",
        "CAN YOU HEAR ME",
        "I'M RIGHT BEHIND YOU",
        "DON'T TURN AROUND",
        "WE ARE NOT ALONE"
    ]

    func triggerDetectionEffect(intensity: Double, threat: ThreatLevel) {
        switch threat {
        case .low:
            triggerMinorEffect()
        case .medium:
            triggerMediumEffect()
        case .high:
            triggerHighEffect()
        case .critical:
            triggerCriticalEffect()
        }

        // Haptic feedback
        if intensity > 0.3 {
            let impact = UIImpactFeedbackGenerator(style: intensity > 0.7 ? .heavy : .medium)
            impact.impactOccurred(intensity: intensity)
        }
    }

    private func triggerMinorEffect() {
        // Subtle static
        withAnimation(.easeInOut(duration: 0.3)) {
            staticNoiseOpacity = 0.1
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation { self.staticNoiseOpacity = 0 }
        }

        // Sonar ping haptic
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
    }

    private func triggerMediumEffect() {
        // Screen interference
        interferenceLines = true
        withAnimation(.easeInOut(duration: 0.2)) {
            staticNoiseOpacity = 0.2
            glitchActive = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation {
                self.interferenceLines = false
                self.staticNoiseOpacity = 0
                self.glitchActive = false
            }
        }

        // Vibration
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
    }

    private func triggerHighEffect() {
        // Glitch + shake + red tint
        withAnimation(.easeInOut(duration: 0.1)) {
            glitchActive = true
            redFlashOpacity = 0.15
            screenShake = 5
        }

        // Screen flicker
        screenFlicker = true

        // Horror text flash
        if Bool.random() {
            horrorText = horrorMessages.randomElement() ?? "IT'S HERE"
            horrorTextVisible = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                self.horrorTextVisible = false
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.easeOut(duration: 0.5)) {
                self.glitchActive = false
                self.redFlashOpacity = 0
                self.screenShake = 0
                self.screenFlicker = false
            }
        }

        // Heavy haptic
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
    }

    func triggerCriticalEffect() {
        // Full horror: rapid flashing, heavy shake, red overlay, horror text
        withAnimation(.easeInOut(duration: 0.05)) {
            glitchActive = true
            redFlashOpacity = 0.4
            screenShake = 12
            staticNoiseOpacity = 0.4
            interferenceLines = true
            screenFlicker = true
        }

        // Horror message
        horrorText = horrorMessages.randomElement() ?? "RUN"
        horrorTextVisible = true

        // Heartbeat effect
        startHeartbeat()

        // Heavy vibration pattern
        for i in 0..<4 {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.15) {
                AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.easeOut(duration: 1.0)) {
                self.glitchActive = false
                self.redFlashOpacity = 0
                self.screenShake = 0
                self.staticNoiseOpacity = 0
                self.interferenceLines = false
                self.screenFlicker = false
                self.horrorTextVisible = false
                self.heartbeatScale = 1.0
            }
        }
    }

    private func startHeartbeat() {
        let beats = [0.0, 0.15, 0.5, 0.65, 1.0, 1.15]
        for beat in beats {
            DispatchQueue.main.asyncAfter(deadline: .now() + beat) {
                withAnimation(.easeOut(duration: 0.1)) {
                    self.heartbeatScale = 1.05
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.easeIn(duration: 0.15)) {
                        self.heartbeatScale = 1.0
                    }
                }
                let impact = UIImpactFeedbackGenerator(style: .heavy)
                impact.impactOccurred(intensity: 1.0)
            }
        }
    }

    func triggerSonarPing() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred(intensity: 0.3)
    }
}
