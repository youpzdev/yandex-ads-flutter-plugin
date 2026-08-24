/*
 * This file is a part of the Yandex Advertising Network
 *
 * Version for Android (C) 2022 YANDEX
 *
 * You may not use this file except in compliance with the License.
 * You may obtain a copy of the License at https://legal.yandex.com/partner_ch/
 */
package com.yandex.mobile.ads.flutter.banner.banneadsize.command

import com.yandex.mobile.ads.banner.BannerAdSize
import com.yandex.mobile.ads.flutter.common.CommandError
import com.yandex.mobile.ads.flutter.common.CommandHandler
import com.yandex.mobile.ads.flutter.util.ActivityContextHolder
import com.yandex.mobile.ads.flutter.util.error
import com.yandex.mobile.ads.flutter.util.getValueOrNull
import io.flutter.plugin.common.MethodChannel

internal class GetCalculatedBannerAdSizeCommandHandler(
    private val activityContextHolder: ActivityContextHolder,
) : CommandHandler {

    override fun handleCommand(command: String, args: Any?, result: MethodChannel.Result) {
        val context = activityContextHolder.activityContext
        if (context == null) {
            result.error(CommandError.ActivityContextIsNull)
            return
        }
        val params = args as? Map<String, Any>

        val adSizeType = params?.getValueOrNull(TYPE) ?: ""
        val width = params?.getValueOrNull(WIDTH) ?: 0
        val maxHeight = params?.getValueOrNull(HEIGHT) ?: 0

        val bannerAdSize = when (adSizeType) {
            INLINE -> BannerAdSize.inline(context, width, maxHeight)
            STICKY -> BannerAdSize.sticky(context, width)
            else -> BannerAdSize.inline(context, width, maxHeight)
        }

        result.success(
            mapOf(
                WIDTH to bannerAdSize.getWidth(context),
                HEIGHT to bannerAdSize.getHeight(context),
            )
        )
    }

    private companion object {
        const val WIDTH = "width"
        const val HEIGHT = "height"
        const val TYPE = "type"

        const val INLINE = "inline"
        const val STICKY = "sticky"
    }
}
