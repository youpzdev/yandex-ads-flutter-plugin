package com.yandex.mobile.ads.flutter.common

import com.yandex.mobile.ads.flutter.util.success
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

internal class EmptyMethodCallHandler : MethodChannel.MethodCallHandler {
    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        result.success()
    }
}
