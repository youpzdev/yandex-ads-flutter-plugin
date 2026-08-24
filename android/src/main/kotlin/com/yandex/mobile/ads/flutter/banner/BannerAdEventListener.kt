/*
 * This file is a part of the Yandex Advertising Network
 *
 * Version for Flutter (C) 2023 YANDEX
 *
 * You may not use this file except in compliance with the License.
 * You may obtain a copy of the License at https://legal.yandex.com/partner_ch/
 */

package com.yandex.mobile.ads.flutter.banner

import android.util.Log
import com.yandex.mobile.ads.banner.BannerAdEventListener
import com.yandex.mobile.ads.flutter.EventListener

internal class BannerAdEventListener(
    private val getLoadedBannerSize: () -> Pair<Int, Int>,
) : EventListener(), BannerAdEventListener {

    override fun onAdLoaded() {
        val (width, height) = getLoadedBannerSize()
        Log.d("Banner Size", "$width $height")
        respond(ON_AD_LOADED, mapOf("width" to width, "height" to height))
    }
}
