import SwiftUI
import AppTrackingTransparency
import GoogleMobileAds

@main
struct GhostSonarApp: App {
    @StateObject private var sensorManager = SensorManager()
    @StateObject private var ghostEngine = GhostDetectionEngine()
    @StateObject private var horrorManager = HorrorEffectManager()
    @StateObject private var adMobManager = AdMobManager.shared
    @Environment(\.scenePhase) private var scenePhase
    @State private var attRequested = false

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(sensorManager)
                .environmentObject(ghostEngine)
                .environmentObject(horrorManager)
                .preferredColorScheme(.dark)
                .onAppear {
                    Task { await MobileAds.shared.start() }
                    adMobManager.configure()
                }
                .onChange(of: scenePhase) { _, newPhase in
                    if newPhase == .active && !attRequested {
                        attRequested = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            ATTrackingManager.requestTrackingAuthorization { _ in }
                        }
                    }
                }
        }
    }
}
