import SwiftUI
import GoogleMobileAds

class AdMobManager: ObservableObject {
    static let shared = AdMobManager()
    let bannerAdUnitID = "ca-app-pub-3940256099942544/2934735716"
    func configure() {
        MobileAds.shared.start()
    }
}

struct BannerAdView: UIViewControllerRepresentable {
    let adUnitID: String

    func makeUIViewController(context: Context) -> UIViewController {
        let controller = UIViewController()
        controller.view.backgroundColor = .clear

        let banner = GADBannerView(adSize: GADAdSizeBanner)
        banner.adUnitID = adUnitID
        banner.rootViewController = controller
        banner.translatesAutoresizingMaskIntoConstraints = false

        controller.view.addSubview(banner)
        NSLayoutConstraint.activate([
            banner.centerXAnchor.constraint(equalTo: controller.view.centerXAnchor),
            banner.centerYAnchor.constraint(equalTo: controller.view.centerYAnchor)
        ])

        banner.load(GADRequest())
        return controller
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}
