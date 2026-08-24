/*
 * This file is a part of the Yandex Advertising Network
 *
 * Version for Flutter (C) 2023 YANDEX
 *
 * You may not use this file except in compliance with the License.
 * You may obtain a copy of the License at https://legal.yandex.com/partner_ch/
 */

package com.yandex.mobile.ads.flutter.interstitial

import com.yandex.mobile.ads.flutter.common.CommandError
import com.yandex.mobile.ads.flutter.common.CommandHandler
import com.yandex.mobile.ads.flutter.common.CommandHandlerProvider
import com.yandex.mobile.ads.flutter.common.ObjectHolder
import com.yandex.mobile.ads.flutter.util.ActivityContextHolder
import com.yandex.mobile.ads.flutter.util.error
import com.yandex.mobile.ads.flutter.util.success
import com.yandex.mobile.ads.interstitial.InterstitialAd
import io.flutter.plugin.common.MethodChannel

internal class InterstitialAdCommandHandlerProvider(
    private val adHolder: ObjectHolder<InterstitialAd>,
    private val activityContextHolder: ActivityContextHolder,
    private val onDestroy: () -> Unit,
) : CommandHandlerProvider {

    override val name = PROVIDER_NAME
    override val commandHandlers = mapOf(
        SHOW to CommandHandler { _, args, result -> showAd(args, result) },
        DESTROY to CommandHandler { _, args, result -> destroy(args, result) },
    )

    private fun showAd(args: Any?, result: MethodChannel.Result) {
        val context = activityContextHolder.activityContext
            ?: return result.error(CommandError.ActivityContextIsNull)
        val ad = adHolder.value ?: return result.error(CommandError.InterstitialAdIsNull)
        ad.show(context)
        result.success()
    }

    private fun destroy(args: Any?, result: MethodChannel.Result) {
        adHolder.value?.setAdEventListener(null)
        adHolder.value = null
        onDestroy()
        result.success()
    }

    private companion object {

        const val PROVIDER_NAME = "interstitialAd"

        const val SHOW = "show"
        const val DESTROY = "destroy"
    }
}
