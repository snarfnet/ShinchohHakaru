import SwiftUI
import GoogleMobileAds

class AdMobManager: ObservableObject {
    static let shared = AdMobManager()
    let bannerAdUnitID = "ca-app-pub-9404799280370656/2948905613"
    func configure() {
        GADMobileAds.sharedInstance().start(completionHandler: nil)
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
