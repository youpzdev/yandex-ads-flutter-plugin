/*
 * This file is a part of the Yandex Advertising Network
 *
 * Version for Flutter (C) 2023 YANDEX
 *
 * You may not use this file except in compliance with the License.
 * You may obtain a copy of the License at https://legal.yandex.com/partner_ch/
 */

part of 'mobile_ads.dart';

abstract class _FullscreenAd with _Ad {
  _FullScreenAdEventListener? _eventListener;

  final int id;
  final String channelName;
  final AdInfo? adInfo;

  @override
  String get methodChannelName => '$channelName.$id';

  _FullscreenAd({
    required this.channelName,
    required this.id,
    this.adInfo,
  });

  Future<void> _setAdEventListener(
      {required _FullScreenAdEventListener eventListener}) async {
    _eventListener = eventListener;
    _eventListener?.setupCallbacks();
  }

  /// Shows ad on top of the application.
  ///
  /// Set an event listener before calling this method for callbacks
  /// about events that occur when an ad is displayed.
  Future<void> show() async {
    _channel.invokeMethod('show');
  }

  Future waitForDismiss();
}
