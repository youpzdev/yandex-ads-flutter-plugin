/*
 * This file is a part of the Yandex Advertising Network
 *
 * Version for Flutter (C) 2023 YANDEX
 *
 * You may not use this file except in compliance with the License.
 * You may obtain a copy of the License at https://legal.yandex.com/partner_ch/
 *
 * Added in this local fork.
 */

package com.yandex.mobile.ads.flutter.nativead

import com.yandex.mobile.ads.common.ImpressionData
import com.yandex.mobile.ads.nativeads.NativeAdEventListener
import io.flutter.plugin.common.EventChannel
import java.util.ArrayDeque

internal class NativeAdFlutterEventListener(
    private val width: Int,
    private val height: Int,
) : EventChannel.StreamHandler, NativeAdEventListener {

    private var eventSink: EventChannel.EventSink? = null
    private val pendingEvents = ArrayDeque<Map<String, Any?>>()

    fun onAdLoaded() {
        respond(ON_AD_LOADED, mapOf(WIDTH to width, HEIGHT to height))
    }

    override fun onAdClicked() {
        respond(ON_AD_CLICKED)
    }

    override fun onImpression(impressionData: ImpressionData?) {
        respond(ON_IMPRESSION, mapOf(IMPRESSION_DATA to impressionData?.rawData))
    }

    fun onAdFailedToLoad(error: com.yandex.mobile.ads.common.AdRequestError) {
        onAdFailedToLoad(error.code, error.description, error.adUnitId)
    }

    fun onAdFailedToLoad(code: Int, description: String, adUnitId: String?) {
        respond(
            ON_AD_FAILED_TO_LOAD,
            mapOf(
                CODE to code,
                DESCRIPTION to description,
                AD_UNIT_ID to adUnitId,
            ),
        )
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
        if (events == null) {
            return
        }
        while (pendingEvents.isNotEmpty()) {
            events.success(pendingEvents.removeFirst())
        }
    }

    override fun onCancel(arguments: Any?) {
        clear()
    }

    fun clear() {
        eventSink = null
        pendingEvents.clear()
    }

    private fun respond(name: String, arguments: Map<String, Any?> = emptyMap()) {
        val event = arguments + (NAME to name)
        val sink = eventSink
        if (sink == null) {
            if (pendingEvents.size == MAX_PENDING_EVENTS) {
                pendingEvents.removeFirst()
            }
            pendingEvents.addLast(event)
        } else {
            sink.success(event)
        }
    }

    private companion object {
        const val MAX_PENDING_EVENTS = 8
        const val WIDTH = "width"
        const val HEIGHT = "height"
        const val NAME = "name"
        const val ON_AD_LOADED = "onAdLoaded"
        const val ON_AD_FAILED_TO_LOAD = "onAdFailedToLoad"
        const val ON_AD_CLICKED = "onAdClicked"
        const val ON_IMPRESSION = "onImpression"
        const val CODE = "code"
        const val DESCRIPTION = "description"
        const val AD_UNIT_ID = "adUnitId"
        const val IMPRESSION_DATA = "impressionData"
    }
}
