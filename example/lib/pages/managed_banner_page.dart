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

import 'package:flutter/material.dart';
import 'package:yandex_mobileads/mobile_ads.dart';

class ManagedBannerPage extends StatefulWidget {
  const ManagedBannerPage({super.key});

  @override
  State<ManagedBannerPage> createState() => _ManagedBannerPageState();
}

class _ManagedBannerPageState extends State<ManagedBannerPage> {
  static const _demoAdUnitId = 'demo-banner-yandex';

  ManagedBannerRefreshPolicy _refreshPolicy =
      ManagedBannerRefreshPolicy.standard;
  ManagedBannerAdController? _controller;
  int? _bannerWidth;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final width = (MediaQuery.sizeOf(context).width - 32.0).floor();
    if (width > 0 && width != _bannerWidth) {
      final previous = _controller;
      _bannerWidth = width;
      _controller = _createController(width);
      if (previous != null) unawaited(previous.destroy());
    }
  }

  @override
  void dispose() {
    unawaited(_controller?.destroy() ?? Future<void>.value());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    return Scaffold(
      appBar: AppBar(title: const Text('Managed banner refresh')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            Text(
              'The controller counts visible time only. It pauses while the '
              'app is backgrounded or this banner scrolls off screen, and it '
              'never overlaps loads.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16.0),
            DropdownButtonFormField<ManagedBannerRefreshPolicy>(
              key: ValueKey(_refreshPolicy),
              initialValue: _refreshPolicy,
              decoration: const InputDecoration(labelText: 'Refresh preset'),
              items: const [
                DropdownMenuItem(
                  value: ManagedBannerRefreshPolicy.conservative,
                  child: Text('Conservative — every 120 seconds'),
                ),
                DropdownMenuItem(
                  value: ManagedBannerRefreshPolicy.standard,
                  child: Text('Standard — every 60 seconds'),
                ),
                DropdownMenuItem(
                  value: ManagedBannerRefreshPolicy.engaged,
                  child: Text('Engaged — every 30 seconds'),
                ),
              ],
              onChanged: (policy) {
                if (policy != null) _changePolicy(policy);
              },
            ),
            const SizedBox(height: 16.0),
            if (controller != null)
              AnimatedBuilder(
                animation: controller,
                builder: (context, _) {
                  final phase = controller.isLoading ? 'Loading…' : 'Ready';
                  return Text(
                    '$phase • visible refresh: '
                    '${controller.refreshInterval.inSeconds}s • retry: '
                    '${controller.retryInterval.inSeconds}s',
                    style: Theme.of(context).textTheme.bodySmall,
                  );
                },
              ),
            const SizedBox(height: 16.0),
            if (controller != null)
              Center(
                child: ManagedBannerAdWidget(
                  key: ValueKey(controller),
                  controller: controller,
                ),
              ),
            const SizedBox(height: 24.0),
            Text(
              'Scroll this placement out of view or send the app to the '
              'background to pause the refresh clock. The demo uses a test '
              'banner placement only.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  ManagedBannerAdController _createController(int width) {
    return ManagedBannerAdController(
      adSize: BannerAdSize.inline(width: width, maxHeight: 100),
      adRequest: const AdRequest(adUnitId: _demoAdUnitId),
      refreshPolicy: _refreshPolicy,
    );
  }

  void _changePolicy(ManagedBannerRefreshPolicy policy) {
    if (_refreshPolicy == policy || _bannerWidth == null) return;
    final previous = _controller;
    setState(() {
      _refreshPolicy = policy;
      _controller = _createController(_bannerWidth!);
    });
    if (previous != null) unawaited(previous.destroy());
  }
}
