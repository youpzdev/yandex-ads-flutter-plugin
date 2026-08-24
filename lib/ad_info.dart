/*
 * This file is a part of the Yandex Advertising Network
 *
 * Version for Flutter (C) 2023 YANDEX
 *
 * You may not use this file except in compliance with the License.
 * You may obtain a copy of the License at https://legal.yandex.com/partner_ch/
 */

part of 'mobile_ads.dart';

/// Information about a creative in an ad.
class Creative {
  final String? creativeId;
  final String? campaignId;
  final String? placeId;
  final String? offerId;

  const Creative({
    this.creativeId,
    this.campaignId,
    this.placeId,
    this.offerId,
  });

  static Creative _fromMap(Map map) {
    return Creative(
      creativeId: map['creativeId'] as String?,
      campaignId: map['campaignId'] as String?,
      placeId: map['placeId'] as String?,
      offerId: map['offerId'] as String?,
    );
  }
}

/// An AdInfo contains information about an ad.
class AdInfo {
  final String adUnitId;
  final List<Creative> creatives;
  final String? extraData;
  final String? partnerText;

  const AdInfo({
    required this.adUnitId,
    this.creatives = const [],
    this.extraData,
    this.partnerText,
  });

  static AdInfo _fromMap(Map map) {
    try {
      final adInfoMap = map['adInfo'] as Map?;
      final adUnitId = (adInfoMap?['adUnitId'] as String?) ?? "";
      final extraData = adInfoMap?['extraData'] as String?;
      final partnerText = adInfoMap?['partnerText'] as String?;
      final creativesRaw = adInfoMap?['creatives'] as List?;
      final creatives = creativesRaw
              ?.map(
                  (c) => Creative._fromMap(Map<String, dynamic>.from(c as Map)))
              .toList() ??
          [];
      return AdInfo(
        adUnitId: adUnitId,
        creatives: creatives,
        extraData: extraData,
        partnerText: partnerText,
      );
    } catch (_) {
      return const AdInfo(adUnitId: "");
    }
  }
}
