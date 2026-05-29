import SwiftUI
import GoogleMobileAds

class AdMobManager: NSObject, ObservableObject {
    static let shared = AdMobManager()

    let bannerAdUnitID = "ca-app-pub-9404799280370656/4004772300"

    func configure() {
        MobileAds.shared.start(completionHandler: nil)
    }
}

struct BannerAdView: UIViewRepresentable {
    let adUnitID: String

    func makeUIView(context: Context) -> BannerView {
        let banner = BannerView(adSize: GADAdSizeBanner)
        banner.adUnitID = adUnitID
        banner.rootViewController = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }?
            .rootViewController
        banner.load(Request())
        return banner
    }

    func updateUIView(_ uiView: BannerView, context: Context) {}
}
