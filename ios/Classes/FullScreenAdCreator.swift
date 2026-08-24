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

@MainActor
final class FullScreenAdCreator {

    let messenger: FlutterBinaryMessenger

    private static var nextIdByChannelName: [String: Int] = [:]

    init(messenger: FlutterBinaryMessenger) {
        self.messenger = messenger
    }

    func createAppOpenAd(ad: AppOpenAd) -> Int {
        let viewController = AppOpenAdViewController()
        ad.delegate = viewController
        return createAd(channelName: appOpenAdChannelName, viewController: viewController) {
            AppOpenAdCommandProvider(ad: ad, onDestroy: $0, adViewController: viewController)
        }
    }

    func createInterstitialAd(ad: InterstitialAd) -> Int {
        let viewController = InterstitialAdViewController()
        ad.delegate = viewController
        return createAd(channelName: interstitialAdChannelName, viewController: viewController) {
            InterstitialAdCommandProvider(ad: ad, onDestroy: $0, adViewController: viewController)
        }
    }

    func createRewardedAd(ad: RewardedAd) -> Int {
        let viewController = RewardedAdViewController()
        ad.delegate = viewController
        return createAd(channelName: rewardedAdChannelName, viewController: viewController) {
            RewardedAdCommandProvider(ad: ad, onDestroy: $0, adViewController: viewController)
        }
    }

    private func createAd(
        channelName: String,
        viewController: BaseFullscreenAdViewController & NSObjectProtocol,
        providerFactory: (_ onDestroy: @escaping () -> Void) -> CommandProvider
    ) -> Int {
        let id = Self.nextIdByChannelName[channelName, default: 0]
        Self.nextIdByChannelName[channelName] = id + 1
        let name = "\(YandexMobileAdsPlugin.channelName).\(channelName).\(id)"
        let methodChannel = FlutterMethodChannel(name: name, binaryMessenger: messenger)
        let eventChannel = FlutterEventChannel(name: "\(name).events", binaryMessenger: messenger)
        let provider = providerFactory {
            methodChannel.setMethodCallHandler(nil)
            eventChannel.setStreamHandler(nil)
        }
        methodChannel.setMethodCallHandler(provider.callHandler)
        eventChannel.setStreamHandler(viewController)
        return id
    }

    private let appOpenAdChannelName = "appOpenAd"
    private let interstitialAdChannelName = "interstitialAd"
    private let rewardedAdChannelName = "rewardedAd"
}
