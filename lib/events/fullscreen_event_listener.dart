/*
 * This file is a part of the Yandex Advertising Network
 *
 * Version for Flutter (C) 2023 YANDEX
 *
 * You may not use this file except in compliance with the License.
 * You may obtain a copy of the License at https://legal.yandex.com/partner_ch/
 */

part of '../mobile_ads.dart';

class _FullScreenAdEventListener {
  final String channelName;

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

  /// Notifies that the user should be rewarded for viewing an ad (impression counted).
  final void Function(Reward reward)? onRewarded;

  late Stream eventStream;

  _FullScreenAdEventListener({
    required this.channelName,
    this.onAdShown,
    this.onAdFailedToShow,
    this.onAdDismissed,
    this.onAdClicked,
    this.onAdImpression,
    this.onRewarded,
  });

  Future<void> setupCallbacks() async {
    eventStream = EventChannel(channelName).receiveBroadcastStream();
    await for (Map result in eventStream) {
      switch (_FullScreenAdCallbackName.find(result['name'])) {
        case _FullScreenAdCallbackName.onAdShown:
          onAdShown?.call();
          break;
        case _FullScreenAdCallbackName.onAdFailedToShow:
          onAdFailedToShow?.call(AdError(result['description']));
          break;
        case _FullScreenAdCallbackName.onAdClicked:
          onAdClicked?.call();
          break;
        case _FullScreenAdCallbackName.onAdDismissed:
          onAdDismissed?.call();
          break;
        case _FullScreenAdCallbackName.onAdImpression:
          onAdImpression?.call(
              _SimpleImpressionData(rawData: result['impressionData'] ?? ""));
          break;
        case _FullScreenAdCallbackName.onRewarded:
          onRewarded?.call(Reward._(result['type'], result['amount']));
          break;
        default:
          break;
      }
    }
  }

  Future<Map> waitFor(List<_FullScreenAdCallbackName> names) async {
    return await eventStream.firstWhere((result) {
      return names.any((name) => result['name'] == name.name);
    });
  }
}
