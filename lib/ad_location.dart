/*
 * This file is a part of the Yandex Advertising Network
 *
 * Version for Flutter (C) 2023 YANDEX
 *
 * You may not use this file except in compliance with the License.
 * You may obtain a copy of the License at https://legal.yandex.com/partner_ch/
 */

part of 'mobile_ads.dart';

/// An AdLocation contains information about user location.
class AdLocation {
  /// User's latitude.
  final double latitude;

  /// User's longitude.
  final double longitude;

  /// Estimated horizontal accuracy of this location, radial, in meters
  final double accuracy;

  const AdLocation(
      {required this.latitude,
      required this.longitude,
      required this.accuracy});

  Map<String, dynamic> _toMap() => {
        'latitude': latitude,
        'longitude': longitude,
        'accuracy': accuracy,
      };
}
