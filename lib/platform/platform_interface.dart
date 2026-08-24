/*
 * This file is a part of the Yandex Advertising Network
 *
 * Version for Flutter (C) 2023 YANDEX
 *
 * You may not use this file except in compliance with the License.
 * You may obtain a copy of the License at https://legal.yandex.com/partner_ch/
 */

part of '../mobile_ads.dart';

abstract class _PlatformInterface {
  static final instance = _createInstance();

  static _PlatformInterface _createInstance() {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return _AndroidInterface();
      case TargetPlatform.iOS:
        return _IosInterface();
      default:
        throw UnsupportedError(
            'This plugin is only supported on Android and iOS.');
    }
  }

  Widget buildBannerAd({
    required BannerAdSize adSize,
    required int id,
    required void Function(int id) onPlatformViewCreated,
  });
}
