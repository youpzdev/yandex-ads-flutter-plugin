/*
 * This file is a part of the Yandex Advertising Network
 *
 * Version for Flutter (C) 2023 YANDEX
 *
 * You may not use this file except in compliance with the License.
 * You may obtain a copy of the License at https://legal.yandex.com/partner_ch/
 */

package com.yandex.mobile.ads.flutter.util

import com.yandex.mobile.ads.common.AdTheme
import java.util.Locale

internal fun String.toAdTheme(): AdTheme? {
    return try {
        AdTheme.valueOf(this.uppercase(Locale.getDefault()))
    } catch (_: Exception) {
        null
    }
}
