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

final class RewardedAdCommandProvider: CommandProvider {

    var commands: [Command] {
        [
            .command(.rewardedAd(.show), showRewardedAd),
            .command(.rewardedAd(.destroy), destroyRewardedAd),
        ]
    }

    private let onDestroy: () -> Void
    private let ad: RewardedAd
    private let adViewController: RewardedAdViewController

    let name = "rewardedAd"

    init(
        ad: RewardedAd,
        onDestroy: @escaping () -> Void,
        adViewController: RewardedAdViewController
    ) {
        self.ad = ad
        self.onDestroy = onDestroy
        self.adViewController = adViewController
    }

    private func showRewardedAd(args: Any?, result: MethodCallResult) {
        guard let controller = Self.controller else {
            return result.error(.noViewController)
        }
        controller.present(adViewController, animated: false) { [weak self] in
            guard let self else { return }
            self.ad.show(from: self.adViewController)
            result.success()
        }
    }

    private func destroyRewardedAd(args: Any?, result: MethodCallResult) {
        onDestroy()
        result.success()
    }
}
