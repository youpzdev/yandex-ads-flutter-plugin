/*
 * This file is a part of the Yandex Advertising Network
 *
 * Version for Flutter (C) 2023 YANDEX
 *
 * You may not use this file except in compliance with the License.
 * You may obtain a copy of the License at https://legal.yandex.com/partner_ch/
 */

part of '../mobile_ads.dart';

class AdRequestError extends Error {
  /// Error code.
  final int code;

  /// Error description.
  final String description;

  final String? adUnitId;

  AdRequestError(this.code, this.description, this.adUnitId);

  @override
  String toString() =>
      "Ad failed to load with unit id $adUnitId and code $code: $description";
}

class AdError extends Error {
  final String description;

  AdError(this.description);

  @override
  String toString() => "Ad failed to show: $description";
}
