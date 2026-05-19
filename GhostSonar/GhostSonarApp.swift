import SwiftUI

@main
struct GhostSonarApp: App {
    @StateObject private var sensorManager = SensorManager()
    @StateObject private var ghostEngine = GhostDetectionEngine()
    @StateObject private var horrorManager = HorrorEffectManager()
    @StateObject private var adMobManager = AdMobManager.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(sensorManager)
                .environmentObject(ghostEngine)
                .environmentObject(horrorManager)
                .preferredColorScheme(.dark)
                .onAppear {
                    adMobManager.configure()
                }
        }
    }
}
