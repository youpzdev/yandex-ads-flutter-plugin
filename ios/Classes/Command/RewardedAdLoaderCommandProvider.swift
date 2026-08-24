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

final class RewardedAdLoaderCommandProvider: LoadDelegate, CommandProvider {

    var commands: [Command] {
        [
            .command(.rewardedAdLoader(.load), loadRewardedAd),
            .command(.rewardedAdLoader(.cancelLoading), cancelLoading),
            .command(.rewardedAdLoader(.destroy), destroyRewardedAdLoader),
        ]
    }

    private let onDestroy: () -> Void
    private let adLoader: RewardedAdLoader
    private let loadDelegate: FullscreenAdLoadDelegate

    let name = "rewardedAdLoader"

    init(adLoader: RewardedAdLoader, loadDelegate: FullscreenAdLoadDelegate, onDestroy: @escaping () -> Void) {
        self.adLoader = adLoader
        self.loadDelegate = loadDelegate
        self.onDestroy = onDestroy
    }

    private func loadRewardedAd(args: Any?, result: MethodCallResult) {
        guard let args = args as? [String: Any?] else {
            return result.error(.argsIsNotMap)
        }
        let requestId = args["requestId"] as? Int ?? 0
        let adRequest = args.toAdRequest()
        adLoader.loadAd(with: adRequest) { [weak self] loadResult in
            switch loadResult {
            case .success(let ad):
                self?.loadDelegate.reportRewardedAdLoaded(ad: ad, adInfo: ad.adInfo, requestId: requestId)
            case .failure(let error):
                self?.loadDelegate.reportAdFailedToLoad(error: error, adUnitId: adRequest.adUnitID, requestId: requestId)
            }
        }
        result.success()
    }

    private func cancelLoading(args: Any?, result: MethodCallResult) {
        Task { @MainActor in
            adLoader.cancelLoading()
            result.success()
        }
    }

    private func destroyRewardedAdLoader(args: Any?, result: MethodCallResult) {
        onDestroy()
        result.success()
    }
}
