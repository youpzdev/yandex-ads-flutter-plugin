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

import android.content.Context
import com.yandex.mobile.ads.flutter.YandexMobileAdsPlugin
import com.yandex.mobile.ads.flutter.common.EmptyMethodCallHandler
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory

internal class NativeAdViewFactory(
    private val messenger: BinaryMessenger,
) : PlatformViewFactory(StandardMessageCodec.INSTANCE) {

    override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
        val params = args as? Map<*, *>
        val id = (params?.get(ID) as? Number)?.toInt() ?: -1
        val width = (params?.get(WIDTH) as? Number)?.toInt()?.coerceAtLeast(0) ?: 0
        val height = (params?.get(HEIGHT) as? Number)?.toInt()?.coerceAtLeast(0) ?: 0
        val template = NativeAdTemplate.from(params?.get(TEMPLATE) as? String)
        val style = NativeAdStyle.from(params?.get(STYLE) as? Map<*, *>)
        val nativeAdView = FlutterNativeAdView(context, width, height, template, style)
        startFlutterCommunication(id, nativeAdView)
        return nativeAdView
    }

    private fun startFlutterCommunication(id: Int, nativeAdView: FlutterNativeAdView) {
        val name = "${YandexMobileAdsPlugin.ROOT}.$NATIVE_AD.$id"
        val methodChannel = MethodChannel(messenger, name)
        val eventChannel = EventChannel(messenger, "$name.events")
        val eventListener = NativeAdFlutterEventListener(nativeAdView.widthDp, nativeAdView.heightDp)
        var channelsDisposed = false
        val disposeChannels = {
            if (!channelsDisposed) {
                channelsDisposed = true
                methodChannel.setMethodCallHandler(EmptyMethodCallHandler())
                eventChannel.setStreamHandler(null)
            }
        }

        nativeAdView.setEventListener(eventListener)
        nativeAdView.setOnDisposed(disposeChannels)
        methodChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                LOAD -> nativeAdView.load(call.arguments, result)
                CANCEL_LOADING -> nativeAdView.cancelLoading(result)
                DESTROY -> nativeAdView.destroy {
                    disposeChannels()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
        eventChannel.setStreamHandler(eventListener)
    }

    private companion object {
        const val NATIVE_AD = "nativeAd"
        const val ID = "id"
        const val WIDTH = "width"
        const val HEIGHT = "height"
        const val TEMPLATE = "template"
        const val STYLE = "style"
        const val LOAD = "load"
        const val CANCEL_LOADING = "cancelLoading"
        const val DESTROY = "destroy"
    }
}
