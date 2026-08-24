/*
 * This file is a part of the Yandex Advertising Network
 *
 * Version for Flutter (C) 2023 YANDEX
 *
 * You may not use this file except in compliance with the License.
 * You may obtain a copy of the License at https://legal.yandex.com/partner_ch/
 */

package com.yandex.mobile.ads.flutter.rewarded

import com.yandex.mobile.ads.flutter.FullScreenEventListener
import com.yandex.mobile.ads.rewarded.Reward
import com.yandex.mobile.ads.rewarded.RewardedAdEventListener as SdkRewardedAdEventListener

internal class RewardedAdEventListener : FullScreenEventListener(), SdkRewardedAdEventListener {

    override fun onRewarded(reward: Reward) = respond(
        ON_REWARDED,
        mapOf(AMOUNT to reward.amount, TYPE to reward.type),
    )
}
