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

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yandex_mobileads/mobile_ads.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  debugDefaultTargetPlatformOverride = TargetPlatform.android;

  test('initialization can retry after a platform failure', () async {
    var calls = 0;
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    const channel = MethodChannel('yandex_mobileads.mobileAds');
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls++;
      if (calls == 1) {
        throw PlatformException(code: 'temporary');
      }
      return null;
    });

    await expectLater(
        YandexAds.initialize(), throwsA(isA<PlatformException>()));
    await YandexAds.initialize();

    expect(calls, 2);
    messenger.setMockMethodCallHandler(channel, null);
  });

  test('loader cancellation completes the pending load and native cancellation',
      () async {
    final harness = _LoaderHarness();
    addTearDown(harness.dispose);
    await harness.install();
    final loader = InterstitialAdLoader();
    final loading = loader.loadAd(adRequest: const AdRequest(adUnitId: 'unit'));
    final result = expectLater(loading, throwsA(isA<StateError>()));

    await harness.waitForLoad();
    await loader.cancelLoading();
    await result;

    expect(harness.cancelCalls, 1);
    await loader.destroy();
  });

  test('loader timeout cancels the native request', () async {
    final harness = _LoaderHarness();
    addTearDown(harness.dispose);
    await harness.install();
    final loader = InterstitialAdLoader();
    final loading = loader.loadAd(
      adRequest: const AdRequest(adUnitId: 'unit'),
      timeout: const Duration(milliseconds: 5),
    );

    await expectLater(loading, throwsA(isA<TimeoutException>()));

    expect(harness.cancelCalls, 1);
    await loader.destroy();
  });

  test('loader timeout includes loader creation', () async {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    const createChannel = MethodChannel('yandex_mobileads.createAdLoader');
    messenger.setMockMethodCallHandler(createChannel, (call) async {
      await Future<void>.delayed(const Duration(milliseconds: 30));
      return null;
    });
    addTearDown(() => messenger.setMockMethodCallHandler(createChannel, null));
    final loader = InterstitialAdLoader();

    await expectLater(
      loader.loadAd(
        adRequest: const AdRequest(adUnitId: 'unit'),
        timeout: const Duration(milliseconds: 5),
      ),
      throwsA(isA<TimeoutException>()),
    );
    await Future<void>.delayed(const Duration(milliseconds: 35));
  });

  test('loader destroy is idempotent and completes its pending load', () async {
    final harness = _LoaderHarness();
    addTearDown(harness.dispose);
    await harness.install();
    final loader = InterstitialAdLoader();
    final loading = loader.loadAd(adRequest: const AdRequest(adUnitId: 'unit'));
    final result = expectLater(loading, throwsA(isA<StateError>()));

    await harness.waitForLoad();
    final firstDestroy = loader.destroy();
    final secondDestroy = loader.destroy();
    await Future.wait([firstDestroy, secondDestroy]);
    await result;

    expect(harness.destroyCalls, 1);
  });

  test('disposing an unobserved fullscreen listener has no unhandled error',
      () async {
    final harness = _LoaderHarness();
    addTearDown(harness.dispose);
    await harness.install();
    final loader = InterstitialAdLoader();
    final loading = loader.loadAd(adRequest: const AdRequest(adUnitId: 'unit'));

    await harness.waitForLoad();
    harness.completeLoadedAd();
    final ad = await loading;
    const adEvents = EventChannel('yandex_mobileads.interstitialAd.91.events');
    const adChannel = MethodChannel('yandex_mobileads.interstitialAd.91');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockStreamHandler(
      adEvents,
      const MockStreamHandler.inline(onListen: _LoaderHarness._onListen),
    );
    messenger.setMockMethodCallHandler(adChannel, (call) async => null);
    addTearDown(() {
      messenger.setMockStreamHandler(adEvents, null);
      messenger.setMockMethodCallHandler(adChannel, null);
    });

    await ad.setAdEventListener(eventListener: InterstitialAdEventListener());
    await ad.destroy();
    await loader.destroy();
  });

  test('native ad load fails instead of hanging without a platform view',
      () async {
    final ad = NativeAd(
      adRequest: const AdRequest(adUnitId: 'unit'),
      width: 324,
      height: 364,
      loadTimeout: const Duration(milliseconds: 20),
    );
    Object? outcome;
    unawaited(
      ad.load().then((_) => outcome = 'completed', onError: (Object e) {
        outcome = e;
      }),
    );

    await Future<void>.delayed(const Duration(milliseconds: 200));

    expect(outcome, isA<TimeoutException>());
  });

  test('banner load fails instead of hanging without a displayed widget',
      () async {
    final banner = BannerAd(adSize: const BannerAdSize.sticky(width: 320));
    Object? outcome;
    unawaited(
      banner
          .load(
        const AdRequest(adUnitId: 'unit'),
        timeout: const Duration(milliseconds: 20),
      )
          .then((_) => outcome = 'completed', onError: (Object e) {
        outcome = e;
      }),
    );

    await Future<void>.delayed(const Duration(milliseconds: 200));

    expect(outcome, isA<TimeoutException>());
    expect(banner.loadState, isA<BannerAdLoadStateError>());
  });

  test('native templates expose safe minimum sizes and style presets', () {
    expect(NativeAdTemplate.compact.minimumWidth, 324);
    expect(NativeAdTemplate.compact.minimumHeight, 344);
    expect(NativeAdTemplate.media.minimumHeight, 364);
    expect(
      () => NativeAdTemplate.media.validateSize(width: 323, height: 364),
      throwsArgumentError,
    );
    expect(
      () => NativeAdTemplate.media.validateSize(width: 324, height: 363),
      throwsArgumentError,
    );
    NativeAdTemplate.compact.validateSize(width: 324, height: 344);
    NativeAdTemplate.media.validateSize(width: 324, height: 364);
    expect(NativeAdStyle.light.backgroundColor, const Color(0xffffffff));
    expect(NativeAdStyle.dark.backgroundColor, const Color(0xff202124));
    expect(
      NativeAdStyle.brandSafe.callToActionBackgroundColor,
      const Color(0xff1d4ed8),
    );
  });

  test('native minimum size follows the content padding', () {
    expect(NativeAdTemplate.media.minimumWidthFor(40), 380);
    expect(NativeAdTemplate.media.minimumHeightFor(40), 420);
    expect(NativeAdTemplate.compact.minimumHeightFor(0), 320);
    expect(
      () => NativeAd(
        adRequest: const AdRequest(adUnitId: 'unit'),
        width: 324,
        height: 364,
        style: const NativeAdStyle(contentPadding: 40),
      ),
      throwsArgumentError,
    );
    final ad = NativeAd(
      adRequest: const AdRequest(adUnitId: 'unit'),
      width: 380,
      height: 420,
      style: const NativeAdStyle(contentPadding: 40),
    );
    addTearDown(ad.destroy);
  });

  test('native ad destroy survives an already disposed platform view',
      () async {
    final ad = NativeAd(
      adRequest: const AdRequest(adUnitId: 'unit'),
      width: 324,
      height: 364,
    );
    await ad.destroy();
    await ad.destroy();
  });

  test('managed refresh policy has safe presets and rejects shorter intervals',
      () {
    expect(
      ManagedBannerRefreshPolicy.conservative.refreshInterval,
      const Duration(seconds: 120),
    );
    expect(
      ManagedBannerRefreshPolicy.standard.refreshInterval,
      const Duration(seconds: 60),
    );
    expect(
      ManagedBannerRefreshPolicy.engaged.refreshInterval,
      const Duration(seconds: 30),
    );
    expect(
      () => const ManagedBannerRefreshPolicy(
        refreshInterval: Duration(seconds: 29),
        retryInterval: Duration(seconds: 30),
      ).validate(),
      throwsArgumentError,
    );
    expect(
      () => ManagedBannerAdController(
        adSize: const BannerAdSize.inline(width: 320, maxHeight: 50),
        adRequest: const AdRequest(adUnitId: 'unit'),
        refreshInterval: const Duration(seconds: 29),
      ),
      throwsArgumentError,
    );
  });
}

