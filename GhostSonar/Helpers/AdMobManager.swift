import SwiftUI
import GoogleMobileAds

class AdMobManager: ObservableObject {
    static let shared = AdMobManager()

    // Replace with actual AdMob IDs after registration
    let bannerAdUnitID = "ca-app-pub-3940256099942544/2934735716" // Test ID
    let appID = "ca-app-pub-XXXXXXXXXXXXXXXX~XXXXXXXXXX" // Replace

    func configure() {
        GADMobileAds.sharedInstance().start(completionHandler: nil)
    }
}

struct BannerAdView: UIViewRepresentable {
    let adUnitID: String

    func makeUIView(context: Context) -> GADBannerView {
        let banner = GADBannerView(adSize: GADAdSizeBanner)
        banner.adUnitID = adUnitID
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            banner.rootViewController = rootVC
        }
        banner.load(GADRequest())
        return banner
    }

    func updateUIView(_ uiView: GADBannerView, context: Context) {}
}
