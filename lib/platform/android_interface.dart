/*
 * This file is a part of the Yandex Advertising Network
 *
 * Version for Flutter (C) 2023 YANDEX
 *
 * You may not use this file except in compliance with the License.
 * You may obtain a copy of the License at https://legal.yandex.com/partner_ch/
 */

part of '../mobile_ads.dart';

class _AndroidInterface implements _PlatformInterface {
  @override
  Widget buildBannerAd({
    required BannerAdSize adSize,
    required int id,
    required void Function(int id) onPlatformViewCreated,
  }) {
    return AndroidView(
      viewType: '<banner-ad>',
      layoutDirection: TextDirection.ltr,
      creationParams: {
        'id': id,
        'width': adSize.width,
        'height': adSize.height,
        'type': adSize._type.name,
      },
      creationParamsCodec: const StandardMessageCodec(),
      onPlatformViewCreated: onPlatformViewCreated,
    );
  }

  @override
  Widget buildNativeAd({
    required int id,
    required int width,
    required int height,
    required NativeAdTemplate template,
    required NativeAdStyle style,
    required void Function(int id) onPlatformViewCreated,
  }) {
    return AndroidView(
      viewType: '<native-ad>',
      layoutDirection: TextDirection.ltr,
      creationParams: {
        'id': id,
        'width': width,
        'height': height,
        'template': template.name,
        'style': style._toMap(),
      },
      creationParamsCodec: const StandardMessageCodec(),
      onPlatformViewCreated: onPlatformViewCreated,
    );
  }
}
