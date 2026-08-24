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

final class FlutterBannerAdViewDelegate: EventDelegate, BannerAdViewDelegate {

    func bannerAdViewDidLoad(_ bannerAdView: YandexMobileAds.BannerAdView) {
        let width = Int(bannerAdView.adContentSize().width)
        let height = Int(bannerAdView.adContentSize().height)
        respond(.onAdLoaded, ["width": width, "height": height])
    }

    func bannerAdViewDidFailLoading(_ bannerAdView: YandexMobileAds.BannerAdView, error: Error) {
        respond(.onAdFailedToLoad, error.toMap())
    }

    func bannerAdViewDidClick(_ bannerAdView: YandexMobileAds.BannerAdView) {
        respond(.onAdClicked)
    }

    func bannerAdView(_ bannerAdView: YandexMobileAds.BannerAdView, didTrackImpression impressionData: ImpressionData?) {
        respond(.onImpression, ["impressionData": impressionData?.rawData])
    }
}
