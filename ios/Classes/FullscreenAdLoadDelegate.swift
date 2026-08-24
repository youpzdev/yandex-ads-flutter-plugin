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

enum FullscreenAdType {
    case interstitial
    case rewarded
    case appOpen
}

final class FullscreenAdLoadDelegate: NSObject, FlutterStreamHandler {

    private var sink: FlutterEventSink?
    private let adCreator: FullScreenAdCreator
    private let adType: FullscreenAdType

    init(adCreator: FullScreenAdCreator, adType: FullscreenAdType) {
        self.adCreator = adCreator
        self.adType = adType
    }

    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        sink = events
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        sink = nil
        return nil
    }

    func reportInterstitialAdLoaded(ad: InterstitialAd, adInfo: AdInfo?, requestId: Int) {
        Task { @MainActor in
            guard sink != nil else { return }
            let id = adCreator.createInterstitialAd(ad: ad)
            sendLoadedEvent(id: id, adInfo: adInfo, requestId: requestId)
        }
    }

    func reportRewardedAdLoaded(ad: RewardedAd, adInfo: AdInfo?, requestId: Int) {
        Task { @MainActor in
            guard sink != nil else { return }
            let id = adCreator.createRewardedAd(ad: ad)
            sendLoadedEvent(id: id, adInfo: adInfo, requestId: requestId)
        }
    }

    func reportAppOpenAdLoaded(ad: AppOpenAd, adInfo: AdInfo?, requestId: Int) {
        Task { @MainActor in
            guard sink != nil else { return }
            let id = adCreator.createAppOpenAd(ad: ad)
            sendLoadedEvent(id: id, adInfo: adInfo, requestId: requestId)
        }
    }

    private func sendLoadedEvent(id: Int, adInfo: AdInfo?, requestId: Int) {
        let args: [String: Any?] = [
            "name": LoadCallbackName.onAdLoaded.rawValue,
            "id": id,
            "requestId": requestId,
            "adInfo": adInfoToMap(adInfo: adInfo),
        ]
        sink?(args)
    }

    func reportAdFailedToLoad(error: Error, adUnitId: String, requestId: Int) {
        let errorMap = error.toMap()
        let args: [String: Any?] = [
            "name": LoadCallbackName.onAdFailedToLoad.rawValue,
            "requestId": requestId,
            "adUnitId": adUnitId,
            "code": errorMap["code"] ?? 1,
            "description": errorMap["description"] ?? "",
        ]
        DispatchQueue.main.async { [weak self] in
            self?.sink?(args)
        }
    }

    private func adInfoToMap(adInfo: AdInfo?) -> [String: Any] {
        guard let info = adInfo else { return [:] }
        return [
            "adUnitId": info.adUnitID,
            "extraData": info.extraData as Any,
            "partnerText": info.partnerText as Any,
            "creatives": info.creatives.map { creative in
                [
                    "creativeId": creative.creativeID as Any,
                    "campaignId": creative.campaignID as Any,
                    "placeId": creative.placeID as Any,
                    "offerId": creative.offerID as Any,
                ] as [String: Any]
            },
        ]
    }
}
