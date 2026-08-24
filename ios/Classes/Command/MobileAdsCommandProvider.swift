/*
 * This file is a part of the Yandex Advertising Network
 *
 * Version for Flutter (C) 2023 YANDEX
 *
 * You may not use this file except in compliance with the License.
 * You may obtain a copy of the License at https://legal.yandex.com/partner_ch/
 */

import Flutter
import YandexMobileAds

final class MobileAdsCommandProvider: CommandProvider {

    var commands: [Command] {
        [
            .command(.mobileAds(.initialize), initialize),
            .command(.mobileAds(.enableLogging), enableLogging),
            .command(.mobileAds(.enableDebugErrorIndicator), enableDebugErrorIndicator),
            .command(.mobileAds(.showDebugPanel), showDebugPanel),
            .command(.mobileAds(.setLocationTracking), setLocationConsent),
            .command(.mobileAds(.setUserConsent), setUserConsent),
            .command(.mobileAds(.setAgeRestricted), setAgeRestrictedUser),
            .command(.mobileAds(.setAutomaticAudioSessionManagement), setAutomaticAudioSessionManagement),
        ]
    }

    let name = "mobileAds"

    private func initialize(args: Any?, result: MethodCallResult) {
        YandexAds.initializeSDK {
            result.success()
        }
    }

    private func enableLogging(args: Any?, result: MethodCallResult) {
        YandexAds.enableLogging()
        result.success()
    }

    private func enableDebugErrorIndicator(args: Any?, result: MethodCallResult) {
        YandexAds.enableVisibilityErrorIndicator(for: .hardware)
        YandexAds.enableVisibilityErrorIndicator(for: .simulator)
        result.success()
    }

    private func showDebugPanel(args: Any?, result: MethodCallResult) {
        YandexAds.showDebugPanel()
        result.success()
    }

    private func setLocationConsent(args: Any?, result: MethodCallResult) {
        guard let value = args as? Bool else {
            return result.error(.argsIsNotBool)
        }
        YandexAds.setLocationTracking(value)
        result.success()
    }

    private func setUserConsent(args: Any?, result: MethodCallResult) {
        guard let value = args as? Bool else {
            return result.error(.argsIsNotBool)
        }
        YandexAds.setUserConsent(value)
        result.success()
    }

    private func setAgeRestrictedUser(args: Any?, result: MethodCallResult) {
        guard let value = args as? Bool else {
            return result.error(.argsIsNotBool)
        }
        YandexAds.setAgeRestricted(value)
        result.success()
    }

    private func setAutomaticAudioSessionManagement(args: Any?, result: MethodCallResult) {
        guard let value = args as? Bool else {
            return result.error(.argsIsNotBool)
        }
        Task { @MainActor in
            YandexAds.audioSessionManager.isAutomaticallyManaged = value
            result.success()
        }
    }
}
