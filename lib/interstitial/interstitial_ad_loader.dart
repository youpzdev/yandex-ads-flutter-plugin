/*
 * This file is a part of the Yandex Advertising Network
 *
 * Version for Flutter (C) 2023 YANDEX
 *
 * You may not use this file except in compliance with the License.
 * You may obtain a copy of the License at https://legal.yandex.com/partner_ch/
 */

part of '../mobile_ads.dart';

/// This class is responsible for loading an interstitial ad.
class InterstitialAdLoader extends _FullscreenAdLoader {
  static const _channelPath = 'interstitialAdLoader';

  InterstitialAdLoader() {
    _init('interstitialAdLoader', _channelPath);
  }

  /// Loads an interstitial ad with the given [AdRequest].
  ///
  /// Returns the loaded [InterstitialAd] on success.
  /// Throws [AdRequestError] if the ad fails to load.
  Future<InterstitialAd> loadAd({required AdRequest adRequest}) async {
    final result = await _invokeLoad(adRequest);
    final name = _FullScreenAdCallbackName.find(result['name'] as String);
    switch (name) {
      case _FullScreenAdCallbackName.onAdLoaded:
        return InterstitialAd._create(
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
