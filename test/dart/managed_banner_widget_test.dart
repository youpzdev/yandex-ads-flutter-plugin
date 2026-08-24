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

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yandex_mobileads/mobile_ads.dart';

const _mockedBannerIds = 10;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(
      SystemChannels.platform_views,
      (call) async => call.method == 'create' ? 0 : null,
    );
    for (var id = 0; id < _mockedBannerIds; id++) {
      messenger.setMockMethodCallHandler(
        MethodChannel('yandex_mobileads.bannerAd.$id'),
        (call) async => null,
      );
      messenger.setMockStreamHandler(
        EventChannel('yandex_mobileads.bannerAd.$id.events'),
        const MockStreamHandler.inline(onListen: _ignoreListen),
      );
    }
  });

  tearDown(() {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(SystemChannels.platform_views, null);
    for (var id = 0; id < _mockedBannerIds; id++) {
      messenger.setMockMethodCallHandler(
        MethodChannel('yandex_mobileads.bannerAd.$id'),
        null,
      );
      messenger.setMockStreamHandler(
        EventChannel('yandex_mobileads.bannerAd.$id.events'),
        null,
      );
    }
  });

  testWidgets('a managed banner at the top of an unpadded list loads',
      (tester) async {
    final controller = ManagedBannerAdController(
      adSize: const BannerAdSize.inline(width: 320, maxHeight: 100),
      adRequest: const AdRequest(adUnitId: 'unit'),
      loadTimeout: const Duration(milliseconds: 50),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: ListView(
          children: [
            ManagedBannerAdWidget(controller: controller),
            const SizedBox(height: 2000),
          ],
        ),
      ),
    );
    await tester.pump();

    expect(controller.isLoading, isTrue);

    await tester.runAsync(controller.destroy);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('a managed banner outside the viewport does not load',
      (tester) async {
    final controller = ManagedBannerAdController(
      adSize: const BannerAdSize.inline(width: 320, maxHeight: 100),
      adRequest: const AdRequest(adUnitId: 'unit'),
      loadTimeout: const Duration(milliseconds: 50),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: ListView(
          children: [
            const SizedBox(height: 4000),
            ManagedBannerAdWidget(controller: controller),
          ],
        ),
      ),
    );
    await tester.pump();

    expect(controller.isLoading, isFalse);

    await tester.runAsync(controller.destroy);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('an ad widget mounts the platform view once loading starts',
      (tester) async {
    final banner = BannerAd(
      adSize: const BannerAdSize.inline(width: 320, maxHeight: 100),
    );

    await tester.pumpWidget(MaterialApp(home: AdWidget(bannerAd: banner)));
    expect(find.byType(AndroidView), findsNothing);

    final loading = banner.load(
      const AdRequest(adUnitId: 'unit'),
      timeout: const Duration(seconds: 5),
    );
    await tester.pump();
    await tester.pump();

    expect(find.byType(AndroidView), findsOneWidget);

    await tester.runAsync(() async {
      await loading;
      await banner.destroy();
    });
    debugDefaultTargetPlatformOverride = null;
  });

  test('destroying a banner that never had a platform view succeeds', () async {
    final banner = BannerAd(adSize: const BannerAdSize.sticky(width: 320));
    await banner.destroy();
    await banner.destroy();
  });

  test('destroying an unused fullscreen loader succeeds', () async {
    final loader = InterstitialAdLoader();
    await loader.destroy();
    await loader.destroy();
  });
}

void _ignoreListen(Object? arguments, MockStreamHandlerEventSink events) {}
