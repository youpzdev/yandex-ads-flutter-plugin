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

part of '../mobile_ads.dart';

/// Ad format an event came from.
enum AdFormat { banner, interstitial, rewarded, appOpen, native }

/// What happened to an ad.
enum AdEventType {
  /// The ad was loaded and is ready to show.
  loaded,

  /// The request came back without an ad.
  failedToLoad,

  /// The ad appeared on screen.
  shown,

  /// The ad was ready but could not be displayed.
  failedToShow,

  /// The user tapped the ad.
  clicked,

  /// An impression was counted by the SDK.
  impression,

  /// A full-screen ad was closed.
  dismissed,

  /// A rewarded ad granted its reward.
  rewarded,
}

/// One ad lifecycle event, ready to be forwarded to analytics.
///
/// Every ad in this plugin reports through [YandexAds.events], so a single
/// subscription covers banners, full-screen formats and native ads instead of
/// per-placement callbacks that are easy to forget.
class AdEvent {
  final AdEventType type;
  final AdFormat format;

  /// Ad unit the event belongs to, when the plugin knows it.
  final String? adUnitId;

  /// Impression payload, present on [AdEventType.impression].
  ///
  /// Its raw data carries the revenue fields used for LTV and ROAS.
  final ImpressionData? impressionData;

  /// Reward granted by a rewarded ad.
  final Reward? reward;

  /// Failure behind [AdEventType.failedToLoad] or [AdEventType.failedToShow].
  final Object? error;

  /// When the plugin observed the event.
  final DateTime timestamp;

  AdEvent({
    required this.type,
    required this.format,
    this.adUnitId,
    this.impressionData,
    this.reward,
    this.error,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  @override
  String toString() =>
      'AdEvent($type, $format, adUnitId: $adUnitId, error: $error)';
}

class _AdEventBus {
  static final _controller = StreamController<AdEvent>.broadcast(sync: true);

  static Stream<AdEvent> get stream => _controller.stream;

  static void emit({
    required AdEventType type,
    required AdFormat format,
    String? adUnitId,
    ImpressionData? impressionData,
    Reward? reward,
    Object? error,
  }) {
    if (!_controller.hasListener) return;
    _controller.add(
      AdEvent(
        type: type,
        format: format,
        adUnitId: adUnitId,
        impressionData: impressionData,
        reward: reward,
        error: error,
      ),
    );
  }
}
