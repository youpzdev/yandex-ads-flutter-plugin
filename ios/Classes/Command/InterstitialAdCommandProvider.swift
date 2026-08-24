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

final class InterstitialAdCommandProvider: CommandProvider {

    var commands: [Command] {
        [
            .command(.interstitialAd(.show), showInterstitialAd),
            .command(.interstitialAd(.destroy), destroyInterstitialAd),
        ]
    }

    private let onDestroy: () -> Void
    private let ad: InterstitialAd
    private let adViewController: InterstitialAdViewController

    let name = "interstitialAd"

    init(
        ad: InterstitialAd,
        onDestroy: @escaping () -> Void,
        adViewController: InterstitialAdViewController
    ) {
        self.ad = ad
        self.onDestroy = onDestroy
        self.adViewController = adViewController
    }

    private func showInterstitialAd(args: Any?, result: MethodCallResult) {
        guard let controller = Self.controller else {
            return result.error(.noViewController)
        }
        controller.present(adViewController, animated: false) { [weak self] in
            guard let self else { return }
            self.ad.show(from: self.adViewController)
            result.success()
        }
    }

    private func destroyInterstitialAd(args: Any?, result: MethodCallResult) {
        onDestroy()
        result.success()
    }
}
