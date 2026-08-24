/*
 * This file is a part of the Yandex Advertising Network
 *
 * Version for Flutter (C) 2023 YANDEX
 *
 * You may not use this file except in compliance with the License.
 * You may obtain a copy of the License at https://legal.yandex.com/partner_ch/
 */

package com.yandex.mobile.ads.flutter.util

import com.yandex.mobile.ads.common.AdInfo
import com.yandex.mobile.ads.common.Creative

internal fun AdInfo.toMap(): Map<String, Any?> {
    val creativesData = creatives.map { creative ->
        mapOf(
            PLACE_ID to creative.placeId,
            OFFER_ID to creative.offerId,
            CAMPAIGN_ID to creative.campaignId,
            CREATIVE_ID to creative.creativeId,
        ).filterValues { value -> value != null }
    }

    val result = mapOf(
        AD_UNIT_ID to adUnitId,
        EXTRA_DATA to extraData,
        PARTNER_TEXT to partnerText,
        CREATIVES to creativesData
    ).filterValues { value -> value != null }

    return result
}

private const val EXTRA_DATA = "extraData"
private const val PARTNER_TEXT = "partnerText"
private const val AD_UNIT_ID = "adUnitId"
private const val CREATIVES = "creatives"
private const val PLACE_ID = "placeId"
private const val OFFER_ID = "offerId"
private const val CAMPAIGN_ID = "campaignId"
private const val CREATIVE_ID = "creativeId"
