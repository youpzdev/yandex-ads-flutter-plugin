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

enum _NativeStylePreset { light, dark, brandSafe }

class NativeAdPage extends StatefulWidget {
  const NativeAdPage({super.key});

  @override
  State<NativeAdPage> createState() => _NativeAdPageState();
}

class _NativeAdPageState extends State<NativeAdPage> {
  static const _demoAdUnitId = 'demo-native-content-yandex';

  NativeAdTemplate _template = NativeAdTemplate.compact;
  _NativeStylePreset _stylePreset = _NativeStylePreset.light;
  NativeAd? _nativeAd;
  StreamSubscription<NativeAdLoadState>? _loadStateSubscription;
  StreamSubscription<NativeAdEvent>? _eventSubscription;
  String _status = 'Choose a template and load the official demo placement.';
  bool _isLoading = false;

  NativeAdStyle get _style {
    switch (_stylePreset) {
      case _NativeStylePreset.light:
        return NativeAdStyle.light;
      case _NativeStylePreset.dark:
        return NativeAdStyle.dark;
      case _NativeStylePreset.brandSafe:
        return NativeAdStyle.brandSafe;
    }
  }

  @override
  void dispose() {
    unawaited(_loadStateSubscription?.cancel());
    unawaited(_eventSubscription?.cancel());
    unawaited(_nativeAd?.destroy() ?? Future<void>.value());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = _template.minimumWidth;
    final height = _template.minimumHeight;
    final hasEnoughWidth = MediaQuery.sizeOf(context).width - 32.0 >= width;
    return Scaffold(
      appBar: AppBar(title: const Text('Native ad')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            Text(
              'This screen uses only Yandex’s official native test placement. '
              'No production ID or programmatic click is used.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16.0),
            DropdownButtonFormField<NativeAdTemplate>(
              key: ValueKey(_template),
              initialValue: _template,
              decoration: const InputDecoration(labelText: 'Template'),
              items: const [
                DropdownMenuItem(
                  value: NativeAdTemplate.compact,
                  child: Text('Compact — 324 × 412 minimum'),
                ),
                DropdownMenuItem(
                  value: NativeAdTemplate.media,
                  child: Text('Media — 324 × 432 minimum'),
                ),
              ],
              onChanged: (template) {
                if (template != null) unawaited(_changeTemplate(template));
              },
            ),
            const SizedBox(height: 12.0),
            DropdownButtonFormField<_NativeStylePreset>(
              key: ValueKey(_stylePreset),
              initialValue: _stylePreset,
              decoration: const InputDecoration(labelText: 'Style preset'),
              items: const [
                DropdownMenuItem(
                  value: _NativeStylePreset.light,
                  child: Text('Light'),
                ),
                DropdownMenuItem(
                  value: _NativeStylePreset.dark,
                  child: Text('Dark'),
                ),
                DropdownMenuItem(
                  value: _NativeStylePreset.brandSafe,
                  child: Text('Brand safe'),
                ),
              ],
              onChanged: (preset) {
                if (preset != null) unawaited(_changeStyle(preset));
              },
            ),
            const SizedBox(height: 16.0),
            FilledButton.icon(
              onPressed: _isLoading || !hasEnoughWidth ? null : _loadNativeAd,
              icon: _isLoading
                  ? const SizedBox(
                      width: 18.0,
                      height: 18.0,
                      child: CircularProgressIndicator(strokeWidth: 2.0),
                    )
                  : const Icon(Icons.download_outlined),
              label: Text(_isLoading ? 'Loading' : 'Load native ad'),
            ),
            const SizedBox(height: 12.0),
            Text(_status, style: Theme.of(context).textTheme.bodySmall),
            if (!hasEnoughWidth) ...[
              const SizedBox(height: 8.0),
              Text(
                'The selected template is disabled until at least $width '
                'logical pixels are available.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 16.0),
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < width) {
                  return Text(
                    'This template requires at least $width logical pixels '
                    'of available width. Rotate the device or use a wider '
                    'layout; the sample will not crop the SDK-bound view.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  );
                }
                final nativeAd = _nativeAd;
                if (nativeAd == null) {
                  return SizedBox(
                    width: width.toDouble(),
                    height: height.toDouble(),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outlineVariant,
                        ),
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: Center(
                        child: Text(
                          '${_template.name} placeholder\n$width × $height',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  );
                }
                return Center(child: NativeAdWidget(nativeAd: nativeAd));
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _changeTemplate(NativeAdTemplate template) async {
    if (_template == template) return;
    await _clearNativeAd();
    if (!mounted) return;
    setState(() {
      _template = template;
      _status = 'Template changed. Load a new native ad.';
    });
  }

  Future<void> _changeStyle(_NativeStylePreset preset) async {
    if (_stylePreset == preset) return;
    await _clearNativeAd();
    if (!mounted) return;
    setState(() {
      _stylePreset = preset;
      _status = 'Style changed. Load a new native ad.';
    });
  }

  Future<void> _loadNativeAd() async {
    await _clearNativeAd();
    if (!mounted) return;

    final ad = NativeAd(
      adRequest: const AdRequest(adUnitId: _demoAdUnitId),
      width: _template.minimumWidth,
      height: _template.minimumHeight,
      template: _template,
      style: _style,
    );
    _loadStateSubscription = ad.loadStateStream.listen(_onLoadState);
    _eventSubscription = ad.events.listen(_onEvent);
    setState(() {
      _nativeAd = ad;
      _isLoading = true;
      _status = 'Waiting for the native SDK view, then loading the demo ad…';
    });

    try {
      await ad.load();
    } catch (error) {
      if (mounted) setState(() => _status = 'Load failed: $error');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onLoadState(NativeAdLoadState state) {
    if (!mounted) return;
    if (state is NativeAdLoadStateLoading) {
      setState(() => _status = 'Native ad request is loading…');
    } else if (state is NativeAdLoadStateLoaded) {
      setState(() => _status = 'Loaded ${state.width} × ${state.height}.');
    } else if (state is NativeAdLoadStateError) {
      setState(() => _status = 'Load failed: ${state.error.description}');
    }
  }

  void _onEvent(NativeAdEvent event) {
    if (!mounted) return;
    if (event is NativeAdClickedEvent) {
      setState(() => _status = 'Native ad clicked by the user.');
    } else if (event is NativeAdImpressionEvent) {
      setState(() => _status = 'Native ad impression recorded.');
    }
  }

  Future<void> _clearNativeAd() async {
    final ad = _nativeAd;
    _nativeAd = null;
    await _loadStateSubscription?.cancel();
    await _eventSubscription?.cancel();
    _loadStateSubscription = null;
    _eventSubscription = null;
    if (ad != null) await ad.destroy();
  }
}