class _LoaderHarness {
  final _channels = <MethodChannel>[];
  final _events = <EventChannel>[];
  int loadCalls = 0;
  int cancelCalls = 0;
  int destroyCalls = 0;
  int? _requestId;
  MockStreamHandlerEventSink? _loaderEvents;

  Future<void> install() async {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    const createChannel = MethodChannel('yandex_mobileads.createAdLoader');
    _channels.add(createChannel);
    messenger.setMockMethodCallHandler(createChannel, (call) async {
      final id = (call.arguments as Map<dynamic, dynamic>)['id'] as int;
      final channel =
          MethodChannel('yandex_mobileads.interstitialAdLoader.$id');
      final events = EventChannel('${channel.name}.events');
      _channels.add(channel);
      _events.add(events);
      messenger.setMockStreamHandler(
        events,
        MockStreamHandler.inline(
          onListen: (_, eventSink) => _loaderEvents = eventSink,
        ),
      );
      messenger.setMockMethodCallHandler(channel, (call) async {
        switch (call.method) {
          case 'load':
            loadCalls++;
            _requestId =
                (call.arguments as Map<dynamic, dynamic>)['requestId'] as int;
            break;
          case 'cancelLoading':
            cancelCalls++;
            break;
          case 'destroy':
            destroyCalls++;
            break;
        }
        return null;
      });
      return null;
    });
  }

  static void _onListen(Object? _, MockStreamHandlerEventSink __) {}

  Future<void> waitForLoad() async {
    while (loadCalls == 0) {
      await Future<void>.delayed(const Duration(milliseconds: 1));
    }
  }

  void completeLoadedAd() {
    _loaderEvents!.success({
      'name': 'onAdLoaded',
      'requestId': _requestId,
      'id': 91,
      'adInfo': {'adUnitId': 'unit'},
    });
  }

  void dispose() {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    for (final channel in _channels) {
      messenger.setMockMethodCallHandler(channel, null);
    }
    for (final channel in _events) {
      messenger.setMockStreamHandler(channel, null);
    }
  }
}
