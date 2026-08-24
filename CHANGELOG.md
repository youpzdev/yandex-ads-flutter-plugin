# Change Log

## Unreleased — maintained fork

### Added

* `FullscreenAdPool` preloads interstitial, rewarded and app open ads, replaces
  stale creatives, retries failed requests with exponential backoff and jitter,
  and shows an ad without leaking it.
* `AdFrequencyPolicy` and `AdFrequencyGate` cap how often a full-screen ad may
  be shown, with a minimum interval, rolling hourly and daily caps, a session
  cap and a startup grace period.
* `AppOpenAdController` shows a preloaded app open ad on return from the
  background and suppresses returns from system dialogs and ad clicks.
* `YandexAds.events` reports every ad lifecycle event with its ad unit and
  impression payload.
* `ManagedBannerAdController.visibilityThreshold` measures the viewable share
  of a banner and reports `visibleFraction`, `viewableDuration` and
  `requestCount`.
* `AdShowOutcome.duration` reports how long an ad held the screen, and
  `AdFrequencyPolicy.durationPenalty` turns that length into a longer gap
  before the next show.
* Full-screen shows are serialised: a second show while one is on screen is
  refused instead of stacking two ads.
* Ads loaded before a `setUserConsent` or `setAgeRestricted` change are dropped
  instead of being shown under an answer the user has replaced.

### Behavior changes against upstream 8.3.0

* `BannerAd.load` now completes only after the native side accepts the request,
  which requires the matching `AdWidget` to be mounted. It takes a `timeout`
  (30 seconds by default) and fails with `TimeoutException` instead of waiting
  forever; overlapping calls throw `StateError`.
* Native ad template minimums are now computed from the template and the
  content padding: `compact` needs 324 × 412 and `media` needs 324 × 432 at the
  default padding.
* `ManagedBannerAdController` takes a `loadTimeout` and recovers the refresh
  cycle when a request is accepted and never answered.

* Added Android and iOS Native Ads with SDK-bound compact/media templates,
  safe style presets, layout validation, early-event buffering and cancellable
  loading.
* Added visibility- and lifecycle-aware managed banner refresh with 30, 60 and
  120 second policy presets.
* Made initialization, fullscreen loading/showing and resource destruction
  awaitable, retryable, timeout-aware and idempotent.
* Added Dart lifecycle and policy contract tests.
* Raised the minimum Flutter version to 3.27 for stable ARGB serialization.

## Version 8.3.0
* Supported Android Yandex Mobile Ads version 8.3.0
* Supported iOS Yandex Mobile Ads version 8.3.0

## Version 8.2.0
* Supported Android Yandex Mobile Ads version 8.2.0
* Supported iOS Yandex Mobile Ads version 8.2.1

## Version 8.1.0
* Supported Android Yandex Mobile Ads version 8.1.0
* Supported iOS Yandex Mobile Ads version 8.1.0

## Version 8.0.0

