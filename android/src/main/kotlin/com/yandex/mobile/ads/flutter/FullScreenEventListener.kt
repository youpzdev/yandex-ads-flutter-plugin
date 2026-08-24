/*
 * This file is a part of the Yandex Advertising Network
 *
 * Version for Flutter (C) 2023 YANDEX
 *
 * You may not use this file except in compliance with the License.
 * You may obtain a copy of the License at https://legal.yandex.com/partner_ch/
 */

package com.yandex.mobile.ads.flutter

import com.yandex.mobile.ads.common.AdError
import com.yandex.mobile.ads.common.ImpressionData
import io.flutter.plugin.common.EventChannel

internal abstract class FullScreenEventListener : EventChannel.StreamHandler {

    private var eventBridge: EventChannel.EventSink? = null

    protected fun respond(callback: String, args: Map<String, Any?> = mapOf()) {
        eventBridge?.success(args + ("name" to callback))
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventBridge = events
    }

    override fun onCancel(arguments: Any?) {
        eventBridge = null
    }

    fun onAdClicked() = respond(ON_AD_CLICKED)

    fun onAdShown() = respond(ON_AD_SHOWN)

    fun onAdFailedToShow(adError: AdError) =
        respond(ON_AD_FAILED_TO_SHOW, mapOf(DESCRIPTION to adError.description))

    fun onAdDismissed() = respond(ON_AD_DISMISSED)

    fun onAdImpression(impressionData: ImpressionData?) = respond(
        ON_AD_IMPRESSION,
        mapOf(IMPRESSION_DATA to impressionData?.rawData),
    )

    protected companion object {

        const val ON_AD_CLICKED = "onAdClicked"
        const val ON_AD_SHOWN = "onAdShown"
        const val ON_AD_FAILED_TO_SHOW = "onAdShown"
        const val ON_AD_DISMISSED = "onAdDismissed"
        const val ON_REWARDED = "onRewarded"
        const val ON_AD_IMPRESSION = "onAdImpression"

        const val IMPRESSION_DATA = "impressionData"
        const val AMOUNT = "amount"
        const val TYPE = "type"

        const val DESCRIPTION = "description"
    }
}
