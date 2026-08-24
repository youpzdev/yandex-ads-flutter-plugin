/*
 * This file is a part of the Yandex Advertising Network
 *
 * Version for Flutter (C) 2023 YANDEX
 *
 * You may not use this file except in compliance with the License.
 * You may obtain a copy of the License at https://legal.yandex.com/partner_ch/
 */

import Flutter
import YandexMobileAds

final class FlutterBannerAdView: NSObject, FlutterPlatformView {

    let banner: BannerAdView
    let wrappedView: UIView

    private weak var methodChannel: FlutterMethodChannel?
    private weak var eventChannel: FlutterEventChannel?

    init(
        adSize: BannerAdSize,
        delegate: BannerAdViewDelegate,
        methodChannel: FlutterMethodChannel,
        eventChannel: FlutterEventChannel
    ) {
        banner = BannerAdView(adSize: adSize)
        banner.accessibilityIdentifier = bannerAccessibilityIdentifier
        banner.delegate = delegate

        self.methodChannel = methodChannel
        self.eventChannel = eventChannel

        wrappedView = UIView()
        wrappedView.addSubview(banner)
        banner.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            banner.topAnchor.constraint(equalTo: wrappedView.topAnchor),
            banner.bottomAnchor.constraint(equalTo: wrappedView.bottomAnchor),
            banner.leadingAnchor.constraint(equalTo: wrappedView.leadingAnchor),
            banner.trailingAnchor.constraint(equalTo: wrappedView.trailingAnchor),
        ])
    }

    func view() -> UIView {
        wrappedView
    }

    private let bannerAccessibilityIdentifier = "banner-ad"
}
