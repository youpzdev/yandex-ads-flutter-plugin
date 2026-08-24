/*
 * This file is a part of the Yandex Advertising Network
 *
 * Version for Flutter (C) 2023 YANDEX
 *
 * You may not use this file except in compliance with the License.
 * You may obtain a copy of the License at https://legal.yandex.com/partner_ch/
 *
 * Added in this local fork.
 */

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> settle() =>
    Future<void>.delayed(const Duration(milliseconds: 20));

class PoolHarness {
  PoolHarness({
    this.loaderType = 'interstitialAdLoader',
    this.adPath = 'interstitialAd',
  });

  final String loaderType;
  final String adPath;
  final _methodChannels = <MethodChannel>[];
  final _eventChannels = <EventChannel>[];
  final destroyedAds = <int>[];

  int loadCalls = 0;
  int showCalls = 0;
  int lastAdId = 0;
  int? _requestId;
  MockStreamHandlerEventSink? _loaderEvents;
  MockStreamHandlerEventSink? _adEvents;

  TestDefaultBinaryMessenger get _messenger =>
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  void install() {
    const createChannel = MethodChannel('yandex_mobileads.createAdLoader');
    _methodChannels.add(createChannel);
    _messenger.setMockMethodCallHandler(createChannel, (call) async {
      final id = (call.arguments as Map<dynamic, dynamic>)['id'] as int;
      final channel = MethodChannel('yandex_mobileads.$loaderType.$id');
      final events = EventChannel('${channel.name}.events');
      _methodChannels.add(channel);
      _eventChannels.add(events);
      _messenger.setMockStreamHandler(
        events,
        MockStreamHandler.inline(
          onListen: (_, sink) => _loaderEvents = sink,
        ),
      );
      _messenger.setMockMethodCallHandler(channel, (call) async {
        switch (call.method) {
          case 'load':
            loadCalls++;
            _requestId =
                (call.arguments as Map<dynamic, dynamic>)['requestId'] as int;
            break;
        }
        return null;
      });
      return null;
    });
  }

  Future<void> waitForLoads(int count) async {
    final deadline = DateTime.now().add(const Duration(seconds: 5));
    while (loadCalls < count) {
      if (DateTime.now().isAfter(deadline)) {
        throw StateError('Expected $count load calls, saw $loadCalls');
      }
      await Future<void>.delayed(const Duration(milliseconds: 1));
    }
  }

  Future<void> waitForShow() async {
    final deadline = DateTime.now().add(const Duration(seconds: 5));
    while (showCalls == 0 || _adEvents == null) {
      if (DateTime.now().isAfter(deadline)) {
        throw StateError('The ad was never shown');
      }
      await Future<void>.delayed(const Duration(milliseconds: 1));
    }
  }

  void completeLoaded({String adUnitId = 'unit'}) {
    lastAdId++;
    final adId = lastAdId;
    _installAdChannels(adId);
    _loaderEvents!.success({
      'name': 'onAdLoaded',
      'requestId': _requestId,
      'id': adId,
      'adUnitId': adUnitId,
      'adInfo': {'adUnitId': adUnitId},
    });
  }

  void completeFailed({int code = 1, String description = 'no fill'}) {
    _loaderEvents!.success({
      'name': 'onAdFailedToLoad',
      'requestId': _requestId,
      'code': code,
      'description': description,
      'adUnitId': 'unit',
    });
  }

  void emitAdEvent(Map<String, Object?> event) => _adEvents!.success(event);

  void _installAdChannels(int adId) {
    final channel = MethodChannel('yandex_mobileads.$adPath.$adId');
    final events = EventChannel('${channel.name}.events');
    _methodChannels.add(channel);
    _eventChannels.add(events);
    _messenger.setMockStreamHandler(
      events,
      MockStreamHandler.inline(onListen: (_, sink) => _adEvents = sink),
    );
    _messenger.setMockMethodCallHandler(channel, (call) async {
      switch (call.method) {
        case 'show':
          showCalls++;
          break;
        case 'destroy':
          destroyedAds.add(adId);
          break;
      }
      return null;
    });
  }

  void dispose() {
    for (final channel in _methodChannels) {
      _messenger.setMockMethodCallHandler(channel, null);
    }
    for (final channel in _eventChannels) {
      _messenger.setMockStreamHandler(channel, null);
    }
  }
}
