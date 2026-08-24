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

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yandex_mobileads/mobile_ads.dart';

import 'support/pool_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late PoolHarness harness;
  late DateTime now;

  setUp(() {
    harness = PoolHarness(
      loaderType: 'appOpenAdLoader',
      adPath: 'appOpenAd',
    );
    harness.install();
    now = DateTime(2026, 8, 24, 12);
  });

  tearDown(() => harness.dispose());

  AppOpenAdController buildController({
    bool showOnColdStart = false,
    Duration minimumBackgroundDuration = const Duration(seconds: 15),
  }) {
    return AppOpenAdController(
      adRequest: const AdRequest(adUnitId: 'unit'),
      showOnColdStart: showOnColdStart,
      minimumBackgroundDuration: minimumBackgroundDuration,
      waitForAd: const Duration(milliseconds: 100),
      clock: () => now,
    );
  }

  Future<void> preload(AppOpenAdController controller) async {
    await controller.start();
    await harness.waitForLoads(1);
    harness.completeLoaded();
    await settle();
  }

  Future<void> completeShow() async {
    await harness.waitForShow();
    harness.emitAdEvent({'name': 'onAdShown'});
    harness.emitAdEvent({'name': 'onAdDismissed'});
  }

  test('a short absence does not count as a new session', () async {
    final controller = buildController();
    await preload(controller);
    now = now.add(const Duration(minutes: 2));

    controller.didChangeAppLifecycleState(AppLifecycleState.paused);
    now = now.add(const Duration(seconds: 5));
    controller.didChangeAppLifecycleState(AppLifecycleState.resumed);
    await settle();

    expect(harness.showCalls, 0,
        reason: 'a permission dialog must not earn an ad');

    await controller.destroy();
  });

  test('a real return shows the preloaded ad', () async {
    final controller = buildController();
    await preload(controller);
    now = now.add(const Duration(minutes: 2));

    final shown = controller.shows.first;
    controller.didChangeAppLifecycleState(AppLifecycleState.paused);
    now = now.add(const Duration(seconds: 30));
    controller.didChangeAppLifecycleState(AppLifecycleState.resumed);
    await completeShow();

    expect((await shown).isShown, isTrue);
    expect(controller.frequencyGate.sessionShowCount, 1);

    await controller.destroy();
  });

  test('a return that follows an ad click is suppressed', () async {
    final controller = buildController();
    await preload(controller);
    now = now.add(const Duration(minutes: 2));

    // The user sees an ad and taps it, which sends them out of the app.
    final firstShow = controller.showIfAllowed();
    await harness.waitForShow();
    harness.emitAdEvent({'name': 'onAdShown'});
    harness.emitAdEvent({'name': 'onAdClicked'});
    harness.emitAdEvent({'name': 'onAdDismissed'});
    await firstShow;

    await harness.waitForLoads(2);
    harness.completeLoaded();
    await settle();
    // Far enough that the frequency policy is no longer the reason.
    now = now.add(const Duration(minutes: 20));

    controller.didChangeAppLifecycleState(AppLifecycleState.paused);
    now = now.add(const Duration(minutes: 1));
    controller.didChangeAppLifecycleState(AppLifecycleState.resumed);
    await settle();

    expect(harness.showCalls, 1,
        reason: 'the user left to follow an ad, not to end the session');

    await controller.destroy();
  });

  test('a cold start show does not block start()', () async {
    final controller = buildController(showOnColdStart: true);

    await controller.start().timeout(const Duration(seconds: 2));
    await harness.waitForLoads(1);
    harness.completeLoaded();
    await completeShow();
    await settle();

    expect(harness.showCalls, 1,
        reason: 'the launch show skips the startup grace on purpose');

    await controller.destroy();
  });

  test('a destroyed controller refuses to be used again', () async {
    final controller = buildController();
    await preload(controller);
    await controller.destroy();
    await controller.destroy();

    expect(controller.isDestroyed, isTrue);
    await expectLater(controller.showIfAllowed(), throwsStateError);
  });
}
