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

enum _Format {
  interstitial('Interstitial', 'demo-interstitial-yandex'),
  appOpen('App open', 'demo-appopenad-yandex');

  const _Format(this.title, this.adUnitId);

  final String title;
  final String adUnitId;
}

class PreloadedAdsPage extends StatefulWidget {
  const PreloadedAdsPage({super.key});

  @override
  State<PreloadedAdsPage> createState() => _PreloadedAdsPageState();
}

class _PreloadedAdsPageState extends State<PreloadedAdsPage> {
  static const _policy = AdFrequencyPolicy(
    startupGrace: Duration(seconds: 5),
    minimumInterval: Duration(seconds: 45),
    maximumPerHour: 6,
    maximumPerDay: 20,
  );

  _Format _format = _Format.interstitial;
  late AdFrequencyGate _gate;
  late FullscreenAdPool<Object> _pool;

  StreamSubscription<FullscreenAdPoolState>? _poolStates;
  StreamSubscription<AdEvent>? _events;

  FullscreenAdPoolState? _state;
  Duration? _lastDuration;
  final _log = <String>[];
  String _status = 'Preloading an ad.';

  @override
  void initState() {
    super.initState();
    _events = YandexAds.events.listen((event) {
      if (!mounted) return;
      setState(() {
        _log.insert(0, '${event.type.name} · ${event.format.name}');
        if (_log.length > 12) _log.removeLast();
      });
    });
    _startPool();
  }

  @override
  void dispose() {
    unawaited(_poolStates?.cancel());
    unawaited(_events?.cancel());
    unawaited(_pool.destroy());
    super.dispose();
  }

  void _startPool() {
    _gate = AdFrequencyGate(policy: _policy);
    _pool = _format == _Format.interstitial
        ? FullscreenAdPool.interstitial(
            adRequest: AdRequest(adUnitId: _format.adUnitId),
            capacity: 2,
            frequencyGate: _gate,
          )
        : FullscreenAdPool.appOpen(
            adRequest: AdRequest(adUnitId: _format.adUnitId),
            capacity: 2,
            frequencyGate: _gate,
          );
    _poolStates = _pool.states.listen((state) {
      if (mounted) setState(() => _state = state);
    });
    unawaited(_pool.start());
  }

  Future<void> _changeFormat(_Format format) async {
    if (format == _format) return;
    final previous = _pool;
    await _poolStates?.cancel();
    setState(() {
      _format = format;
      _state = null;
      _lastDuration = null;
      _status = 'Preloading a ${format.title.toLowerCase()} ad.';
    });
    _startPool();
    await previous.destroy();
  }

  Future<void> _show() async {
    final outcome = await _pool.showNext(waitFor: const Duration(seconds: 3));
    if (!mounted) return;
    setState(() {
      _lastDuration = outcome.duration;
      _status = _describe(outcome);
    });
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
    final duration = _lastDuration;
    return Scaffold(
      appBar: AppBar(title: const Text('Preloaded full-screen')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SegmentedButton<_Format>(
            segments: [
              for (final format in _Format.values)
                ButtonSegment(value: format, label: Text(format.title)),
            ],
            selected: {_format},
            onSelectionChanged: (selection) => _changeFormat(selection.first),
          ),
          const SizedBox(height: 8),
          Text(
            'The close button belongs to the ad SDK and the creative. '
            'Compare both formats here to pick the dismissal a placement '
            'needs.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
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
                  if (duration != null)
                    Text('Last ad held the screen: '
                        '${(duration.inMilliseconds / 1000).toStringAsFixed(1)}'
                        ' s'),
                  Text('Next gap after it: '
                      '${_gate.effectiveMinimumInterval.inSeconds} s'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _show,
            child: Text('Show ${_format.title.toLowerCase()}'),
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
