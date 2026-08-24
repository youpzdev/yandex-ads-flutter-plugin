/*
 * This file is a part of the Yandex Advertising Network
 *
 * Version for Flutter (C) 2023 YANDEX
 *
 * You may not use this file except in compliance with the License.
 * You may obtain a copy of the License at https://legal.yandex.com/partner_ch/
 */

part of '../mobile_ads.dart';

/// This class is responsible for listen app open ad events.
/// Should be set to [AppOpenAd] before ad showing.
class AppOpenAdEventListener {
  /// Notifies that the ad has been shown.
  final void Function()? onAdShown;

  /// Notifies that the ad failed to show.
  final void Function(AdError error)? onAdFailedToShow;

  /// Notifies that the ad has been dismissed.
  final void Function()? onAdDismissed;

  /// Notifies that the user clicked on the ad.
  final void Function()? onAdClicked;

  /// Notifies that an ad impression has been counted.
  final void Function(ImpressionData impressionData)? onAdImpression;

  AppOpenAdEventListener({
    this.onAdShown,
    this.onAdFailedToShow,
    this.onAdDismissed,
    this.onAdClicked,
    this.onAdImpression,
  });
}
