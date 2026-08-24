/*
 * This file is a part of the Yandex Advertising Network
 *
 * Version for Flutter (C) 2023 YANDEX
 *
 * You may not use this file except in compliance with the License.
 * You may obtain a copy of the License at https://legal.yandex.com/partner_ch/
 */

package com.yandex.mobile.ads.flutter.util

import android.app.Activity
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import java.lang.ref.WeakReference

internal class ActivityContextHolder : ActivityAware {

    val activityContext: Activity?
        get() = activityContextReference?.get()

    private var activityContextReference: WeakReference<Activity>? = null

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activityContextReference = WeakReference(binding.activity)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activityContextReference?.clear()
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activityContextReference = WeakReference(binding.activity)
    }

    override fun onDetachedFromActivity() {
        activityContextReference?.clear()
    }
}
