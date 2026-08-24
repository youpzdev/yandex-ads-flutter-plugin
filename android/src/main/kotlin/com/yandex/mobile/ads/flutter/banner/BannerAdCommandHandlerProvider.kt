/*
 * This file is a part of the Yandex Advertising Network
 *
 * Version for Flutter (C) 2023 YANDEX
 *
 * You may not use this file except in compliance with the License.
 * You may obtain a copy of the License at https://legal.yandex.com/partner_ch/
 */

package com.yandex.mobile.ads.flutter.banner

import com.yandex.mobile.ads.flutter.common.CommandHandler
import com.yandex.mobile.ads.flutter.common.CommandHandlerProvider

internal class BannerAdCommandHandlerProvider(
    override val commandHandlers: Map<String, CommandHandler>,
) : CommandHandlerProvider {

    override val name = COMMAND_BANNER_NAME

    private companion object {

        const val COMMAND_BANNER_NAME = "bannerAd"
    }
}
