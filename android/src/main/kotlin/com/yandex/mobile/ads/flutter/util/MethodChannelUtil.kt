/*
 * This file is a part of the Yandex Advertising Network
 *
 * Version for Flutter (C) 2023 YANDEX
 *
 * You may not use this file except in compliance with the License.
 * You may obtain a copy of the License at https://legal.yandex.com/partner_ch/
 */

package com.yandex.mobile.ads.flutter.util

import com.yandex.mobile.ads.flutter.common.CommandError
import io.flutter.plugin.common.MethodChannel

internal fun MethodChannel.Result.success() = success(null)

internal fun MethodChannel.Result.error(commandError: CommandError) {
    error(commandError.tag, commandError.description, commandError.args)
}
