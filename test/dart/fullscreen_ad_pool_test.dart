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

  test('an ad that answers after a timeout is released, not leaked', () async {
    final harness = PoolHarness();
    addTearDown(harness.dispose);
    harness.install();

    final loader = InterstitialAdLoader();
    addTearDown(loader.destroy);

    final events = <AdEvent>[];
    final subscription = YandexAds.events.listen(events.add);
    addTearDown(subscription.cancel);

    await expectLater(
      loader.loadAd(
        adRequest: const AdRequest(adUnitId: 'unit'),
        timeout: const Duration(milliseconds: 20),
      ),
      throwsA(isA<TimeoutException>()),
    );

    // The native side answers after nobody is waiting any more.
    harness.completeLoaded();
    await settle();

    expect(harness.destroyedAds, contains(harness.lastAdId),
        reason: 'an orphan ad must be released on the native side');
    expect(
      events.where((event) => event.type == AdEventType.loaded),
      isEmpty,
      reason: 'a load nobody received is not a load',
    );
  });

  test('an ad loaded across a consent change is dropped', () async {
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

    // The user answers the consent prompt while the request is in flight.
    await YandexAds.setUserConsent(false);
    harness.completeLoaded();
    await settle();

    expect(pool.availableCount, 0,
        reason: 'the request was sent under the previous answer');
    expect(harness.destroyedAds, contains(harness.lastAdId));
  });

  test('two pools cannot both claim the screen', () async {
    final first = PoolHarness();
    addTearDown(first.dispose);
    first.install();

    final poolA = FullscreenAdPool.interstitial(
      adRequest: const AdRequest(adUnitId: 'unit'),
    );
    final poolB = FullscreenAdPool.interstitial(
      adRequest: const AdRequest(adUnitId: 'unit'),
    );
    addTearDown(poolA.destroy);
    addTearDown(poolB.destroy);

    await poolA.start();
    await first.waitForLoads(1);
    first.completeLoaded();
    await poolB.start();
    await first.waitForLoads(2);
    first.completeLoaded();
    await settle();

    final showA = poolA.showNext();
    final showB = poolB.showNext();

    final outcomeB = await showB;
    expect(outcomeB.status, AdShowStatus.alreadyShowing,
        reason: 'the second pool must not stack another ad on the screen');
    expect(poolB.availableCount, 1,
        reason: 'an ad that could not be shown goes back to its pool');
    expect(first.destroyedAds, isEmpty,
        reason: 'nothing was shown, so nothing should be released');

    await first.waitForShow();
    first.emitAdEvent({'name': 'onAdShown'});
    first.emitAdEvent({'name': 'onAdDismissed'});
    expect((await showA).isShown, isTrue);
    expect(first.showCalls, 1);
  });

  test('a repeated reward callback grants the reward once', () async {
    final harness = PoolHarness(
      loaderType: 'rewardedAdLoader',
      adPath: 'rewardedAd',
    );
    addTearDown(harness.dispose);
    harness.install();

    final pool = FullscreenAdPool.rewarded(
      adRequest: const AdRequest(adUnitId: 'unit'),
    );
    addTearDown(pool.destroy);

    await pool.start();
    await harness.waitForLoads(1);
    harness.completeLoaded();
    await settle();

    var rewards = 0;
    final showing = pool.showNext(onRewarded: (_) => rewards++);
    await harness.waitForShow();
    harness.emitAdEvent({'name': 'onAdShown'});
    harness.emitAdEvent({'name': 'onRewarded', 'type': 'coins', 'amount': 10});
    harness.emitAdEvent({'name': 'onRewarded', 'type': 'coins', 'amount': 10});
    harness.emitAdEvent({'name': 'onAdDismissed'});

    final outcome = await showing;

    expect(rewards, 1);
    expect(outcome.reward?.amount, 10);
  });

  test('an acquired ad refuses to show after a targeting change', () async {
    final harness = PoolHarness();
    addTearDown(harness.dispose);
    harness.install();

    const settings = MethodChannel('yandex_mobileads.mobileAds');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(settings, (call) async => null);
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(settings, null);
    });

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

    await YandexAds.setLocationTracking(false);

    await expectLater(ad!.show(), throwsStateError);
    expect(harness.showCalls, 0);

    await ad.destroy();
  });

  test('an ad cannot be shown twice', () async {
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

    final ad = (await pool.acquire())!;
    await ad.setAdEventListener(eventListener: InterstitialAdEventListener());
    await ad.show();

    await expectLater(ad.show(), throwsStateError);
    expect(harness.showCalls, 1);

    harness.emitAdEvent({'name': 'onAdDismissed'});
    await settle();
    await ad.destroy();
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
