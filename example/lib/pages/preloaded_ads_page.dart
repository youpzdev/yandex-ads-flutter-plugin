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

class PreloadedAdsPage extends StatefulWidget {
  const PreloadedAdsPage({super.key});

  @override
  State<PreloadedAdsPage> createState() => _PreloadedAdsPageState();
}

class _PreloadedAdsPageState extends State<PreloadedAdsPage> {
  late final AdFrequencyGate _gate;
  late final FullscreenAdPool<InterstitialAd> _pool;

  StreamSubscription<FullscreenAdPoolState>? _poolStates;
  StreamSubscription<AdEvent>? _events;

  FullscreenAdPoolState? _state;
  final _log = <String>[];
  String _status = 'Preloading an interstitial ad.';

  @override
  void initState() {
    super.initState();
    _gate = AdFrequencyGate(
      policy: const AdFrequencyPolicy(
        startupGrace: Duration(seconds: 5),
        minimumInterval: Duration(seconds: 45),
        maximumPerHour: 6,
        maximumPerDay: 20,
      ),
    );
    _pool = FullscreenAdPool.interstitial(
      adRequest: const AdRequest(adUnitId: 'demo-interstitial-yandex'),
      capacity: 2,
      frequencyGate: _gate,
      retryPolicy: AdRetryPolicy.standard,
    );
    _poolStates = _pool.states.listen((state) {
      if (mounted) setState(() => _state = state);
    });
    _events = YandexAds.events.listen((event) {
      if (!mounted) return;
      setState(() {
        _log.insert(0, '${event.type.name} · ${event.format.name}');
        if (_log.length > 12) _log.removeLast();
      });
    });
    unawaited(_pool.start());
  }

  @override
  void dispose() {
    unawaited(_poolStates?.cancel());
    unawaited(_events?.cancel());
    unawaited(_pool.destroy());
    super.dispose();
  }

  Future<void> _show() async {
    final outcome = await _pool.showNext(waitFor: const Duration(seconds: 3));
    if (!mounted) return;
    setState(() => _status = _describe(outcome));
  }

  String _describe(AdShowOutcome outcome) {
    switch (outcome.status) {
      case AdShowStatus.shown:
        return 'Shown. The next ad is already loading.';
      case AdShowStatus.blocked:
        final frequency = outcome.frequency;
        final wait = frequency?.retryAfter;
        final reason = frequency?.block.name ?? 'policy';
        return wait == null
            ? 'Blocked by $reason for the rest of the session.'
            : 'Blocked by $reason, try again in ${wait.inSeconds} s.';
      case AdShowStatus.unavailable:
        return 'No ad was ready in time.';
      case AdShowStatus.alreadyShowing:
        return 'Another full-screen ad is on screen right now.';
      case AdShowStatus.failed:
        return 'The ad could not be displayed: ${outcome.error?.description}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = _state;
    final decision = _gate.evaluate();
    return Scaffold(
      appBar: AppBar(title: const Text('Preloaded interstitial')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(_status, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Pool: ${state?.status.name ?? 'idle'}'),
                  Text('Ready: ${state?.available ?? 0} of ${_pool.capacity}'),
                  Text('Failures in a row: ${state?.consecutiveFailures ?? 0}'),
                  if (state?.lastError != null)
                    Text('Last error: ${state?.lastError}'),
                  const Divider(),
                  Text(
                    decision.isAllowed
                        ? 'Frequency: a show is allowed now'
                        : 'Frequency: ${decision.block.name}'
                            '${decision.retryAfter == null ? '' : ' for '
                                '${decision.retryAfter!.inSeconds} s'}',
                  ),
                  Text('Shown this session: ${_gate.sessionShowCount}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _show,
            child: const Text('Show interstitial'),
          ),
          const SizedBox(height: 24),
          Text('Ad events', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          for (final entry in _log) Text(entry),
        ],
      ),
    );
  }
}
