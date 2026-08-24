/*
 * This file is a part of the Yandex Advertising Network
 *
 * Version for Flutter (C) 2023 YANDEX
 *
 * You may not use this file except in compliance with the License.
 * You may obtain a copy of the License at https://legal.yandex.com/partner_ch/
 */

package com.yandex.mobile.ads.flutter.banner

import kotlin.math.roundToInt

object BannerAdUtil {

    fun Int.toDp(density: Float): Int {
        return if (density == 0.0F) 0 else (this / density).roundToInt()
    }
}
