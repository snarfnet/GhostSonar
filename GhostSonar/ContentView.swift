import SwiftUI

struct ContentView: View {
    @EnvironmentObject var sensorManager: SensorManager
    @EnvironmentObject var ghostEngine: GhostDetectionEngine
    @EnvironmentObject var horrorManager: HorrorEffectManager

    @State private var isActive = false
    @State private var showLog = false
    @State private var previousThreat: ThreatLevel = .low
    @State private var statusText = "SYSTEMS OFFLINE"
    @State private var submarineDepth = "DEPTH: 000m"
    @Environment(\.horizontalSizeClass) private var sizeClass

    private let soundGen = SoundGenerator.shared
    private var iPad: Bool { sizeClass == .regular }

    var body: some View {
        ZStack {
            // Background - submarine interior dark
            LinearGradient(
                colors: [
                    Color(red: 0.02, green: 0.04, blue: 0.02),
                    Color(red: 0.01, green: 0.02, blue: 0.01),
                    Color.black
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Top HUD bar
                topHUD
                    .padding(.horizontal)
                    .padding(.top, 4)

                // Status bar
                statusBar
                    .padding(.horizontal)
                    .padding(.top, 4)

                // Main sonar radar
                SonarRadarView()
                    .padding(16)
                    .scaleEffect(horrorManager.heartbeatScale)
                    .offset(x: horrorManager.screenShake * (Bool.random() ? 1 : -1),
                            y: horrorManager.screenShake * (Bool.random() ? 1 : -1))

                // Threat indicator
                threatIndicator
                    .padding(.horizontal)

                // Sensor panels
                SensorPanelView()
                    .padding(.vertical, 8)

                // Detection log (collapsible)
                if showLog {
                    DetectionLogView()
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                // Control buttons
                controlBar
                    .padding(.horizontal)
                    .padding(.bottom, 4)

                // AdMob Banner
                BannerAdView(adUnitID: AdMobManager.shared.bannerAdUnitID)
                    .frame(height: 50)
            }

            // Horror overlay (always on top)
            HorrorOverlayView()
                .allowsHitTesting(false)
        }
        .onChange(of: ghostEngine.currentThreat) { _, newThreat in
            if newThreat != previousThreat {
                horrorManager.triggerDetectionEffect(
                    intensity: ghostEngine.detections.last?.intensity ?? 0.5,
                    threat: newThreat
                )
                if newThreat != .low {
                    soundGen.playDetectionAlert(threat: newThreat)
                }
                previousThreat = newThreat
            }
        }
        .onChange(of: ghostEngine.isEntityDetected) { _, detected in
            if detected {
                statusText = "!! CONTACT DETECTED !!"
            } else if isActive {
                statusText = "SCANNING..."
            }
        }
    }

    // MARK: - Top HUD
    private var topHUD: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("GHOST SONAR")
                    .font(.system(size: iPad ? 26 : 18, weight: .black, design: .monospaced))
                    .foregroundColor(Color("sonarGreen"))

                Text("PARANORMAL DETECTION SYSTEM v2.1")
                    .font(.system(size: iPad ? 15 : 11, design: .monospaced))
                    .foregroundColor(Color("sonarGreen").opacity(0.5))
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(Date(), style: .time)
                    .font(.system(size: iPad ? 20 : 14, weight: .medium, design: .monospaced))
                    .foregroundColor(Color("sonarGreen").opacity(0.8))

                Text(submarineDepth)
                    .font(.system(size: iPad ? 16 : 12, design: .monospaced))
                    .foregroundColor(Color("sonarGreen").opacity(0.4))
            }
        }
    }

    // MARK: - Status Bar
    private var statusBar: some View {
        HStack(spacing: 8) {
            // Scanning indicator
            Circle()
                .fill(isActive ? Color("sonarGreen") : Color.gray.opacity(0.3))
                .frame(width: 6, height: 6)
                .shadow(color: isActive ? Color("sonarGreen") : .clear, radius: 4)
                .opacity(isActive ? (ghostEngine.isEntityDetected ? 0.3 : 1.0) : 0.5)
                .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: isActive)

            Text(statusText)
                .font(.system(size: iPad ? 18 : 13, weight: .bold, design: .monospaced))
                .foregroundColor(ghostEngine.isEntityDetected ? Color("sonarRed") : Color("sonarGreen"))
                .animation(.easeInOut(duration: 0.3), value: statusText)

            Spacer()

            if isActive && ghostEngine.scanProgress < 1.0 {
                Text("CALIBRATING \(Int(ghostEngine.scanProgress * 100))%")
                    .font(.system(size: iPad ? 16 : 12, design: .monospaced))
                    .foregroundColor(Color("sonarYellow"))
            }

            Text("CONTACTS: \(ghostEngine.detectionCount)")
                .font(.system(size: iPad ? 16 : 12, design: .monospaced))
                .foregroundColor(Color("sonarGreen").opacity(0.6))
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(Color("sonarGreen").opacity(0.05))
        .cornerRadius(4)
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(Color("sonarGreen").opacity(0.15), lineWidth: 0.5)
        )
    }

    // MARK: - Threat Indicator
    private var threatIndicator: some View {
        HStack(spacing: 4) {
            ForEach(["LOW", "MED", "HIGH", "CRIT"], id: \.self) { level in
                let isActive = isThreatActive(level)
                VStack(spacing: 2) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(threatColor(level).opacity(isActive ? 0.9 : 0.15))
                        .frame(height: 4)
                        .shadow(color: isActive ? threatColor(level) : .clear, radius: 4)

                    Text(level)
                        .font(.system(size: iPad ? 15 : 11, weight: .bold, design: .monospaced))
                        .foregroundColor(threatColor(level).opacity(isActive ? 0.9 : 0.3))
                }
            }
        }
    }

    private func isThreatActive(_ level: String) -> Bool {
        switch (level, ghostEngine.currentThreat) {
        case ("LOW", .low), ("LOW", .medium), ("LOW", .high), ("LOW", .critical): return true
        case ("MED", .medium), ("MED", .high), ("MED", .critical): return true
        case ("HIGH", .high), ("HIGH", .critical): return true
        case ("CRIT", .critical): return true
        default: return false
        }
    }

    private func threatColor(_ level: String) -> Color {
        switch level {
        case "LOW": return Color("sonarGreen")
        case "MED": return Color("sonarYellow")
        case "HIGH": return Color("sonarOrange")
        case "CRIT": return Color("sonarRed")
        default: return .gray
        }
    }

    // MARK: - Control Bar
    private var controlBar: some View {
        HStack(spacing: 12) {
            // Scan toggle
            Button {
                toggleScanning()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: isActive ? "stop.fill" : "antenna.radiowaves.left.and.right")
                        .font(.system(size: iPad ? 22 : 16))
                    Text(isActive ? "STOP SCAN" : "BEGIN SCAN")
                        .font(.system(size: iPad ? 18 : 14, weight: .bold, design: .monospaced))
                }
                .foregroundColor(isActive ? Color("sonarRed") : Color("sonarGreen"))
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(isActive ? Color("sonarRed") : Color("sonarGreen"), lineWidth: 1.5)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill((isActive ? Color("sonarRed") : Color("sonarGreen")).opacity(0.1))
                        )
                )
            }

            // Log toggle
            Button {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showLog.toggle()
                }
            } label: {
                Image(systemName: "list.bullet.rectangle")
                    .font(.system(size: 16))
                    .foregroundColor(Color("sonarGreen"))
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color("sonarGreen").opacity(0.5), lineWidth: 1)
                    )
            }

            // Sound ping test
            Button {
                soundGen.playSonarPing()
            } label: {
                Image(systemName: "speaker.wave.2")
                    .font(.system(size: 16))
                    .foregroundColor(Color("sonarGreen"))
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color("sonarGreen").opacity(0.5), lineWidth: 1)
                    )
            }
        }
    }

    // MARK: - Actions
    private func toggleScanning() {
        if isActive {
            sensorManager.stopScanning()
            ghostEngine.stopDetection()
            soundGen.stopAll()
            statusText = "SYSTEMS OFFLINE"
        } else {
            sensorManager.startScanning()
            ghostEngine.bind(to: sensorManager)
            ghostEngine.startDetection()
            soundGen.playSonarPing()
            statusText = "INITIALIZING..."
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                if self.isActive { self.statusText = "SCANNING..." }
            }
        }
        isActive.toggle()
    }
}
