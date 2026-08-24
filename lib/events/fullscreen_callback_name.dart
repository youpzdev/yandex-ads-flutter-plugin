/*
 * This file is a part of the Yandex Advertising Network
 *
 * Version for Flutter (C) 2023 YANDEX
 *
 * You may not use this file except in compliance with the License.
 * You may obtain a copy of the License at https://legal.yandex.com/partner_ch/
 */

part of '../mobile_ads.dart';

enum _FullScreenAdCallbackName {
  /// Notifies that the ad loaded successfully.
  onAdLoaded,

  /// Notifies that the ad failed to load.
  onAdFailedToLoad,

  /// Notifies that the user clicked on the ad.
  onAdClicked,

  /// Notifies that the ad has been shown.
  onAdShown,

  /// Notifies that the ad can’t be displayed.
  onAdFailedToShow,

  /// Notifies that the ad has been dismissed.
  onAdDismissed,

  /// Notifies that the user should be rewarded for viewing an ad (impression counted).
  onRewarded,

  /// Notifies that an fullscreen ad impression has been counted.
  onAdImpression;

  static _FullScreenAdCallbackName? find(String name) {
    for (_FullScreenAdCallbackName value in _FullScreenAdCallbackName.values) {
      if (value.name == name) return value;
    }

    return null;
  }
}
