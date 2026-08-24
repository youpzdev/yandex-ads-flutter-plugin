/*
 * This file is a part of the Yandex Advertising Network
 *
 * Version for Flutter (C) 2023 YANDEX
 *
 * You may not use this file except in compliance with the License.
 * You may obtain a copy of the License at https://legal.yandex.com/partner_ch/
 */

part of '../mobile_ads.dart';

/// Class contains information about the reward given to the user.
class Reward {
  /// Type of reward.
  final String type;

  /// Amount of reward.
  final int amount;

  const Reward._(this.type, this.amount);
}
