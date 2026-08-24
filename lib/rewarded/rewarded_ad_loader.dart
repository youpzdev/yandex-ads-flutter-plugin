/*
 * This file is a part of the Yandex Advertising Network
 *
 * Version for Flutter (C) 2023 YANDEX
 *
 * You may not use this file except in compliance with the License.
 * You may obtain a copy of the License at https://legal.yandex.com/partner_ch/
 */

part of '../mobile_ads.dart';

/// This class is responsible for loading a rewarded ad.
class RewardedAdLoader extends _FullscreenAdLoader {
  static const _channelPath = 'rewardedAdLoader';

  RewardedAdLoader() {
    _init('rewardedAdLoader', _channelPath, AdFormat.rewarded);
  }

  /// Loads a rewarded ad with the given [AdRequest].
  ///
  /// Returns the loaded [RewardedAd] on success.
  /// Throws [AdRequestError] if the ad fails to load.
  Future<RewardedAd> loadAd({
    required AdRequest adRequest,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    final result = await _invokeLoad(adRequest, timeout: timeout);
    final name = _FullScreenAdCallbackName.find(result['name'] as String);
    switch (name) {
      case _FullScreenAdCallbackName.onAdLoaded:
        return RewardedAd._create(
          id: result['id'] as int,
          adInfo: AdInfo._fromMap(result),
        );
      case _FullScreenAdCallbackName.onAdFailedToLoad:
        throw AdRequestError(
          result['code'] as int,
          result['description'] as String,
          result['adUnitId'] as String?,
        );
      default:
        throw StateError('Unexpected event: ${result['name']}');
    }
  }
}
