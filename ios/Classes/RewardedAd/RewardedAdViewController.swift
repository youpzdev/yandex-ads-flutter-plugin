/*
 * This file is a part of the Yandex Advertising Network
 *
 * Version for Flutter (C) 2023 YANDEX
 *
 * You may not use this file except in compliance with the License.
 * You may obtain a copy of the License at https://legal.yandex.com/partner_ch/
 */

import YandexMobileAds

final class RewardedAdViewController: BaseFullscreenAdViewController, RewardedAdDelegate {
    func rewardedAd(_ rewardedAd: RewardedAd, didReward reward: Reward) {
        fullScreenEvendDelegate.respond(.onRewarded, ["type": reward.type, "amount": reward.amount])
    }

    func rewardedAd(_ rewardedAd: RewardedAd, didFailToShow error: any Error) {
        super.adDidFailToShow(error)
    }

    func rewardedAdDidShow(_ rewardedAd: RewardedAd) {
        fullScreenEvendDelegate.respond(.onAdShown)
    }

    func rewardedAdDidDismiss(_ rewardedAd: RewardedAd) {
        super.adDidDismiss()
    }

    func rewardedAdDidClick(_ rewardedAd: RewardedAd) {
        fullScreenEvendDelegate.respond(.onAdClicked)
    }

    func rewardedAd(_ rewardedAd: RewardedAd, didTrackImpression impressionData: (any ImpressionData)?) {
        fullScreenEvendDelegate.respond(.onAdImpression, ["impressionData": impressionData?.rawData])
    }
}
