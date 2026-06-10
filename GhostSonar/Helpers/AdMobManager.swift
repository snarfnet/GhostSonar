import SwiftUI
import GoogleMobileAds

class AdMobManager: NSObject, ObservableObject {
    static let shared = AdMobManager()

    let bannerAdUnitID = "ca-app-pub-9404799280370656/5595301558"

    func configure() {
        Task { await MobileAds.shared.start() }
    }
}

struct BannerAdView: UIViewRepresentable {
    let adUnitID: String

    func makeUIView(context: Context) -> BannerView {
        let banner = BannerView()
        banner.adUnitID = adUnitID
        banner.translatesAutoresizingMaskIntoConstraints = false
        DispatchQueue.main.async {
            guard let windowScene = UIApplication.shared.connectedScenes
                .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene
                ?? UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
            banner.rootViewController = windowScene.keyWindow?.rootViewController
            banner.load(Request())
        }
        return banner
    }

    func updateUIView(_ uiView: BannerView, context: Context) {}
}
