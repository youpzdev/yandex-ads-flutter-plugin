/*
 * This file is a part of the Yandex Advertising Network
 *
 * Version for Flutter (C) 2023 YANDEX
 *
 * You may not use this file except in compliance with the License.
 * You may obtain a copy of the License at https://legal.yandex.com/partner_ch/
 */

package com.yandex.mobile.ads.flutter.interstitial

import com.yandex.mobile.ads.common.AdRequestError
import com.yandex.mobile.ads.flutter.common.AdLoaderCommandHandlerProvider
import com.yandex.mobile.ads.flutter.common.CommandError
import com.yandex.mobile.ads.flutter.common.CommandHandler
import com.yandex.mobile.ads.flutter.common.FullScreenAdCreator
import com.yandex.mobile.ads.flutter.common.ObjectHolder
import com.yandex.mobile.ads.flutter.util.ActivityContextHolder
import com.yandex.mobile.ads.flutter.util.error
import com.yandex.mobile.ads.flutter.util.success
import com.yandex.mobile.ads.flutter.util.toAdRequest
import com.yandex.mobile.ads.flutter.util.toMap
import com.yandex.mobile.ads.interstitial.InterstitialAd
import com.yandex.mobile.ads.interstitial.InterstitialAdLoadListener
import com.yandex.mobile.ads.interstitial.InterstitialAdLoader
import io.flutter.plugin.common.MethodChannel

internal class InterstitialAdLoaderCommandHandlerProvider(
    private val activityContextHolder: ActivityContextHolder,
    private val loaderHolder: ObjectHolder<InterstitialAdLoader>,
    private val adCreator: FullScreenAdCreator,
    private val onDestroy: () -> Unit,
) : AdLoaderCommandHandlerProvider() {

    override val name = PROVIDER_NAME
    override val commandHandlers = mapOf(
        LOAD to CommandHandler { _, args, result -> loadAd(args, result) },
        CANCEL_LOADING to CommandHandler { _, args, result -> cancelLoading(args, result) },
        DESTROY to CommandHandler { _, args, result -> destroy(args, result) }
    )

    private fun loadAd(args: Any?, result: MethodChannel.Result) {
        val args = args as? Map<String, Any?>
            ?: return result.error(CommandError.MissingArgsCast)
        val adUnitId = args[AD_UNIT_ID] as? String? ?: ""
        val requestId = (args[REQUEST_ID] as? Number)?.toInt() ?: 0
        val loader =
            loaderHolder.value ?: return result.error(CommandError.InterstitialAdLoaderIsNull)

        loader.loadAd(args.toAdRequest(adUnitId), object : InterstitialAdLoadListener {
            override fun onAdFailedToLoad(error: AdRequestError) {
                this@InterstitialAdLoaderCommandHandlerProvider.onAdFailedToLoad(requestId, error)
            }

            override fun onAdLoaded(interstitialAd: InterstitialAd) {
                val listener = InterstitialAdEventListener()
                interstitialAd.setAdEventListener(listener)
                if (!hasListener) {
                    interstitialAd.setAdEventListener(null)
                    return
                }
                val id = adCreator.createFullScreenAd(
                    INTERSTITIAL_AD,
                    listener
                ) {
                    InterstitialAdCommandHandlerProvider(
                        ObjectHolder(interstitialAd),
                        activityContextHolder,
                        it
                    )
                }

                respond(
                    ON_AD_LOADED, mapOf(
                        ID to id,
                        REQUEST_ID to requestId,
                        AD_INFO to interstitialAd.adInfo.toMap()
                    )
                )
            }
        })
        result.success()
    }

    private fun cancelLoading(args: Any?, result: MethodChannel.Result) {
        loaderHolder.value?.cancelLoading()
        result.success()
    }

    private fun destroy(args: Any?, result: MethodChannel.Result) {
        loaderHolder.value?.cancelLoading()
        loaderHolder.value = null
        onDestroy()
        result.success()
    }

    private companion object {

        const val PROVIDER_NAME = "interstitialAdLoader"
        const val INTERSTITIAL_AD = "interstitialAd"
        const val LOAD = "load"
        const val CANCEL_LOADING = "cancelLoading"
        const val DESTROY = "destroy"
    }
}
