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
import UIKit
final class AppOpenAdViewController: BaseFullscreenAdViewController, AppOpenAdDelegate {
    func appOpenAd(_ appOpenAd: AppOpenAd, didFailToShow error: any Error) {
        super.adDidFailToShow(error)
    }
    func appOpenAdDidShow(_ interstitialAd: AppOpenAd) {
        fullScreenEvendDelegate.respond(.onAdShown)
    }
    func appOpenAdDidDismiss(_ interstitialAd: AppOpenAd) {
        super.adDidDismiss()
    }
    func appOpenAdDidClick(_ ad: AppOpenAd) {
        fullScreenEvendDelegate.respond(.onAdClicked)
    }

    func appOpenAd(_ appOpenAd: AppOpenAd, didTrackImpression impressionData: (any ImpressionData)?) {
        fullScreenEvendDelegate.respond(.onAdImpression, ["impressionData": impressionData?.rawData])
    }
}
