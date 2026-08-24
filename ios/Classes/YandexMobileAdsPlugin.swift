/*
 * This file is a part of the Yandex Advertising Network
 *
 * Version for Flutter (C) 2023 YANDEX
 *
 * You may not use this file except in compliance with the License.
 * You may obtain a copy of the License at https://legal.yandex.com/partner_ch/
 */

import Flutter
import UIKit
import YandexMobileAds

public final class YandexMobileAdsPlugin: NSObject, FlutterPlugin {
    
    static let channelName = "yandex_mobileads"
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let bannerAdSizeFactory = BannerAdSizeFactory()
        let factory = BannerAdViewFactory(
            messenger: registrar.messenger(),
            bannerAdSizeFactory: bannerAdSizeFactory
        )
        
        registrar.register(factory, withId: "<banner-ad>")
        
        let commandProviders: [CommandProvider] = [
            MobileAdsCommandProvider(),
            CreateAdLoaderCommandProvider(messenger: registrar.messenger()),
            GetCalculatedBannerAdSizeCommandProvider(bannerAdSizeFactory: bannerAdSizeFactory)
        ]
        
        commandProviders.forEach { provider in
            FlutterMethodChannel(
                name: "\(channelName).\(provider.name)",
                binaryMessenger: registrar.messenger()
            ).setMethodCallHandler(provider.callHandler)
        }
    }
}
