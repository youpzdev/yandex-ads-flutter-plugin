/*
 * This file is a part of the Yandex Advertising Network
 *
 * Version for Flutter (C) 2023 YANDEX
 *
 * You may not use this file except in compliance with the License.
 * You may obtain a copy of the License at https://legal.yandex.com/partner_ch/
 */

package com.yandex.mobile.ads.flutter.appopenad

import com.yandex.mobile.ads.appopenad.AppOpenAd
import com.yandex.mobile.ads.appopenad.AppOpenAdLoadListener
import com.yandex.mobile.ads.appopenad.AppOpenAdLoader
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
import io.flutter.plugin.common.MethodChannel

internal class AppOpenAdLoaderCommandHandlerProvider(
    private val activityContextHolder: ActivityContextHolder,
    private val loaderHolder: ObjectHolder<AppOpenAdLoader>,
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
        val loader = loaderHolder.value ?: return result.error(CommandError.AppOpenAdIsNull)
        loader.loadAd(args.toAdRequest(adUnitId), object : AppOpenAdLoadListener {
            override fun onAdFailedToLoad(error: AdRequestError) {
                this@AppOpenAdLoaderCommandHandlerProvider.onAdFailedToLoad(requestId, error)
            }

            override fun onAdLoaded(appOpenAd: AppOpenAd) {
                val listener = AppOpenAdEventListener()
                appOpenAd.setAdEventListener(listener)
                val id = adCreator.createFullScreenAd(APP_OPEN_AD, listener) { onDestroy ->
                    AppOpenAdCommandHandlerProvider(
                        ObjectHolder(appOpenAd),
                        activityContextHolder,
                        onDestroy
                    )
                }

                respond(
                    ON_AD_LOADED,
                    mapOf(
                        ID to id,
                        REQUEST_ID to requestId,
                        AD_INFO to appOpenAd.adInfo.toMap()
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

        const val PROVIDER_NAME = "appOpenAdLoader"
        const val APP_OPEN_AD = "appOpenAd"

        const val LOAD = "load"
        const val CANCEL_LOADING = "cancelLoading"
        const val DESTROY = "destroy"
    }
}
