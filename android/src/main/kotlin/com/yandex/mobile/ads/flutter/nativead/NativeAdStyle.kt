/*
 * This file is a part of the Yandex Advertising Network
 *
 * Version for Flutter (C) 2023 YANDEX
 *
 * You may not use this file except in compliance with the License.
 * You may obtain a copy of the License at https://legal.yandex.com/partner_ch/
 *
 * Added in this local fork.
 */

package com.yandex.mobile.ads.flutter.nativead

internal data class NativeAdStyle(
    val backgroundColor: Int?,
    val titleColor: Int?,
    val bodyColor: Int?,
    val metadataColor: Int?,
    val callToActionTextColor: Int?,
    val callToActionBackgroundColor: Int?,
    val cornerRadiusDp: Float?,
    val contentPaddingDp: Float?,
) {
    companion object {
        fun from(value: Map<*, *>?): NativeAdStyle {
            return NativeAdStyle(
                backgroundColor = value.color("backgroundColor"),
                titleColor = value.color("titleColor"),
                bodyColor = value.color("bodyColor"),
                metadataColor = value.color("metadataColor"),
                callToActionTextColor = value.color("callToActionTextColor"),
                callToActionBackgroundColor = value.color("callToActionBackgroundColor"),
                cornerRadiusDp = value.dimension("cornerRadius", MAX_CORNER_RADIUS_DP),
                contentPaddingDp = value.dimension("contentPadding", MAX_CONTENT_PADDING_DP),
            )
        }

        private fun Map<*, *>?.color(key: String): Int? {
            val value = this?.get(key)
            val longValue = when (value) {
                is Byte, is Short, is Int, is Long -> (value as Number).toLong()
                else -> return null
            }
            return when {
                longValue in Int.MIN_VALUE.toLong()..Int.MAX_VALUE.toLong() -> longValue.toInt()
                longValue in 0..ARGB_MAX_VALUE -> longValue.toInt()
                else -> null
            }
        }

        private fun Map<*, *>?.dimension(key: String, maximum: Float): Float? {
            val value = this?.get(key) as? Number ?: return null
            val dimension = value.toFloat()
            return if (dimension.isFinite() && dimension >= 0f) {
                dimension.coerceAtMost(maximum)
            } else {
                null
            }
        }

        private const val ARGB_MAX_VALUE = 0xFFFF_FFFFL
        private const val MAX_CORNER_RADIUS_DP = 64f
        private const val MAX_CONTENT_PADDING_DP = 64f
    }
}

internal enum class NativeAdTemplate {
    COMPACT,
    MEDIA;

    val mediaHeightDp: Int
        get() = when (this) {
            COMPACT -> 160
            MEDIA -> 180
        }

    companion object {
        fun from(value: String?): NativeAdTemplate = if (value == "media") MEDIA else COMPACT
    }
}
