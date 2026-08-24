/*
 * This file is a part of the Yandex Advertising Network
 *
 * Version for Flutter (C) 2023 YANDEX
 *
 * You may not use this file except in compliance with the License.
 * You may obtain a copy of the License at https://legal.yandex.com/partner_ch/
 */

package com.yandex.mobile.ads.flutter

import com.yandex.mobile.ads.common.AdRequestError
import com.yandex.mobile.ads.common.ImpressionData
import io.flutter.plugin.common.EventChannel

internal abstract class EventListener : EventChannel.StreamHandler {

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

    open fun onAdLoaded() = respond(ON_AD_LOADED)

    fun onAdFailedToLoad(error: AdRequestError) = respond(
        ON_AD_FAILED_TO_LOAD,
        mapOf(CODE to error.code, DESCRIPTION to error.description, AD_UNIT_ID to error.adUnitId)
    )

    fun onAdClicked() = respond(ON_AD_CLICKED)

    fun onImpression(impressionData: ImpressionData?) = respond(
        ON_IMPRESSION,
        mapOf(IMPRESSION_DATA to impressionData?.rawData),
    )

    protected companion object {

        const val ON_AD_LOADED = "onAdLoaded"
        const val ON_AD_FAILED_TO_LOAD = "onAdFailedToLoad"
        const val ON_AD_CLICKED = "onAdClicked"
        const val ON_IMPRESSION = "onImpression"

        const val CODE = "code"
        const val DESCRIPTION = "description"
        const val IMPRESSION_DATA = "impressionData"
        const val AD_UNIT_ID = "adUnitId"
    }
}
