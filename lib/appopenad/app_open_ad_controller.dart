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

part of '../mobile_ads.dart';

/// Shows an app open ad when the user comes back to the app.
///
/// The controller keeps an ad preloaded, so the return is not spent waiting
/// for the network, and it refuses to show in the cases that make users
/// uninstall: right after a permission dialog, on top of another full-screen
/// ad, and when the user only left to follow an ad click.
class AppOpenAdController with WidgetsBindingObserver {
  /// Ad request used for every app open ad.
  final AdRequest adRequest;

  /// How long the app must stay in the background before a return counts.
  ///
  /// Shorter absences are usually system dialogs — a permission prompt, the
  /// share sheet, a photo picker — and an ad on top of those is a bug, not
  /// revenue.
  final Duration minimumBackgroundDuration;

  /// How long a return may wait for an ad that is still loading.
  final Duration waitForAd;

  /// Whether the first app start shows an ad as well.
  final bool showOnColdStart;

  final FullscreenAdPool<AppOpenAd> _pool;
  final DateTime Function() _clock;
  final _shows = StreamController<AdShowOutcome>.broadcast();

  DateTime? _backgroundedAt;
  int _clicksAtResume = 0;
  bool _suppressNextResume = false;
  bool _started = false;
  bool _destroyed = false;
  bool _showing = false;
  Future<void>? _destroyFuture;

  AppOpenAdController({
    required this.adRequest,
    AdFrequencyPolicy frequencyPolicy = AdFrequencyPolicy.conservative,
    AdRetryPolicy retryPolicy = AdRetryPolicy.standard,
    Duration timeToLive = const Duration(minutes: 30),
    Duration loadTimeout = const Duration(seconds: 20),
    this.minimumBackgroundDuration = const Duration(seconds: 15),
    this.waitForAd = const Duration(seconds: 3),
    this.showOnColdStart = true,
    AdFrequencyGate? frequencyGate,
    DateTime Function()? clock,
  })  : _clock = clock ?? DateTime.now,
        _pool = FullscreenAdPool.appOpen(
          adRequest: adRequest,
          timeToLive: timeToLive,
          loadTimeout: loadTimeout,
          retryPolicy: retryPolicy,
          frequencyGate: frequencyGate ??
              AdFrequencyGate(policy: frequencyPolicy, clock: clock),
          clock: clock,
        ) {
    if (minimumBackgroundDuration < Duration.zero) {
      throw ArgumentError.value(
        minimumBackgroundDuration,
        'minimumBackgroundDuration',
        'Must not be negative.',
      );
    }
  }

  /// Outcome of every show this controller attempted.
  ///
  /// Blocked and unavailable attempts are reported too: they are the numbers
  /// that explain a placement that earns less than it should.
  Stream<AdShowOutcome> get shows => _shows.stream;

  /// The preloading pool, exposed for state and metrics.
  FullscreenAdPool<AppOpenAd> get pool => _pool;

  /// Pacing state shared by every show this controller makes.
  AdFrequencyGate get frequencyGate => _pool.frequencyGate!;

  bool get isDestroyed => _destroyed;

  /// Starts preloading and watching the application lifecycle.
  Future<void> start() async {
    if (_destroyed) {
      throw StateError('App open ad controller is destroyed.');
    }
    if (_started) return;
    _started = true;
    _clicksAtResume = _AdActivity.clickCount;
    WidgetsBinding.instance.addObserver(this);
    await _pool.start();
    if (showOnColdStart) {
      // The launch show is the point of a cold start ad, so it is the one
      // show allowed to skip the startup grace. It is not awaited: start()
      // must not block the caller for the length of an ad. Watch [shows] for
      // the outcome, and call start() only after the user's consent answer is
      // known.
      unawaited(showIfAllowed(waitFor: waitForAd, ignoreStartupGrace: true));
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_destroyed) return;
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        _backgroundedAt = _clock();
        // Leaving after an ad was clicked, or while one owns the screen, means
        // the user followed the ad rather than ended the session.
        _suppressNextResume = _AdActivity.isShowing ||
            _showing ||
            _AdActivity.clickCount != _clicksAtResume;
        break;
      case AppLifecycleState.resumed:
        unawaited(_handleResume());
        break;
      case AppLifecycleState.inactive:
        break;
    }
  }

  Future<void> _handleResume() async {
    if (_destroyed) return;
    final leftAt = _backgroundedAt;
    _backgroundedAt = null;
    _clicksAtResume = _AdActivity.clickCount;
    if (_suppressNextResume) {
      _suppressNextResume = false;
      return;
    }
    if (leftAt == null) return;
    final now = _clock();
    if (now.difference(leftAt) < minimumBackgroundDuration) return;
    final adEndedAt = _AdActivity.lastShowEndedAt;
    if (adEndedAt != null &&
        now.difference(adEndedAt) < const Duration(seconds: 2)) {
      return;
    }
    await showIfAllowed(waitFor: waitForAd);
  }

  /// Shows an app open ad when the policy and the pool allow it.
  Future<AdShowOutcome> showIfAllowed({
    Duration? waitFor,
    bool ignoreStartupGrace = false,
  }) async {
    if (_destroyed) {
      throw StateError('App open ad controller is destroyed.');
    }
    if (_showing) {
      const outcome = AdShowOutcome._(AdShowStatus.alreadyShowing);
      _publish(outcome);
      return outcome;
    }

    _showing = true;
    try {
      final outcome = await _pool.showNext(
        waitFor: waitFor ?? waitForAd,
        ignoreStartupGrace: ignoreStartupGrace,
      );
      _publish(outcome);
      return outcome;
    } finally {
      _showing = false;
    }
  }

  /// Stops watching the lifecycle and releases the preloaded ad.
  Future<void> destroy() => _destroyFuture ??= _destroy();

  Future<void> _destroy() async {
    if (_destroyed) return;
    _destroyed = true;
    if (_started) {
      WidgetsBinding.instance.removeObserver(this);
    }
    await _pool.destroy();
    await _shows.close();
  }

  void _publish(AdShowOutcome outcome) {
    if (!_shows.isClosed) _shows.add(outcome);
  }
}
