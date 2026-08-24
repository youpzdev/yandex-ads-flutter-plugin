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

enum NativeAdTemplate {
  compact,
  media;

  static const _defaultContentPadding = 12.0;
  static const _minimumMediaWidth = 300;
  static const _fixedVerticalContent = 160;

  int get _mediaHeight {
    switch (this) {
      case NativeAdTemplate.compact:
        return 160;
      case NativeAdTemplate.media:
        return 180;
    }
  }

  /// Minimum container width for the default content padding.
  int get minimumWidth => minimumWidthFor(_defaultContentPadding);

  /// Minimum container height for the default content padding.
  int get minimumHeight => minimumHeightFor(_defaultContentPadding);

  /// Minimum container width in dp for the given [contentPadding].
  ///
  /// Larger padding needs a larger container: the native layers compute the
  /// same value and refuse to request an ad for a smaller one.
  int minimumWidthFor(double contentPadding) =>
      _minimumMediaWidth + 2 * NativeAdStyle._boundedDimension(contentPadding).round();

  /// Minimum container height in dp for the given [contentPadding].
  int minimumHeightFor(double contentPadding) =>
      _mediaHeight +
      _fixedVerticalContent +
      2 * NativeAdStyle._boundedDimension(contentPadding).round();

  void validateSize({
    required int width,
    required int height,
    double contentPadding = _defaultContentPadding,
  }) {
    final requiredWidth = minimumWidthFor(contentPadding);
    final requiredHeight = minimumHeightFor(contentPadding);
    if (width < requiredWidth) {
      throw ArgumentError.value(
          width, 'width', 'Must be at least $requiredWidth.');
    }
    if (height < requiredHeight) {
      throw ArgumentError.value(
        height,
        'height',
        'Must be at least $requiredHeight.',
      );
    }
  }
}

class NativeAdStyle {
  static const light = NativeAdStyle(
    backgroundColor: Color(0xffffffff),
    titleColor: Color(0xff15171a),
    bodyColor: Color(0xff51565d),
    metadataColor: Color(0xff6f7782),
    callToActionTextColor: Color(0xffffffff),
    callToActionBackgroundColor: Color(0xff3f72e8),
  );

  static const dark = NativeAdStyle(
    backgroundColor: Color(0xff202124),
    titleColor: Color(0xffffffff),
    bodyColor: Color(0xffd9dde3),
    metadataColor: Color(0xffaeb6c2),
    callToActionTextColor: Color(0xff15171a),
    callToActionBackgroundColor: Color(0xffa9c7ff),
  );

  static const brandSafe = NativeAdStyle(
    backgroundColor: Color(0xffffffff),
    titleColor: Color(0xff111827),
    bodyColor: Color(0xff4b5563),
    metadataColor: Color(0xff6b7280),
    callToActionTextColor: Color(0xffffffff),
    callToActionBackgroundColor: Color(0xff1d4ed8),
    cornerRadius: 12,
    contentPadding: 12,
  );

  final Color? backgroundColor;
  final Color? titleColor;
  final Color? bodyColor;
  final Color? metadataColor;
  final Color? callToActionTextColor;
  final Color? callToActionBackgroundColor;
  final double cornerRadius;
  final double contentPadding;

  const NativeAdStyle({
    this.backgroundColor,
    this.titleColor,
    this.bodyColor,
    this.metadataColor,
    this.callToActionTextColor,
    this.callToActionBackgroundColor,
    this.cornerRadius = 12,
    this.contentPadding = 12,
  });

  Map<String, dynamic> _toMap() => {
        'backgroundColor': backgroundColor?.toARGB32(),
        'titleColor': titleColor?.toARGB32(),
        'bodyColor': bodyColor?.toARGB32(),
        'metadataColor': metadataColor?.toARGB32(),
        'callToActionTextColor': callToActionTextColor?.toARGB32(),
        'callToActionBackgroundColor': callToActionBackgroundColor?.toARGB32(),
        'cornerRadius': _boundedDimension(cornerRadius),
        'contentPadding': _boundedDimension(contentPadding),
      };

  static double _boundedDimension(double value) {
    if (!value.isFinite) return 0;
    return value.clamp(0, 64).toDouble();
  }
}

abstract class NativeAdLoadState {}

class NativeAdLoadStateLoading extends NativeAdLoadState {}

class NativeAdLoadStateLoaded extends NativeAdLoadState {
  final int width;
  final int height;

  NativeAdLoadStateLoaded({required this.width, required this.height});
}

class NativeAdLoadStateError extends NativeAdLoadState {
  final AdRequestError error;

  NativeAdLoadStateError({required this.error});
}

abstract class NativeAdEvent {}

class NativeAdClickedEvent extends NativeAdEvent {}

class NativeAdImpressionEvent extends NativeAdEvent {
  final ImpressionData impressionData;

  NativeAdImpressionEvent({required this.impressionData});
}
