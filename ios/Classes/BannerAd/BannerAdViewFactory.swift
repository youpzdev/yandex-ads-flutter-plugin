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

final class BannerAdViewFactory: NSObject, FlutterPlatformViewFactory {

    private let messenger: FlutterBinaryMessenger
    private let bannerAdSizeFactory: BannerAdSizeFactory

    init(messenger: FlutterBinaryMessenger, bannerAdSizeFactory: BannerAdSizeFactory) {
        self.messenger = messenger
        self.bannerAdSizeFactory = bannerAdSizeFactory
    }

    func create(
        withFrame frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?
    ) -> FlutterPlatformView {
        let params = args as? [String: Any?] ?? [:]
        let id: Int = params[.id] ?? -1
        let adSize = bannerAdSizeFactory.createFromCommandParams(params: params)

        let delegate = FlutterBannerAdViewDelegate()
        let name = "\(YandexMobileAdsPlugin.channelName).\(bannerAdChannelName).\(id)"
        let methodChannel = FlutterMethodChannel(name: name, binaryMessenger: messenger)
        let eventChannel = FlutterEventChannel(name: "\(name).events", binaryMessenger: messenger)
        let banner = FlutterBannerAdView(
            adSize: adSize,
            delegate: delegate,
            methodChannel: methodChannel,
            eventChannel: eventChannel
        )
        let provider = BannerAdCommandProvider(banner: banner) {
            methodChannel.setMethodCallHandler(nil)
            eventChannel.setStreamHandler(nil)
        }
        methodChannel.setMethodCallHandler(provider.callHandler)
        eventChannel.setStreamHandler(delegate)

        return banner
    }

    func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
        FlutterStandardMessageCodec.sharedInstance()
    }

    private let bannerAdChannelName = "bannerAd"
}

private enum BannerAdCreationParameter: String {
    case id
}

private extension Dictionary where Key == String {
    subscript<T>(_ key: BannerAdCreationParameter) -> T? {
        self[key.rawValue] as? T
    }
}
