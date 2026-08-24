/*
 * This file is a part of the Yandex Advertising Network
 *
 * Version for Flutter (C) 2023 YANDEX
 *
 * You may not use this file except in compliance with the License.
 * You may obtain a copy of the License at https://legal.yandex.com/partner_ch/
 */

package com.yandex.mobile.ads.flutter.banner

import android.content.Context
import com.yandex.mobile.ads.banner.BannerAdSize
import io.flutter.plugin.platform.PlatformView
import com.yandex.mobile.ads.banner.BannerAdView as LibBannerAdView

internal class BannerAdView(
    context: Context,
    adSize: BannerAdSize,
) : PlatformView {

    private val banner = LibBannerAdView(context).apply {
        tag = accessibilityId
        setAdSize(adSize)
    }

    override fun getView() = banner

    override fun dispose() {
        banner.destroy()
    }

    companion object {
        val accessibilityId = "banner-ad"
    }
}
