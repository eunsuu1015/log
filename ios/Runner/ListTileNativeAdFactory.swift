import google_mobile_ads
import UIKit

class ListTileNativeAdFactory: FLTNativeAdFactory {
    func createNativeAd(
        _ nativeAd: GADNativeAd,
        customOptions: [AnyHashable: Any]? = nil
    ) -> GADNativeAdView? {
        let nativeAdView = GADNativeAdView()
        nativeAdView.backgroundColor = .systemBackground

        // 아이콘
        let iconView = UIImageView()
        iconView.contentMode = .scaleAspectFit
        iconView.translatesAutoresizingMaskIntoConstraints = false
        if let icon = nativeAd.icon { iconView.image = icon.image }
        nativeAdView.iconView = iconView

        // 광고 배지
        let badgeLabel = UILabel()
        badgeLabel.text = "광고"
        badgeLabel.font = .systemFont(ofSize: 10)
        badgeLabel.textColor = .white
        badgeLabel.backgroundColor = UIColor(red: 1.0, green: 0.76, blue: 0.03, alpha: 1)
        badgeLabel.layer.cornerRadius = 2
        badgeLabel.layer.masksToBounds = true
        badgeLabel.translatesAutoresizingMaskIntoConstraints = false

        // 제목
        let headlineLabel = UILabel()
        headlineLabel.text = nativeAd.headline
        headlineLabel.font = .boldSystemFont(ofSize: 14)
        headlineLabel.numberOfLines = 1
        headlineLabel.translatesAutoresizingMaskIntoConstraints = false
        nativeAdView.headlineView = headlineLabel

        // 본문
        let bodyLabel = UILabel()
        bodyLabel.text = nativeAd.body
        bodyLabel.font = .systemFont(ofSize: 12)
        bodyLabel.textColor = .secondaryLabel
        bodyLabel.numberOfLines = 1
        bodyLabel.translatesAutoresizingMaskIntoConstraints = false
        nativeAdView.bodyView = bodyLabel

        // 제목 줄 (배지 + 제목)
        let titleStack = UIStackView(arrangedSubviews: [badgeLabel, headlineLabel])
        titleStack.axis = .horizontal
        titleStack.spacing = 6
        titleStack.alignment = .center
        titleStack.translatesAutoresizingMaskIntoConstraints = false

        // 텍스트 스택
        let textStack = UIStackView(arrangedSubviews: [titleStack, bodyLabel])
        textStack.axis = .vertical
        textStack.spacing = 2
        textStack.translatesAutoresizingMaskIntoConstraints = false

        // 메인 스택
        let mainStack = UIStackView(arrangedSubviews: [iconView, textStack])
        mainStack.axis = .horizontal
        mainStack.spacing = 12
        mainStack.alignment = .center
        mainStack.translatesAutoresizingMaskIntoConstraints = false

        nativeAdView.addSubview(mainStack)
        NSLayoutConstraint.activate([
            iconView.widthAnchor.constraint(equalToConstant: 40),
            iconView.heightAnchor.constraint(equalToConstant: 40),
            mainStack.topAnchor.constraint(equalTo: nativeAdView.topAnchor, constant: 12),
            mainStack.bottomAnchor.constraint(equalTo: nativeAdView.bottomAnchor, constant: -12),
            mainStack.leadingAnchor.constraint(equalTo: nativeAdView.leadingAnchor, constant: 16),
            mainStack.trailingAnchor.constraint(equalTo: nativeAdView.trailingAnchor, constant: -16),
        ])

        nativeAdView.nativeAd = nativeAd
        return nativeAdView
    }
}
