/*
 * This file is a part of the Yandex Advertising Network
 *
 * Version for Flutter (C) 2023 YANDEX
 *
 * You may not use this file except in compliance with the License.
 * You may obtain a copy of the License at https://legal.yandex.com/partner_ch/
 */

part of 'mobile_ads.dart';

/// An AdRequest contains targeting information used to fetch an ad.
class AdRequest {
  /// Unique ad placement ID, created at partner interface.
  final String adUnitId;

  /// Targeting information for the ad request.
  final AdTargeting? targeting;

  /// Custom parameters for ad loading request.
  final Map<String, String>? parameters;

  /// Preferred ad theme.
  final AdTheme? preferredTheme;

  const AdRequest({
    required this.adUnitId,
    this.targeting,
    this.parameters,
    this.preferredTheme,
  });

  Map<String, dynamic> _toMap() => {
        'adUnitId': adUnitId,
        'age': targeting?.age?.toString(),
        'contextQuery': targeting?.contextQuery,
        'contextTags': targeting?.contextTags,
        'gender': targeting?.gender,
        'location': targeting?.location?._toMap(),
        'parameters': parameters,
        'preferredTheme': preferredTheme?.name,
      };
}
