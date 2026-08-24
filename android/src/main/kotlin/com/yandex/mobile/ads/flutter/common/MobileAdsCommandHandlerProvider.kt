/*
 * This file is a part of the Yandex Advertising Network
 *
 * Version for Flutter (C) 2022 YANDEX
 *
 * You may not use this file except in compliance with the License.
 * You may obtain a copy of the License at https://legal.yandex.com/partner_ch/
 */

package com.yandex.mobile.ads.flutter.common

internal class MobileAdsCommandHandlerProvider(
    override val commandHandlers: Map<String, CommandHandler>,
) : CommandHandlerProvider {

    override val name = PROVIDER_NAME

    private companion object {
        const val PROVIDER_NAME = "mobileAds"
    }
}
