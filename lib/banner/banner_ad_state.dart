/*
 * This file is a part of the Yandex Advertising Network
 *
 * Version for Flutter (C) 2023 YANDEX
 *
 * You may not use this file except in compliance with the License.
 * You may obtain a copy of the License at https://legal.yandex.com/partner_ch/
 */

part of '../mobile_ads.dart';

/// Represents the load state of a [BannerAd].
abstract class BannerAdLoadState {}

/// The initial state before any load has been requested.
class BannerAdLoadStateInitial extends BannerAdLoadState {}

/// A load request is in progress.
class BannerAdLoadStateLoading extends BannerAdLoadState {}

/// The ad has been loaded successfully.
class BannerAdLoadStateLoaded extends BannerAdLoadState {
  /// Actual width of the loaded banner in density-independent pixels (dp).
  final int width;

  /// Actual height of the loaded banner in density-independent pixels (dp).
  final int height;

  BannerAdLoadStateLoaded({required this.width, required this.height});
}

/// The ad failed to load.
class BannerAdLoadStateError extends BannerAdLoadState {
  /// The error that occurred during loading.
  final AdRequestError error;

  BannerAdLoadStateError({required this.error});
}

/// An event emitted by a [BannerAd] after it has been loaded.
abstract class BannerAdEvent {}

/// The user clicked on the ad.
class BannerAdClickedEvent extends BannerAdEvent {}

/// An ad impression has been counted.
class BannerAdImpressionEvent extends BannerAdEvent {
  /// The impression data.
  final ImpressionData impressionData;

  BannerAdImpressionEvent({required this.impressionData});
}
