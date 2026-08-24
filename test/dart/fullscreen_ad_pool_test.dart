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
import 'package:yandex_mobileads/mobile_ads.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a pool preloads up to its capacity', () async {
    final harness = _PoolHarness();
    addTearDown(harness.dispose);
    harness.install();

    final pool = FullscreenAdPool.interstitial(
      adRequest: const AdRequest(adUnitId: 'unit'),
      capacity: 2,
    );
    addTearDown(pool.destroy);

    await pool.start();
    await harness.waitForLoads(1);
    harness.completeLoaded();
    await harness.waitForLoads(2);
    harness.completeLoaded();
    await _settle();

    expect(pool.availableCount, 2);
    expect(pool.isReady, isTrue);
    expect(pool.state.status, FullscreenAdPoolStatus.ready);
  });

  test('acquire hands out a ready ad and refills behind it', () async {
    final harness = _PoolHarness();
    addTearDown(harness.dispose);
    harness.install();

    final pool = FullscreenAdPool.interstitial(
      adRequest: const AdRequest(adUnitId: 'unit'),
    );
    addTearDown(pool.destroy);

    await pool.start();
    await harness.waitForLoads(1);
    harness.completeLoaded();
    await _settle();

    final ad = await pool.acquire();
    expect(ad, isNotNull);
    expect(pool.availableCount, 0);

    await harness.waitForLoads(2);
    harness.completeLoaded();
    await _settle();
    expect(pool.availableCount, 1);

    await ad!.destroy();
  });

  test('acquire waits for a load that is still in flight', () async {
    final harness = _PoolHarness();
    addTearDown(harness.dispose);
    harness.install();

    final pool = FullscreenAdPool.interstitial(
      adRequest: const AdRequest(adUnitId: 'unit'),
    );
    addTearDown(pool.destroy);

    final acquired = pool.acquire(waitFor: const Duration(seconds: 5));
    await harness.waitForLoads(1);
    harness.completeLoaded();

    expect(await acquired, isNotNull);
  });

  test('acquire gives up when nothing arrives in time', () async {
    final harness = _PoolHarness();
    addTearDown(harness.dispose);
    harness.install();

    final pool = FullscreenAdPool.interstitial(
      adRequest: const AdRequest(adUnitId: 'unit'),
    );
    addTearDown(pool.destroy);

    final acquired =
        await pool.acquire(waitFor: const Duration(milliseconds: 30));

    expect(acquired, isNull);
  });

  test('a stale ad is dropped instead of being handed out', () async {
    final harness = _PoolHarness();
    addTearDown(harness.dispose);
    harness.install();

    var now = DateTime(2026, 8, 24, 12);
    final pool = FullscreenAdPool.interstitial(
      adRequest: const AdRequest(adUnitId: 'unit'),
      timeToLive: const Duration(minutes: 10),
      clock: () => now,
    );
    addTearDown(pool.destroy);

    await pool.start();
    await harness.waitForLoads(1);
    harness.completeLoaded();
    await _settle();
    expect(pool.availableCount, 1);

    now = now.add(const Duration(minutes: 11));
    expect(pool.availableCount, 0);
    await _settle();

    expect(harness.destroyedAds, isNotEmpty);
  });

  test('a failed request backs off and is repeated', () async {
    final harness = _PoolHarness();
    addTearDown(harness.dispose);
    harness.install();

    final pool = FullscreenAdPool.interstitial(
      adRequest: const AdRequest(adUnitId: 'unit'),
      retryPolicy: const AdRetryPolicy(
        initialDelay: Duration(milliseconds: 20),
        maximumDelay: Duration(milliseconds: 20),
        jitter: 0,
      ),
    );
    addTearDown(pool.destroy);

    await pool.start();
    await harness.waitForLoads(1);
    harness.completeFailed();
    await _settle();

    expect(pool.state.status, FullscreenAdPoolStatus.backingOff);
    expect(pool.state.consecutiveFailures, 1);
    expect(pool.state.lastError, isA<AdRequestError>());

    await harness.waitForLoads(2);
    harness.completeLoaded();
    await _settle();

    expect(pool.availableCount, 1);
    expect(pool.state.consecutiveFailures, 0);
  });

  test('the frequency policy blocks a show before an ad is taken', () async {
    final harness = _PoolHarness();
    addTearDown(harness.dispose);
    harness.install();

    var now = DateTime(2026, 8, 24, 12);
    final gate = AdFrequencyGate(
      policy: const AdFrequencyPolicy(
        startupGrace: Duration.zero,
        minimumInterval: Duration(minutes: 5),
        maximumPerHour: null,
        maximumPerDay: null,
      ),
      clock: () => now,
    );
    gate.recordShow();

    final pool = FullscreenAdPool.interstitial(
      adRequest: const AdRequest(adUnitId: 'unit'),
      frequencyGate: gate,
      clock: () => now,
    );
    addTearDown(pool.destroy);

    await pool.start();
    await harness.waitForLoads(1);
    harness.completeLoaded();
    await _settle();

    final outcome = await pool.showNext();

    expect(outcome.status, AdShowStatus.blocked);
    expect(outcome.frequency?.block, AdFrequencyBlock.minimumInterval);
    expect(pool.availableCount, 1, reason: 'a blocked show keeps the ad');
  });

  test('showNext displays, records the show and releases the ad', () async {
    final harness = _PoolHarness();
    addTearDown(harness.dispose);
    harness.install();

    var now = DateTime(2026, 8, 24, 12);
    final gate = AdFrequencyGate(
      policy: const AdFrequencyPolicy(
        startupGrace: Duration.zero,
        minimumInterval: Duration(minutes: 5),
        maximumPerHour: null,
        maximumPerDay: null,
      ),
      clock: () => now,
    );

    final pool = FullscreenAdPool.interstitial(
      adRequest: const AdRequest(adUnitId: 'unit'),
      frequencyGate: gate,
      clock: () => now,
    );
    addTearDown(pool.destroy);

    final shownEvents = <AdEvent>[];
    final subscription = YandexAds.events.listen(shownEvents.add);
    addTearDown(subscription.cancel);

    await pool.start();
    await harness.waitForLoads(1);
    harness.completeLoaded();
    await _settle();

    var clicked = false;
    final showing = pool.showNext(onAdClicked: () => clicked = true);
    await harness.waitForShow();
    harness.emitAdEvent({'name': 'onAdShown'});
    harness.emitAdEvent({'name': 'onAdClicked'});
    harness.emitAdEvent({'name': 'onAdDismissed'});

    final outcome = await showing;

    expect(outcome.isShown, isTrue);
    expect(clicked, isTrue);
    expect(gate.sessionShowCount, 1);
    expect(gate.isAllowed, isFalse, reason: 'the show consumed the interval');
    expect(harness.destroyedAds, contains(harness.lastAdId));
    expect(
      shownEvents.map((event) => event.type),
      containsAll(<AdEventType>[
        AdEventType.loaded,
        AdEventType.shown,
        AdEventType.clicked,
        AdEventType.dismissed,
      ]),
    );
    expect(
      shownEvents
          .where((event) => event.type == AdEventType.shown)
          .single
          .format,
      AdFormat.interstitial,
    );
  });

  test('showNext reports that nothing was ready', () async {
    final harness = _PoolHarness();
    addTearDown(harness.dispose);
    harness.install();

    final pool = FullscreenAdPool.interstitial(
      adRequest: const AdRequest(adUnitId: 'unit'),
    );
    addTearDown(pool.destroy);

    final outcome = await pool.showNext();

    expect(outcome.status, AdShowStatus.unavailable);
  });

  test('destroy releases held ads and refuses further use', () async {
    final harness = _PoolHarness();
    addTearDown(harness.dispose);
    harness.install();

    final pool = FullscreenAdPool.interstitial(
      adRequest: const AdRequest(adUnitId: 'unit'),
    );

    await pool.start();
    await harness.waitForLoads(1);
    harness.completeLoaded();
    await _settle();

    await pool.destroy();
    await pool.destroy();

    expect(harness.destroyedAds, contains(harness.lastAdId));
    expect(pool.isDestroyed, isTrue);
    expect(() => pool.acquire(), throwsStateError);
  });
}

Future<void> _settle() =>
    Future<void>.delayed(const Duration(milliseconds: 20));

class _PoolHarness {
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
      final channel =
          MethodChannel('yandex_mobileads.interstitialAdLoader.$id');
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
    final channel = MethodChannel('yandex_mobileads.interstitialAd.$adId');
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