[Full migration guideline](https://ads.yandex.com/helpcenter/en/dev/flutter/release/8-0-0-migration)

### Breaking changes

* `MobileAds` renamed to `YandexAds`
* `AdRequestConfiguration` removed — use `AdRequest(adUnitId:)` instead
* `AdRequest` targeting fields (`age`, `gender`, `location`, `contextQuery`, `contextTags`) removed — use `AdTargeting`
* `InterstitialAdLoader.create()`, `RewardedAdLoader.create()`, `AppOpenAdLoader.create()` replaced with synchronous constructors
* `loadAd` for fullscreen ads now returns `Future<Ad>` instead of delivering results via callbacks
* `InterstitialAdLoadListener`, `RewardedAdLoadListener`, `AppOpenAdLoadListener` removed
* `BannerAd` constructor no longer accepts `adRequest` or callbacks — use `load(AdRequest)` and subscribe to `loadStateStream` / `events` streams
* `AdInfo.adSize` removed — use `AdInfo.creatives`, `AdInfo.extraData`, `AdInfo.partnerText`
* `onLeftApplication`, `onReturnedToApplication`, `onAdClose` callbacks removed
* `MobileAds.setLocationConsent` renamed to `YandexAds.setLocationTracking`
* `MobileAds.setAgeRestrictedUser` renamed to `YandexAds.setAgeRestricted`

### Added

* `AdTargeting` class for targeting parameters
* `BannerAdLoadState` and `BannerAdEvent` class hierarchies for stream-based banner state
* Stream-based API for banner ads (`loadStateStream`, `events`)

#### Updated
* Supported Android Yandex Mobile Ads version 8.0.0
* Supported iOS Yandex Mobile Ads version 8.0.0

## Version 7.18.0
* Supported Android Yandex Mobile Ads version 7.18.0
* Supported iOS Yandex Mobile Ads version 7.18.0

## Version 7.17.0
* Supported Android Yandex Mobile Ads version 7.17.0
* Supported iOS Yandex Mobile Ads version 7.17.0

## Version 7.16.0
* Supported Android Yandex Mobile Ads version 7.16.0
* Supported iOS Yandex Mobile Ads version 7.16.0

## Version 7.15.0
* Supported Android Yandex Mobile Ads version 7.15.2
* Supported iOS Yandex Mobile Ads version 7.15.1

## Version 7.14.0
* Supported Android Yandex Mobile Ads version 7.15.0
* Supported iOS Yandex Mobile Ads version 7.15.1

## Version 7.13.0
* Supported Android Yandex Mobile Ads version 7.13.0
* Supported iOS Yandex Mobile Ads version 7.13.0

## Version 7.12.1
* Supported Android Yandex Mobile Ads version 7.12.1
* Supported iOS Yandex Mobile Ads version 7.12.1

## Version 7.12.0
* Supported Android Yandex Mobile Ads version 7.12.0
* Supported iOS Yandex Mobile Ads version 7.12.0
* Supported OnAdClose callback in banner ads

## Version 7.11.0
* Added improvements and fixes

## Version 7.10.0
* Supported Android Yandex Mobile Ads version 7.11.0
* Supported iOS Yandex Mobile Ads version 7.11.0

## Version 7.9.1
* Supported Android Yandex Mobile Ads version 7.10.1
* Supported iOS Yandex Mobile Ads version 7.10.1

## Version 7.9.0
* Supported Android Yandex Mobile Ads version 7.10.0
* Supported iOS Yandex Mobile Ads version 7.10.0

## Version 7.8.0
* Supported Android Yandex Mobile Ads version 7.9.0
* Supported iOS Yandex Mobile Ads version 7.9.0

## Version 7.7.0

#### Updated

* Supported Android Yandex Mobile Ads version 7.8.0
* Supported iOS Yandex Mobile Ads version 7.8.0

## Version 7.6.0

#### Updated

* Supported Android Yandex Mobile Ads version 7.7.0
* Supported iOS Yandex Mobile Ads version 7.7.0

## Version 7.5.0

#### Updated

* Supported Android Yandex Mobile Ads version 7.6.0
* Supported iOS Yandex Mobile Ads version 7.6.0

## Version 7.4.0

#### Updated

* Supported Android Yandex Mobile Ads version 7.5.0
* Supported iOS Yandex Mobile Ads version 7.5.1

## Version 7.3.0

#### Updated

* Supported Android Yandex Mobile Ads version 7.4.0
* Supported iOS Yandex Mobile Ads version 7.4.0

## Version 7.2.0

#### Updated

* Supported Android Yandex Mobile Ads version 7.3.0
* Supported iOS Yandex Mobile Ads version 7.3.2

## Version 7.1.0

#### Updated

* Supported Android Yandex Mobile Ads version 7.1.0
* Supported iOS Yandex Mobile Ads version 7.1.0

## Version 7.0.1

#### Updated

* Supported Android Yandex Mobile Ads Version 7.0.1
* Supported iOS Yandex Mobile Ads Version 7.0.1

## Version 7.0.0

#### Added

* Debug Panel for Android

#### Updated

* Supported Android Yandex Mobile Ads version 7.0.0
* Supported iOS Yandex Mobile Ads version 7.0.0

## Version 6.3.0

* Supported Android Yandex Mobile Ads version 6.4.0
* Supported iOS Yandex Mobile Ads version 6.4.0

## Version 6.2.0

* Supported Android Yandex Mobile Ads version 6.3.0
* Supported iOS Yandex Mobile Ads version 6.3.0

## Version 6.1.0

#### Added

* Ability to get calculated banner size before ads loading

#### Updated

* Supported Android Yandex Mobile Ads version 6.1.0
* Supported iOS Yandex Mobile Ads version 6.1.0

## Version 6.0.1

#### Updated
* Supported Android Yandex Mobile Ads version 6.0.1

## Version 6.0.0

#### Updated

* Added App Open Ad format
* Supported Android Yandex Mobile Ads version 6.0.0
* Supported iOS Yandex Mobile Ads version 6.0.0
* Changed versioning to match the major version of the native SDK's

#### Breaking changes

* New banner ad size API
* Interstitial ad loading and ad show API decomposition
* Rewarded ad loading and ad show API decomposition
* Updated minimum supported version for iOS to 13

## Version 1.4.0

* Supported Android Yandex Mobile Ads version 5.10.0
* Supported iOS Yandex Mobile Ads version 5.9.0

## Version 1.3.0

* Supported Android Yandex Mobile Ads Android version 5.9.0
* Supported iOS Yandex Mobile Ads Android version 5.8.0

## Version 1.2.0

* Supported Android Yandex Mobile Ads Android version 5.8.0
* Supported iOS Yandex Mobile Ads Android version 5.7.0

## Version 1.1.0

* Support for Yandex Mobile Ads SDK version 5.4.1 on Android
* Change native platform structure

## Version 1.0.0

* Change native platform structure

## Version 0.1.0

* Support for Yandex Mobile Ads SDK version 5.4.0 on Android
* Support for Yandex Mobile Ads SDK version 5.3.1 on iOS
