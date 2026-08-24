/*
 * This file is a part of the Yandex Advertising Network
 *
 * Version for Flutter (C) 2023 YANDEX
 *
 * You may not use this file except in compliance with the License.
 * You may obtain a copy of the License at https://legal.yandex.com/partner_ch/
 */

part of '../mobile_ads.dart';

/// A BannerAdSize represents the size of a banner ad.
class BannerAdSize {
  static const _initialHeight = 1;

  const BannerAdSize._(this.width, this.height, this._type);

  ///
  /// Returns flexible banner size.
  /// Banners with flexible sizes stretch to container width and height when possible.
  ///
  /// [width] The width of the ad container in density-independent pixels (dp).
  /// [maxHeight] The maximum height of the ad container in density-independent pixels (dp).
  ///
  const BannerAdSize.inline({
    required int width,
    required int maxHeight,
  }) : this._(width, maxHeight, _AdSizeType.inline);

  ///
  /// Returns sticky banner size with the given width.
  ///
  /// [width] The width of the ad container in density-independent pixels (dp).
  ///
  const BannerAdSize.sticky({
    required int width,
  }) : this._(width, _initialHeight, _AdSizeType.sticky);

  /// Given width in density-independent pixels (dp).
  final int width;

  /// Given height in density-independent pixels (dp).
  final int height;
  final _AdSizeType _type;

  /// Returns the calculated size of this [BannerAdSize].
  Future<CalculatedBannerAdSize> getCalculatedBannerAdSize() async {
    return await _CalculatedBannerAdSizeProvider.getCalculatedBannerAdSize(
        width, height, _type);
  }

  /// Returns the calculated width of this [BannerAdSize] in density-independent pixels (dp).
  Future<int> getCalculatedWidth() async {
    return (await getCalculatedBannerAdSize()).width;
  }

  /// Returns the calculated height of this [BannerAdSize] in density-independent pixels (dp).
  Future<int> getCalculatedHeight() async {
    return (await getCalculatedBannerAdSize()).height;
  }
}

enum _AdSizeType { sticky, inline }

class CalculatedBannerAdSize {
  /// Actual width of the [BannerAdSize] in density-independent pixels (dp).
  final int width;

  /// Actual height of the [BannerAdSize] in density-independent pixels (dp).
  final int height;

  const CalculatedBannerAdSize(this.width, this.height);

  @override
  String toString() {
    return 'CalculatedBannerAdSize{width: $width, height: $height}';
  }
}

class _CalculatedBannerAdSizeProvider {
  static const _createChannel = MethodChannel('yandex_mobileads.bannerAdSize');

  static Future<CalculatedBannerAdSize> getCalculatedBannerAdSize(
    int width,
    int height,
    _AdSizeType adSizeType,
  ) async {
    Map params = {"width": width, "height": height, "type": adSizeType.name};

    Map? result = await _createChannel.invokeMethod("bannerAdSize", params);
    if (result == null) {
      throw ArgumentError('something went wrong while creating banner ad size');
    }

    return CalculatedBannerAdSize(result["width"], result["height"]);
  }
}
