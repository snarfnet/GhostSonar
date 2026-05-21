import SwiftUI

class AdMobManager: ObservableObject {
    static let shared = AdMobManager()

    let bannerAdUnitID = ""

    func configure() {}
}

struct BannerAdView: View {
    let adUnitID: String
    var body: some View { EmptyView() }
}
