/*
 * This file is a part of the Yandex Advertising Network
 *
 * Version for Flutter (C) 2022 YANDEX
 *
 * You may not use this file except in compliance with the License.
 * You may obtain a copy of the License at https://legal.yandex.com/partner_ch/
 */

package com.yandex.mobile.ads.flutter.common.command

enum class MobileAdsCommand(val command: String) {
    INITIALIZE("initialize"),
    ENABLE_LOGGING("enableLogging"),
    ENABLE_DEBUG_ERROR_INDICATOR("enableDebugErrorIndicator"),
    SET_LOCATION_TRACKING("setLocationTracking"),
    SET_USER_CONSENT("setUserConsent"),
    SET_AGE_RESTRICTED("setAgeRestricted"),
    SET_AUTOMATIC_AUDIO_SESSION_MANAGEMENT("setAutomaticAudioSessionManagement"),
    SHOW_DEBUG_PANEL("showDebugPanel");

    companion object {

        fun getValueOrNull(command: String): MobileAdsCommand? {
            return MobileAdsCommand.entries.find { it.command == command }
        }
    }
}
