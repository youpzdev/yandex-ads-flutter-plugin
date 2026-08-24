/*
 * This file is a part of the Yandex Advertising Network
 *
 * Version for Flutter (C) 2023 YANDEX
 *
 * You may not use this file except in compliance with the License.
 * You may obtain a copy of the License at https://legal.yandex.com/partner_ch/
 */

part of '../mobile_ads.dart';

/// This class is responsible for showing an interstitial ad.
class InterstitialAd extends _FullscreenAd {
  static const _channelPath = 'yandex_mobileads.interstitialAd';

  InterstitialAd._({
    required super.channelName,
    required super.id,
    super.adInfo,
  });

  static InterstitialAd _create({
    required int id,
    required AdInfo adInfo,
  }) {
    return InterstitialAd._(channelName: _channelPath, id: id, adInfo: adInfo);
  }

  Future<void> setAdEventListener(
      {required InterstitialAdEventListener eventListener}) async {
    _setAdEventListener(
        eventListener: _FullScreenAdEventListener(
            channelName: '${_channel.name}.events',
            onAdShown: eventListener.onAdShown,
            onAdFailedToShow: eventListener.onAdFailedToShow,
            onAdDismissed: eventListener.onAdDismissed,
            onAdClicked: eventListener.onAdClicked,
            onAdImpression: eventListener.onAdImpression));
  }

  @override
  Future<void> waitForDismiss() async {
    await _eventListener?.waitFor([_FullScreenAdCallbackName.onAdDismissed]);
  }
}
