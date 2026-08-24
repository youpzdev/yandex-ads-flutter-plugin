/*
 * This file is a part of the Yandex Advertising Network
 *
 * Version for Flutter (C) 2023 YANDEX
 *
 * You may not use this file except in compliance with the License.
 * You may obtain a copy of the License at https://legal.yandex.com/partner_ch/
 */

package com.yandex.mobile.ads.flutter.util

import com.yandex.mobile.ads.common.AdRequest
import com.yandex.mobile.ads.common.AdTargeting

internal fun Map<String, Any?>.toAdRequest(
    adUnitId: String
) = AdRequest.Builder(adUnitId).also { builder ->
    toAdTargeting().let(builder::setTargeting)
    (getValueOrNull<Map<String, String>>(PARAMETERS))?.let(builder::setParameters)
    (getValueOrNull<String>(PREFERRED_THEME))?.toAdTheme()?.let(builder::setPreferredTheme)
}.build()

private fun Map<String, Any?>.toAdTargeting(): AdTargeting = AdTargeting.Builder().also { builder ->
    (getValueOrNull<String>(AGE))?.let(builder::setAge)
    (getValueOrNull<String>(CONTEXT_QUERY))?.let(builder::setContextQuery)
    (getValueOrNull<List<String>>(CONTEXT_TAGS))?.let(builder::setContextTags)
    (getValueOrNull<String>(GENDER))?.let(builder::setGender)
    (getValueOrNull<Map<String, Double>>(LOCATION))?.toLocation()?.let(builder::setLocation)
}.build()

private const val AGE = "age"
private const val CONTEXT_QUERY = "contextQuery"
private const val CONTEXT_TAGS = "contextTags"
private const val GENDER = "gender"
private const val LOCATION = "location"
private const val PARAMETERS = "parameters"
private const val PREFERRED_THEME = "preferredTheme"
