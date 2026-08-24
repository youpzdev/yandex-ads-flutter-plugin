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

final class InterstitialAdLoaderCommandProvider: LoadDelegate, CommandProvider {

    var commands: [Command] {
        [
            .command(.interstitialAdLoader(.load), loadInterstitialAd),
            .command(.interstitialAdLoader(.cancelLoading), cancelLoading),
            .command(.interstitialAdLoader(.destroy), destroyInterstitialAdLoader),
        ]
    }

    private let onDestroy: () -> Void
    private let adLoader: InterstitialAdLoader
    private let loadDelegate: FullscreenAdLoadDelegate

    let name = "interstitialAdLoader"

    init(adLoader: InterstitialAdLoader, loadDelegate: FullscreenAdLoadDelegate, onDestroy: @escaping () -> Void) {
        self.adLoader = adLoader
        self.loadDelegate = loadDelegate
        self.onDestroy = onDestroy
    }

    private func loadInterstitialAd(args: Any?, result: MethodCallResult) {
        guard let args = args as? [String: Any?] else {
            return result.error(.argsIsNotMap)
        }
        let requestId = args["requestId"] as? Int ?? 0
        let adRequest = args.toAdRequest()
        adLoader.loadAd(with: adRequest) { [weak self] loadResult in
            switch loadResult {
            case .success(let ad):
                self?.loadDelegate.reportInterstitialAdLoaded(ad: ad, adInfo: ad.adInfo, requestId: requestId)
            case .failure(let error):
                self?.loadDelegate.reportAdFailedToLoad(error: error, adUnitId: adRequest.adUnitID, requestId: requestId)
            }
        }
        result.success()
    }

    private func cancelLoading(args: Any?, result: MethodCallResult) {
        adLoader.cancelLoading()
        result.success()
    }

    private func destroyInterstitialAdLoader(args: Any?, result: MethodCallResult) {
        onDestroy()
        result.success()
    }
}
