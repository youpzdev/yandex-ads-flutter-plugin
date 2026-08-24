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

final class CreateAdLoaderCommandProvider: CommandProvider {

    let messenger: FlutterBinaryMessenger
    var commands: [Command] {
        [
            .command(.createAdLoader(.interstitialAdLoader), createInterstitialAdLoader),
            .command(.createAdLoader(.rewardedAdLoader), createRewardedAdLoader),
            .command(.createAdLoader(.appOpenAdLoader), createAppOpenAdLoader),
        ]
    }

    let name = "createAdLoader"

    init(messenger: FlutterBinaryMessenger) {
        self.messenger = messenger
    }

    @MainActor
    private func createAppOpenAdLoader(args: Any?, result: MethodCallResult) {
        let adLoader = AppOpenAdLoader()
        let adCreator = FullScreenAdCreator(messenger: messenger)
        let loadDelegate = FullscreenAdLoadDelegate(adCreator: adCreator, adType: .appOpen)
        createAdLoader(args: args, result: result, channelName: appOpenAdLoaderChannelName,
                       delegate: loadDelegate)
        {
            AppOpenAdLoaderCommandProvider(adLoader: adLoader, loadDelegate: loadDelegate, onDestroy: $0)
        }
    }

    @MainActor
    private func createInterstitialAdLoader(args: Any?, result: MethodCallResult) {
        let adLoader = InterstitialAdLoader()
        let adCreator = FullScreenAdCreator(messenger: messenger)
        let loadDelegate = FullscreenAdLoadDelegate(adCreator: adCreator, adType: .interstitial)
        createAdLoader(args: args, result: result, channelName: interstitialAdLoaderChannelName, delegate: loadDelegate) {
            InterstitialAdLoaderCommandProvider(adLoader: adLoader, loadDelegate: loadDelegate, onDestroy: $0)
        }
    }

    @MainActor
    private func createRewardedAdLoader(args: Any?, result: MethodCallResult) {
        let adLoader = RewardedAdLoader()
        let adCreator = FullScreenAdCreator(messenger: messenger)
        let loadDelegate = FullscreenAdLoadDelegate(adCreator: adCreator, adType: .rewarded)
        createAdLoader(args: args, result: result, channelName: rewardedAdLoaderChannelName, delegate: loadDelegate) {
            RewardedAdLoaderCommandProvider(adLoader: adLoader, loadDelegate: loadDelegate, onDestroy: $0)
        }
    }

    private func createAdLoader(
        args: Any?,
        result: MethodCallResult,
        channelName: String,
        delegate: FullscreenAdLoadDelegate,
        providerFactory: (_ onDestroy: @escaping () -> Void) -> CommandProvider
    ) {
        let params = args as? [String: Any?]
        let id = params?["id"] as? Int ?? 0
        let name = "\(YandexMobileAdsPlugin.channelName).\(channelName).\(id)"
        let methodChannel = FlutterMethodChannel(name: name, binaryMessenger: messenger)
        let eventChannel = FlutterEventChannel(name: "\(name).events", binaryMessenger: messenger)
        let provider = providerFactory {
            methodChannel.setMethodCallHandler(nil)
            eventChannel.setStreamHandler(nil)
        }
        methodChannel.setMethodCallHandler(provider.callHandler)
        eventChannel.setStreamHandler(delegate)
        result.success(id)
    }

    private let appOpenAdLoaderChannelName = "appOpenAdLoader"
    private let interstitialAdLoaderChannelName = "interstitialAdLoader"
    private let rewardedAdLoaderChannelName = "rewardedAdLoader"
}
