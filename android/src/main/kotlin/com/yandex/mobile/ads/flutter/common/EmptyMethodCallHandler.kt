/*
 * This file is a part of the Yandex Advertising Network
 *
 * Version for Flutter (C) 2023 YANDEX
 *
 * You may not use this file except in compliance with the License.
 * You may obtain a copy of the License at https://legal.yandex.com/partner_ch/
 */

package com.yandex.mobile.ads.flutter.common

import com.yandex.mobile.ads.flutter.util.error
import com.yandex.mobile.ads.flutter.util.success
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/// Answers commands sent to an object that was already destroyed.
internal class EmptyMethodCallHandler(
    private val error: CommandError,
) : MethodChannel.MethodCallHandler {

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        if (call.method == DESTROY) {
            result.success()
        } else {
            result.error(error)
        }
    }

    private companion object {
        const val DESTROY = "destroy"
    }
}
