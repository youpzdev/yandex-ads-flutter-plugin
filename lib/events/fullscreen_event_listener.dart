/*
 * This file is a part of the Yandex Advertising Network
 *
 * Version for Flutter (C) 2023 YANDEX
 *
 * You may not use this file except in compliance with the License.
 * You may obtain a copy of the License at https://legal.yandex.com/partner_ch/
 */

part of '../mobile_ads.dart';

class _FullScreenAdEventListener {
  final String channelName;

  /// Notifies that the ad has been shown.
  final void Function()? onAdShown;

  /// Notifies that the ad failed to show.
  final void Function(AdError error)? onAdFailedToShow;

  /// Notifies that the ad has been dismissed.
  final void Function()? onAdDismissed;

  /// Notifies that the user clicked on the ad.
  final void Function()? onAdClicked;

  /// Notifies that an ad impression has been counted.
  final void Function(ImpressionData impressionData)? onAdImpression;

  /// Notifies that the user should be rewarded for viewing an ad (impression counted).
  final void Function(Reward reward)? onRewarded;

  StreamSubscription<Map<dynamic, dynamic>>? _subscription;
  final Completer<Map<dynamic, dynamic>> _terminalEvent = Completer();
  Reward? reward;

  _FullScreenAdEventListener({
    required this.channelName,
    this.onAdShown,
    this.onAdFailedToShow,
    this.onAdDismissed,
    this.onAdClicked,
    this.onAdImpression,
    this.onRewarded,
  }) {
    unawaited(_terminalEvent.future.then<void>((_) {}, onError: (Object _) {}));
  }

  void setupCallbacks() {
    _subscription = EventChannel(channelName)
        .receiveBroadcastStream()
        .map(
          (event) => Map<dynamic, dynamic>.from(event as Map),
        )
        .listen(
      (result) {
        switch (_FullScreenAdCallbackName.find(result['name'])) {
          case _FullScreenAdCallbackName.onAdShown:
            onAdShown?.call();
            break;
          case _FullScreenAdCallbackName.onAdFailedToShow:
            final error = AdError(result['description']);
            _completeTerminal(result);
            onAdFailedToShow?.call(error);
            break;
          case _FullScreenAdCallbackName.onAdClicked:
            onAdClicked?.call();
            break;
          case _FullScreenAdCallbackName.onAdDismissed:
            _completeTerminal(result);
            onAdDismissed?.call();
            break;
          case _FullScreenAdCallbackName.onAdImpression:
            onAdImpression?.call(
              _SimpleImpressionData(rawData: result['impressionData'] ?? ""),
            );
            break;
          case _FullScreenAdCallbackName.onRewarded:
            reward = Reward._(result['type'], result['amount']);
            onRewarded?.call(reward!);
            break;
          default:
            break;
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        if (!_terminalEvent.isCompleted) {
          _terminalEvent.completeError(error, stackTrace);
        }
      },
      onDone: () {
        if (!_terminalEvent.isCompleted) {
          _terminalEvent.completeError(
            StateError('Fullscreen ad event stream closed before dismissal.'),
          );
        }
      },
    );
  }

  void _completeTerminal(Map<dynamic, dynamic> result) {
    if (_terminalEvent.isCompleted) return;
    // The subscription stays alive: impressions can still follow a dismissal.
    _terminalEvent.complete(result);
  }

  Future<Map<dynamic, dynamic>> waitForTerminal() => _terminalEvent.future;

  Future<void> dispose() async {
    if (!_terminalEvent.isCompleted) {
      _terminalEvent.completeError(
        StateError('Fullscreen ad listener was disposed before dismissal.'),
      );
    }
    await _subscription?.cancel();
  }
}
