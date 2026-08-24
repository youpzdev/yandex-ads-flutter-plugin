/*
 * This file is a part of the Yandex Advertising Network
 *
 * Version for Flutter (C) 2023 YANDEX
 *
 * You may not use this file except in compliance with the License.
 * You may obtain a copy of the License at https://legal.yandex.com/partner_ch/
 */

package com.yandex.mobile.ads.flutter.rewarded

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
import com.yandex.mobile.ads.rewarded.RewardedAd
import com.yandex.mobile.ads.rewarded.RewardedAdLoadListener
import com.yandex.mobile.ads.rewarded.RewardedAdLoader
import io.flutter.plugin.common.MethodChannel

internal class RewardedAdLoaderCommandHandlerProvider(
    private val activityContextHolder: ActivityContextHolder,
    private val loaderHolder: ObjectHolder<RewardedAdLoader>,
    private val adCreator: FullScreenAdCreator,
    private val onDestroy: () -> Unit,
) : AdLoaderCommandHandlerProvider() {

    override val name = PROVIDER_NAME
    override val commandHandlers = mapOf(
        LOAD to CommandHandler { _, args, result -> loadAd(args, result) },
        CANCEL_LOADING to CommandHandler { _, args, result -> cancelLoading(args, result) },
        DESTROY to CommandHandler { _, args, result -> destroy(args, result) },
    )

    private fun loadAd(args: Any?, result: MethodChannel.Result) {
        val args = args as? Map<String, Any?>
            ?: return result.error(CommandError.MissingArgsCast)
        val adUnitId = args[AD_UNIT_ID] as? String? ?: ""
        val requestId = (args[REQUEST_ID] as? Number)?.toInt() ?: 0
        val loader = loaderHolder.value ?: return result.error(CommandError.RewardedAdLoaderIsNull)

        loader.loadAd(args.toAdRequest(adUnitId), object : RewardedAdLoadListener {
            override fun onAdFailedToLoad(error: AdRequestError) {
                this@RewardedAdLoaderCommandHandlerProvider.onAdFailedToLoad(requestId, error)
            }

            override fun onAdLoaded(rewarded: RewardedAd) {
                val listener = RewardedAdEventListener()
                rewarded.setAdEventListener(listener)
                if (!hasListener) {
                    rewarded.setAdEventListener(null)
                    return
                }
                val id = adCreator.createFullScreenAd(REWARDED_AD, listener) {
                    RewardedAdCommandHandlerProvider(
                        ObjectHolder(rewarded),
                        activityContextHolder,
                        it
                    )
                }
                respond(
                    ON_AD_LOADED,
                    mapOf(
                        ID to id,
                        REQUEST_ID to requestId,
                        AD_INFO to rewarded.adInfo.toMap()
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

        const val PROVIDER_NAME = "rewardedAdLoader"
        const val REWARDED_AD = "rewardedAd"

        const val LOAD = "load"
        const val CANCEL_LOADING = "cancelLoading"
        const val DESTROY = "destroy"
    }
}
