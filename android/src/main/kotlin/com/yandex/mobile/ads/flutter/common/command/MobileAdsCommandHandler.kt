/*
 * This file is a part of the Yandex Advertising Network
 *
 * Version for Flutter (C) 2023 YANDEX
 *
 * You may not use this file except in compliance with the License.
 * You may obtain a copy of the License at https://legal.yandex.com/partner_ch/
 */

package com.yandex.mobile.ads.flutter.common.command

import android.content.Context
import com.yandex.mobile.ads.common.YandexAds
import com.yandex.mobile.ads.flutter.common.CommandError
import com.yandex.mobile.ads.flutter.common.CommandHandler
import com.yandex.mobile.ads.flutter.util.ActivityContextHolder
import com.yandex.mobile.ads.flutter.util.error
import com.yandex.mobile.ads.flutter.util.success
import io.flutter.plugin.common.MethodChannel.Result

internal class MobileAdsCommandHandler(
    private val applicationContext: Context,
    private val activityContextHolder: ActivityContextHolder
) : CommandHandler {

    override fun handleCommand(command: String, args: Any?, result: Result) {
        when (MobileAdsCommand.getValueOrNull(command)) {
            MobileAdsCommand.INITIALIZE -> initialize(result)
            MobileAdsCommand.ENABLE_DEBUG_ERROR_INDICATOR -> setDebugErrorIndicator(args, result)
            MobileAdsCommand.ENABLE_LOGGING -> setLogging(args, result)
            MobileAdsCommand.SET_AGE_RESTRICTED -> setAgeRestricted(args, result)
            MobileAdsCommand.SET_LOCATION_TRACKING -> setLocationTracking(args, result)
            MobileAdsCommand.SET_USER_CONSENT -> setUserConsent(args, result)
            MobileAdsCommand.SET_AUTOMATIC_AUDIO_SESSION_MANAGEMENT -> setAutomaticAudioSessionManagement(result)
            MobileAdsCommand.SHOW_DEBUG_PANEL -> showDebugPanel(result)
            null -> result.error(CommandError.CommandNotImplemented)
        }
    }

    private fun initialize(result: Result) {
        YandexAds.initialize(applicationContext) {
            result.success()
        }
    }

    private fun setLogging(args: Any?, result: Result) {
        val value = args as? Boolean
            ?: return throwsError(result)
        YandexAds.enableLogging(value)
        result.success()
    }

    private fun setDebugErrorIndicator(args: Any?, result: Result) {
        val value = args as? Boolean
            ?: return throwsError(result)
        YandexAds.enableDebugErrorIndicator(value)
        result.success()
    }

    private fun setLocationTracking(args: Any?, result: Result) {
        val value = args as? Boolean
            ?: return throwsError(result)
        YandexAds.setLocationTracking(value)
        result.success()
    }

    private fun setUserConsent(args: Any?, result: Result) {
        val value = args as? Boolean
            ?: return throwsError(result)
        YandexAds.setUserConsent(value)
        result.success()
    }

    private fun setAgeRestricted(args: Any?, result: Result) {
        val value = args as? Boolean
            ?: return throwsError(result)
        YandexAds.setAgeRestricted(value)
        result.success()
    }

    private fun setAutomaticAudioSessionManagement(result: Result) {
        result.success()
    }

    private fun showDebugPanel(result: Result) {
        val activity = activityContextHolder.activityContext
        if (activity != null) {
            YandexAds.showDebugPanel(activity)
            result.success()
        } else {
            result.error(CommandError.ActivityContextIsNull)
        }
    }

    private fun throwsError(result: Result) {
        result.error(CommandError.ArgsMustBeBool)
    }
}
