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
import io.flutter.plugin.common.EventChannel

internal open class LoadListener : EventChannel.StreamHandler {

    private var eventBridge: EventChannel.EventSink? = null

    fun respond(callback: String, args: Map<String, Any?> = mapOf()) {
        eventBridge?.success(args + ("name" to callback))
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventBridge = events
    }

    override fun onCancel(arguments: Any?) {
        eventBridge = null
    }

    val hasListener: Boolean
        get() = eventBridge != null

    fun onAdFailedToLoad(requestId: Int, error: AdRequestError) = respond(
        ON_AD_FAILED_TO_LOAD,
        mapOf(
            REQUEST_ID to requestId,
            CODE to error.code,
            DESCRIPTION to error.description,
            AD_UNIT_ID to error.adUnitId,
        )
    )

    protected companion object {

        const val ON_AD_LOADED = "onAdLoaded"
        const val ON_AD_FAILED_TO_LOAD = "onAdFailedToLoad"

        const val CODE = "code"
        const val DESCRIPTION = "description"
        const val AD_UNIT_ID = "adUnitId"
        const val AD_INFO = "adInfo"
        const val ID = "id"
        const val REQUEST_ID = "requestId"
    }
}
