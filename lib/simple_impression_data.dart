/*
 * This file is a part of the Yandex Advertising Network
 *
 * Version for Flutter (C) 2023 YANDEX
 *
 * You may not use this file except in compliance with the License.
 * You may obtain a copy of the License at https://legal.yandex.com/partner_ch/
 */

part of 'mobile_ads.dart';

class _SimpleImpressionData implements ImpressionData {
  String rawData;

  _SimpleImpressionData({required this.rawData});

  @override
  String getRawData() {
    return rawData;
  }
}
