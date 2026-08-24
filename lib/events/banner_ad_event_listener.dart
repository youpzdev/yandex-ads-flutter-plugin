/*
 * This file is a part of the Yandex Advertising Network
 *
 * Version for Flutter (C) 2023 YANDEX
 *
 * You may not use this file except in compliance with the License.
 * You may obtain a copy of the License at https://legal.yandex.com/partner_ch/
 */

part of '../mobile_ads.dart';

class _BannerAdEventListener {
  final String channelName;
  final StreamController<BannerAdLoadState> loadStateController;
  final StreamController<BannerAdEvent> eventsController;

  StreamSubscription? _subscription;

  /// Ad unit of the request in flight, for telemetry.
  String? adUnitId;

  _BannerAdEventListener({
    required this.channelName,
    required this.loadStateController,
    required this.eventsController,
  });

  void setupCallbacks() {
    final previous = _subscription;
    if (previous != null) {
      unawaited(previous.cancel());
    }
    final stream = EventChannel(channelName).receiveBroadcastStream();
    _subscription = stream.listen((result) {
      final map = result as Map;
      switch (_CallbackName.find(map['name'])) {
        case _CallbackName.onAdLoaded:
          _AdEventBus.emit(
            type: AdEventType.loaded,
            format: AdFormat.banner,
            adUnitId: adUnitId,
          );
          loadStateController.add(
            BannerAdLoadStateLoaded(width: map['width'], height: map['height']),
          );
          break;
        case _CallbackName.onAdFailedToLoad:
          final error = AdRequestError(
            map['code'],
            map['description'],
            map['adUnitId'],
          );
          _AdEventBus.emit(
            type: AdEventType.failedToLoad,
            format: AdFormat.banner,
            adUnitId: map['adUnitId'] as String? ?? adUnitId,
            error: error,
          );
          loadStateController.add(BannerAdLoadStateError(error: error));
          break;
        case _CallbackName.onAdClicked:
          _AdEventBus.emit(
            type: AdEventType.clicked,
            format: AdFormat.banner,
            adUnitId: adUnitId,
          );
          eventsController.add(BannerAdClickedEvent());
          break;
        case _CallbackName.onImpression:
          final impressionData = _SimpleImpressionData(
            rawData: map['impressionData'] ?? "",
          );
          _AdEventBus.emit(
            type: AdEventType.impression,
            format: AdFormat.banner,
            adUnitId: adUnitId,
            impressionData: impressionData,
          );
          eventsController.add(
            BannerAdImpressionEvent(impressionData: impressionData),
          );
          break;
        default:
          break;
      }
    });
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
  }
}
