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

  _BannerAdEventListener({
    required this.channelName,
    required this.loadStateController,
    required this.eventsController,
  });

  void setupCallbacks() {
    final stream = EventChannel(channelName).receiveBroadcastStream();
    _subscription = stream.listen((result) {
      final map = result as Map;
      switch (_CallbackName.find(map['name'])) {
        case _CallbackName.onAdLoaded:
          loadStateController.add(BannerAdLoadStateLoaded(
            width: map['width'],
            height: map['height'],
          ));
          break;
        case _CallbackName.onAdFailedToLoad:
          loadStateController.add(BannerAdLoadStateError(
            error: AdRequestError(
                map['code'], map['description'], map['adUnitId']),
          ));
          break;
        case _CallbackName.onAdClicked:
          eventsController.add(BannerAdClickedEvent());
          break;
        case _CallbackName.onImpression:
          eventsController.add(BannerAdImpressionEvent(
            impressionData:
                _SimpleImpressionData(rawData: map['impressionData'] ?? ""),
          ));
          break;
        default:
          break;
      }
    });
  }

  void dispose() {
    _subscription?.cancel();
  }
}
