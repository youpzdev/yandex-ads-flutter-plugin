/*
 * This file is a part of the Yandex Advertising Network
 *
 * Version for Flutter (C) 2023 YANDEX
 *
 * You may not use this file except in compliance with the License.
 * You may obtain a copy of the License at https://legal.yandex.com/partner_ch/
 */

package com.yandex.mobile.ads.flutter

import android.content.Context
import com.yandex.mobile.ads.flutter.appopenad.command.CreateAppOpenAdLoaderCommandHandler
import com.yandex.mobile.ads.flutter.banner.BannerAdViewFactory
import com.yandex.mobile.ads.flutter.banner.banneadsize.command.GetCalculatedBannerAdSizeCommandHandler
import com.yandex.mobile.ads.flutter.common.AdLoaderCreator
import com.yandex.mobile.ads.flutter.common.CreateAdLoaderCommandHandlerProvider
import com.yandex.mobile.ads.flutter.common.CreateBannerAdSizeCommandHandlerProvider
import com.yandex.mobile.ads.flutter.common.FullScreenAdCreator
import com.yandex.mobile.ads.flutter.common.MobileAdsCommandHandlerProvider
import com.yandex.mobile.ads.flutter.common.command.MobileAdsCommand
import com.yandex.mobile.ads.flutter.common.command.MobileAdsCommandHandler
import com.yandex.mobile.ads.flutter.interstitial.command.CreateInterstitialAdLoaderCommandHandler
import com.yandex.mobile.ads.flutter.nativead.NativeAdViewFactory
import com.yandex.mobile.ads.flutter.rewarded.command.CreateRewardedAdLoaderCommandHandler
import com.yandex.mobile.ads.flutter.util.ActivityContextHolder
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.FlutterPlugin.FlutterPluginBinding
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

class YandexMobileAdsPlugin : FlutterPlugin, ActivityAware {

    private val activityContextHolder = ActivityContextHolder()

    override fun onAttachedToEngine(binding: FlutterPluginBinding) {
        val factory = BannerAdViewFactory(binding.binaryMessenger)
        val nativeAdViewFactory = NativeAdViewFactory(binding.binaryMessenger)
        val applicationContext = binding.applicationContext
        binding.platformViewRegistry
            .registerViewFactory(BANNER_VIEW_TYPE, factory)
        binding.platformViewRegistry
            .registerViewFactory(NATIVE_AD_VIEW_TYPE, nativeAdViewFactory)

        val providers = listOf(
            getMobileAdsCommandHandlerProvider(applicationContext),
            getCreateAdLoaderHandlerProvider(activityContextHolder, binding.binaryMessenger),
            getCreateBannerAdSizeHandlerProvider(activityContextHolder),
        )

        providers.forEach { provider ->
            MethodChannel(binding.binaryMessenger, "$ROOT.${provider.name}")
                .setMethodCallHandler { call, result ->
                    provider.commandHandlers[call.method]?.handleCommand(
                        call.method,
                        call.arguments,
                        result
                    )
                        ?: result.notImplemented()
                }
        }
    }

    private fun getCreateAdLoaderHandlerProvider(
        activityContextHolder: ActivityContextHolder,
        messenger: BinaryMessenger,
    ): CreateAdLoaderCommandHandlerProvider {
        val adLoaderCreator = AdLoaderCreator(messenger)
        val fullScreenAdCreator = FullScreenAdCreator(messenger)
        return CreateAdLoaderCommandHandlerProvider(
            mapOf(
                INTERSTITIAL_AD_LOADER to CreateInterstitialAdLoaderCommandHandler(
                    activityContextHolder,
                    adLoaderCreator,
                    fullScreenAdCreator,
                ),
                REWARDED_AD_LOADER to CreateRewardedAdLoaderCommandHandler(
                    activityContextHolder,
                    adLoaderCreator,
                    fullScreenAdCreator,
                ),
                APP_OPEN_AD_LOADER to CreateAppOpenAdLoaderCommandHandler(
                    activityContextHolder,
                    adLoaderCreator,
                    fullScreenAdCreator,
                ),
            )
        )
    }

    private fun getCreateBannerAdSizeHandlerProvider(
        activityContextHolder: ActivityContextHolder,
    ): CreateBannerAdSizeCommandHandlerProvider {
        return CreateBannerAdSizeCommandHandlerProvider(
            mapOf(
                BANNER_AD_SIZE to GetCalculatedBannerAdSizeCommandHandler(activityContextHolder)
            )
        )
    }

    private fun getMobileAdsCommandHandlerProvider(
        applicationContext: Context,
    ): MobileAdsCommandHandlerProvider {
        val mobileAdsCommandHandler = MobileAdsCommandHandler(
            applicationContext, activityContextHolder
        )
        return MobileAdsCommandHandlerProvider(
            MobileAdsCommand.entries.associate { mobileAdsCommand ->
                mobileAdsCommand.command to mobileAdsCommandHandler
            },
        )
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activityContextHolder.onAttachedToActivity(binding)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activityContextHolder.onDetachedFromActivity()
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activityContextHolder.onReattachedToActivityForConfigChanges(binding)
    }

    override fun onDetachedFromActivity() {
        activityContextHolder.onDetachedFromActivity()
    }

    override fun onDetachedFromEngine(binding: FlutterPluginBinding) = Unit

    internal companion object {

        const val ROOT = "yandex_mobileads"
        const val BANNER_VIEW_TYPE = "<banner-ad>"
        const val NATIVE_AD_VIEW_TYPE = "<native-ad>"

        const val BANNER_AD_SIZE = "bannerAdSize"

        const val INTERSTITIAL_AD_LOADER = "interstitialAdLoader"
        const val REWARDED_AD_LOADER = "rewardedAdLoader"
        const val APP_OPEN_AD_LOADER = "appOpenAdLoader"
    }
}
