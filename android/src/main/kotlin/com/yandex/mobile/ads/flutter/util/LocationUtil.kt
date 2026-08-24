/*
 * This file is a part of the Yandex Advertising Network
 *
 * Version for Flutter (C) 2023 YANDEX
 *
 * You may not use this file except in compliance with the License.
 * You may obtain a copy of the License at https://legal.yandex.com/partner_ch/
 */

package com.yandex.mobile.ads.flutter.util

import android.location.Location

internal fun Map<String, Double>.toLocation(): Location? {
    try {
        val latitude = this["latitude"]
        val longitude = this["longitude"]
        if (latitude != null && longitude != null) {
            val location = Location("")
            location.latitude = latitude
            location.longitude = longitude
            val accuracy = this["accuracy"]
            accuracy?.let { location.accuracy = it.toFloat() }
            return location
        }
        return null
    } catch (_: Throwable) {
        return null
    }
}
