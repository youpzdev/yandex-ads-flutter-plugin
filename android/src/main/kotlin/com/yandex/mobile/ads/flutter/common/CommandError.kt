/*
 * This file is a part of the Yandex Advertising Network
 *
 * Version for Flutter (C) 2023  YANDEX
 *
 * You may not use this file except in compliance with the License.
 * You may obtain a copy of the License at https://legal.yandex.com/partner_ch/
 */

package com.yandex.mobile.ads.flutter.common

internal sealed class CommandError(val tag: String, val description: String, val args: Any?) {

    object ActivityContextIsNull : CommandError(
        "Internal",
        "Activity context is null. Maybe using activity was destroyed",
        null
    )

    object BannerAdIsNull : CommandError(
        "BannerAd",
        "Banner ad cannot be null. Maybe you destroyed it",
        null
    )

    object RewardedAdIsNull : CommandError(
        "RewardedAd",
        "Rewarded ad cannot be null. Maybe you destroyed it",
        null
    )

    object InterstitialAdIsNull : CommandError(
        "InterstitialAd",
        "Interstitial ad cannot be null. Maybe you destroyed it",
        null
    )

    object AppOpenAdIsNull : CommandError(
        "AppOpenAd",
        "AppOpen ad cannot be null. Maybe you destroyed it",
        null
    )

    object RewardedAdLoaderIsNull : CommandError(
        "RewardedAdLoader",
        "Rewarded ad loader cannot be null. Maybe you destroyed it",
        null
    )

    object InterstitialAdLoaderIsNull : CommandError(
        "InterstitialAdLoader",
        "Interstitial ad loader cannot be null. Maybe you destroyed it",
        null
    )

    object AppOpenAdAdLoaderIsNull : CommandError(
        "AppOpenAdAdLoader",
        "AppOpen ad loader cannot be null. Maybe you destroyed it",
        null
    )

    object ArgsMustBeBool : CommandError("Args", "Args must be bool", null)

    object MissingArgsCast : CommandError("Args", "Args must be Map<String, Object?>", null)

    object CommandNotImplemented : CommandError("Command", "Command not implemented", null)
}
