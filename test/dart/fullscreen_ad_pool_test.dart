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

import 'support/pool_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a pool preloads up to its capacity', () async {
    final harness = PoolHarness();
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
    await settle();

    expect(pool.availableCount, 2);
    expect(pool.isReady, isTrue);
    expect(pool.state.status, FullscreenAdPoolStatus.ready);
  });

  test('acquire hands out a ready ad and refills behind it', () async {
    final harness = PoolHarness();
    addTearDown(harness.dispose);
    harness.install();

    final pool = FullscreenAdPool.interstitial(
      adRequest: const AdRequest(adUnitId: 'unit'),
    );
    addTearDown(pool.destroy);

    await pool.start();
    await harness.waitForLoads(1);
    harness.completeLoaded();
    await settle();

    final ad = await pool.acquire();
    expect(ad, isNotNull);
    expect(pool.availableCount, 0);

    await harness.waitForLoads(2);
    harness.completeLoaded();
    await settle();
    expect(pool.availableCount, 1);

    await ad!.destroy();
  });

  test('acquire waits for a load that is still in flight', () async {
    final harness = PoolHarness();
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
    final harness = PoolHarness();
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
    final harness = PoolHarness();
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
    await settle();
    expect(pool.availableCount, 1);

    now = now.add(const Duration(minutes: 11));
    expect(pool.availableCount, 0);
    await settle();

    expect(harness.destroyedAds, isNotEmpty);
  });

  test('a failed request backs off and is repeated', () async {
    final harness = PoolHarness();
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
    await settle();

    expect(pool.state.status, FullscreenAdPoolStatus.backingOff);
    expect(pool.state.consecutiveFailures, 1);
    expect(pool.state.lastError, isA<AdRequestError>());

    await harness.waitForLoads(2);
    harness.completeLoaded();
    await settle();

    expect(pool.availableCount, 1);
    expect(pool.state.consecutiveFailures, 0);
  });

  test('the frequency policy blocks a show before an ad is taken', () async {
    final harness = PoolHarness();
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
    await settle();

    final outcome = await pool.showNext();

    expect(outcome.status, AdShowStatus.blocked);
    expect(outcome.frequency?.block, AdFrequencyBlock.minimumInterval);
    expect(pool.availableCount, 1, reason: 'a blocked show keeps the ad');
  });

  test('showNext displays, records the show and releases the ad', () async {
    final harness = PoolHarness();
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
    await settle();

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

  test('a used up retry budget stops requesting until retry()', () async {
    final harness = PoolHarness();
    addTearDown(harness.dispose);
    harness.install();

    final pool = FullscreenAdPool.interstitial(
      adRequest: const AdRequest(adUnitId: 'unit'),
      retryPolicy: const AdRetryPolicy(
        initialDelay: Duration(milliseconds: 10),
        maximumDelay: Duration(milliseconds: 10),
        jitter: 0,
        maximumAttempts: 2,
      ),
    );
    addTearDown(pool.destroy);

    await pool.start();
    await harness.waitForLoads(1);
    harness.completeFailed();
    await harness.waitForLoads(2);
    harness.completeFailed();
    await settle();

    expect(pool.state.status, FullscreenAdPoolStatus.exhausted);

    // A pool that gave up must not request again through the back door.
    await pool.acquire();
    await settle();
    expect(harness.loadCalls, 2);

    await pool.retry();
    await harness.waitForLoads(3);
    harness.completeLoaded();
    await settle();
    expect(pool.availableCount, 1);
  });

  test('a show that the platform refuses returns the cap', () async {
    final harness = PoolHarness();
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

    await pool.start();
    await harness.waitForLoads(1);
    harness.completeLoaded();
    await settle();

    final showing = pool.showNext();
    await harness.waitForShow();
    harness.emitAdEvent({
      'name': 'onAdFailedToShow',
      'description': 'no activity',
    });
    final outcome = await showing;

    expect(outcome.status, AdShowStatus.failed);
    expect(gate.sessionShowCount, 0,
        reason: 'a show that never happened must not consume the cap');
    expect(gate.isAllowed, isTrue);
  });

  test('a second show is refused while one is on screen', () async {
    final harness = PoolHarness();
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
    await settle();

    final first = pool.showNext();
    await harness.waitForShow();
    final second = await pool.showNext();

    expect(second.status, AdShowStatus.alreadyShowing);
    expect(harness.showCalls, 1);

    harness.emitAdEvent({'name': 'onAdShown'});
    harness.emitAdEvent({'name': 'onAdDismissed'});
    expect((await first).isShown, isTrue);
  });

  test('a consent change drops ads requested under the old answer', () async {
    final harness = PoolHarness();
    addTearDown(harness.dispose);
    harness.install();

    const consentChannel = MethodChannel('yandex_mobileads.mobileAds');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(consentChannel, (call) async => null);
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(consentChannel, null);
    });

    final pool = FullscreenAdPool.interstitial(
      adRequest: const AdRequest(adUnitId: 'unit'),
    );
    addTearDown(pool.destroy);

    await pool.start();
    await harness.waitForLoads(1);
    harness.completeLoaded();
    await settle();
    expect(pool.availableCount, 1);

    await YandexAds.setUserConsent(false);

    expect(pool.availableCount, 0,
        reason: 'the ad was requested under the previous answer');
  });

  test('showNext reports that nothing was ready', () async {
    final harness = PoolHarness();
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
    final harness = PoolHarness();
    addTearDown(harness.dispose);
    harness.install();

    final pool = FullscreenAdPool.interstitial(
      adRequest: const AdRequest(adUnitId: 'unit'),
    );

    await pool.start();
    await harness.waitForLoads(1);
    harness.completeLoaded();
    await settle();

    await pool.destroy();
    await pool.destroy();

    expect(harness.destroyedAds, contains(harness.lastAdId));
    expect(pool.isDestroyed, isTrue);
    expect(() => pool.acquire(), throwsStateError);
  });
}
