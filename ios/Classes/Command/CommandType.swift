/*
 * This file is a part of the Yandex Advertising Network
 *
 * Version for Flutter (C) 2023 YANDEX
 *
 * You may not use this file except in compliance with the License.
 * You may obtain a copy of the License at https://legal.yandex.com/partner_ch/
 */

enum CommandType {
    case mobileAds(MobileAdsCommand)
    case createAdLoader(CreateAdLoaderCommand)
    case bannerAd(BannerAdCommand)
    case bannerAdSize(BannerAdSizeCommand)
    case interstitialAd(InterstitialAdCommand)
    case rewardedAd(RewardedAdCommand)
    case appOpenAd(AppOpenAdCommand)
    case appOpenAdLoader(AppOpenAdLoaderCommand)
    case interstitialAdLoader(InterstitialAdLoaderCommand)
    case rewardedAdLoader(RewardedAdLoaderCommand)

    var name: String {
        switch self {
        case .mobileAds:
            return "mobileAds"
        case .createAdLoader:
            return "createAdLoader"
        case .bannerAd:
            return "bannerAd"
        case .bannerAdSize:
            return "bannerAdSize"
        case .interstitialAd:
            return "interstitialAd"
        case .rewardedAd:
            return "rewardedAd"
        case .appOpenAd:
            return "appOpenAd"
        case .appOpenAdLoader:
            return "appOpenAdLoader"
        case .interstitialAdLoader:
            return "interstitialAdLoader"
        case .rewardedAdLoader:
            return "rewardedAdLoader"
        }
    }

    var commandName: String {
        switch self {
        case .mobileAds(let command):
            return command.rawValue
        case .createAdLoader(let command):
            return command.rawValue
        case .bannerAd(let command):
            return command.rawValue
        case .bannerAdSize(let command):
            return command.rawValue
        case .interstitialAd(let command):
            return command.rawValue
        case .rewardedAd(let command):
            return command.rawValue
        case .appOpenAd(let command):
            return command.rawValue
        case .appOpenAdLoader(let command):
            return command.rawValue
        case .interstitialAdLoader(let command):
            return command.rawValue
        case .rewardedAdLoader(let command):
            return command.rawValue
        }
    }
}

enum CreateAdLoaderCommand: String {
    case interstitialAdLoader
    case rewardedAdLoader
    case appOpenAdLoader
}

enum MobileAdsCommand: String {
    case initialize
    case enableLogging
    case enableDebugErrorIndicator
    case setLocationTracking
    case setUserConsent
    case setAgeRestricted
    case setAutomaticAudioSessionManagement
    case showDebugPanel
}

enum BannerAdCommand: String {
    case load
    case destroy
}

enum BannerAdSizeCommand: String {
    case bannerAdSize
}

enum InterstitialAdCommand: String {
    case show
    case destroy
}

enum RewardedAdCommand: String {
    case show
    case destroy
}

enum AppOpenAdCommand: String {
    case show
    case destroy
}

enum AppOpenAdLoaderCommand: String {
    case load
    case cancelLoading
    case destroy
}

enum InterstitialAdLoaderCommand: String {
    case load
    case cancelLoading
    case destroy
}

enum RewardedAdLoaderCommand: String {
    case load
    case cancelLoading
    case destroy
}
