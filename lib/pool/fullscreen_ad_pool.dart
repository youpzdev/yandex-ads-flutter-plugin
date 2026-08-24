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

/// Tracks whether a full-screen ad owns the screen right now.
///
/// An app open ad must not appear on top of an interstitial, and returning
/// from an ad click must not look like a fresh app launch.
class _AdActivity {
  static int _visibleCount = 0;
  static DateTime? _endedAt;
  static int _clickCount = 0;

  static bool get isShowing => _visibleCount > 0;

  static DateTime? get lastShowEndedAt => _endedAt;

  /// How many ads of any format were clicked in this process.
  ///
  /// A counter rather than a timestamp: it needs no clock, so a comparison
  /// stays correct no matter which clock the caller uses.
  static int get clickCount => _clickCount;

  static void noteClick() => _clickCount++;

  static void begin() => _visibleCount++;

  static void end() {
    if (_visibleCount > 0) _visibleCount--;
    _endedAt = DateTime.now();
  }
}

/// Invalidates ads that were requested under a consent that no longer holds.
class _AdConsent {
  static int _generation = 0;

  static int get generation => _generation;

  static void invalidate() => _generation++;
}

/// What a pool is doing right now.
enum FullscreenAdPoolStatus {
  /// Not started yet, or stopped.
  idle,

  /// Filling an empty slot.
  loading,

  /// At least one ad is ready to show.
  ready,

  /// The last request failed and the next attempt is scheduled.
  backingOff,

  /// The retry budget is used up; nothing will be requested until [retry].
  exhausted,

  /// The pool released its resources.
  destroyed,
}

/// A snapshot of a [FullscreenAdPool].
class FullscreenAdPoolState {
  final FullscreenAdPoolStatus status;

  /// Ads ready to show.
  final int available;

  /// How many ads the pool keeps.
  final int capacity;

  /// Failures since the last successful load.
  final int consecutiveFailures;

  /// The error that caused the current back-off.
  final Object? lastError;

  const FullscreenAdPoolState({
    required this.status,
    required this.available,
    required this.capacity,
    this.consecutiveFailures = 0,
    this.lastError,
  });

  bool get isReady => available > 0;

  @override
  String toString() => 'FullscreenAdPoolState($status, $available/$capacity, '
      'failures: $consecutiveFailures)';
}

/// Why a requested show did not happen.
enum AdShowStatus {
  /// The ad was displayed and dismissed by the user.
  shown,

  /// The frequency policy blocked the show.
  blocked,

  /// No ad was ready in time.
  unavailable,

  /// Another full-screen ad owns the screen right now.
  alreadyShowing,

  /// The ad was ready but the platform refused to display it.
  failed,
}

/// The result of [FullscreenAdPool.showNext].
class AdShowOutcome {
  final AdShowStatus status;

  /// Set when the frequency policy blocked the show.
  final AdFrequencyDecision? frequency;

  /// Set when the platform refused to display a ready ad.
  final AdError? error;

  /// Set when a rewarded ad granted a reward.
  final Reward? reward;

  const AdShowOutcome._(this.status, {this.frequency, this.error, this.reward});

  bool get isShown => status == AdShowStatus.shown;

  @override
  String toString() => 'AdShowOutcome($status)';
}

typedef _PoolLoad = Future<_FullscreenAd> Function(Duration timeout);

typedef _PoolListen = Future<void> Function(
  _FullscreenAd ad,
  _PoolCallbacks callbacks,
);

class _PoolCallbacks {
  final void Function() onShown;
  final void Function(AdError error) onFailedToShow;
  final void Function() onDismissed;
  final void Function() onClicked;
  final void Function(ImpressionData data) onImpression;
  final void Function(Reward reward) onRewarded;

  const _PoolCallbacks({
    required this.onShown,
    required this.onFailedToShow,
    required this.onDismissed,
    required this.onClicked,
    required this.onImpression,
    required this.onRewarded,
  });
}

class _PoolSlot {
  final _FullscreenAd ad;
  final DateTime loadedAt;
  final int consentGeneration;

  _PoolSlot(this.ad, this.loadedAt, this.consentGeneration);
}

/// Keeps full-screen ads loaded before they are needed.
///
/// A placement that requests an ad at the moment it wants to show it makes the
/// user wait for the network, and every second of that wait is a show that
/// does not happen. The pool loads ahead of time, replaces ads that went
/// stale, spaces failed requests with [AdRetryPolicy] and can enforce an
/// [AdFrequencyPolicy] on the shows themselves.
class FullscreenAdPool<T extends Object> with WidgetsBindingObserver {
  /// Ads older than this are dropped instead of shown.
  ///
  /// This is the plugin's own ceiling, not a guarantee from the ad network:
  /// a creative that sat in memory for an hour is likely to be refused or to
  /// perform badly, so the pool replaces it.
  static const defaultTimeToLive = Duration(minutes: 45);

  final AdRequest adRequest;

  /// How many ads are kept ready.
  final int capacity;

  /// How long a loaded ad may wait before it is replaced.
  final Duration timeToLive;

  /// Deadline for a single load request.
  final Duration loadTimeout;

  /// Deadline for a single show.
  ///
  /// A native layer that dies without closing its event channel would
  /// otherwise leave the plugin believing an ad still owns the screen.
  final Duration showTimeout;

  /// How failed requests are repeated.
  final AdRetryPolicy retryPolicy;

  /// Optional pacing applied by [showNext].
  final AdFrequencyGate? frequencyGate;

  final _PoolLoad _load;
  final _PoolListen _listen;
  final Future<void> Function() _disposeLoader;
  final DateTime Function() _clock;
  final double Function() _noise;

  final _slots = <_PoolSlot>[];
  final _waiters = <Completer<void>>[];
  final _stateController = StreamController<FullscreenAdPoolState>.broadcast();

  Timer? _retryTimer;
  Timer? _expiryTimer;
  bool _showInFlight = false;
  bool _retryPending = false;
  bool _observing = false;
  bool _started = false;
  bool _destroyed = false;
  bool _filling = false;
  int _consecutiveFailures = 0;
  Object? _lastError;
  Future<void>? _destroyFuture;

  FullscreenAdPool._({
    required this.adRequest,
    required _PoolLoad load,
    required _PoolListen listen,
    required Future<void> Function() disposeLoader,
    required this.capacity,
    required this.timeToLive,
    required this.loadTimeout,
    required this.showTimeout,
    required this.retryPolicy,
    required this.frequencyGate,
    DateTime Function()? clock,
    double Function()? noise,
  })  : _load = load,
        _listen = listen,
        _disposeLoader = disposeLoader,
        _clock = clock ?? DateTime.now,
        _noise = noise ?? _defaultNoise {
    if (capacity <= 0) {
      throw ArgumentError.value(capacity, 'capacity', 'Must be positive.');
    }
    if (timeToLive <= Duration.zero) {
      throw ArgumentError.value(timeToLive, 'timeToLive', 'Must be positive.');
    }
    if (loadTimeout <= Duration.zero) {
      throw ArgumentError.value(loadTimeout, 'loadTimeout', 'Must be positive.');
    }
    if (showTimeout <= Duration.zero) {
      throw ArgumentError.value(showTimeout, 'showTimeout', 'Must be positive.');
    }
    retryPolicy.validate();
  }

  static final _random = Random();

  static double _defaultNoise() => _random.nextDouble() * 2 - 1;

  /// A pool of interstitial ads.
  static FullscreenAdPool<InterstitialAd> interstitial({
    required AdRequest adRequest,
    int capacity = 1,
    Duration timeToLive = defaultTimeToLive,
    Duration loadTimeout = const Duration(seconds: 30),
    Duration showTimeout = const Duration(minutes: 5),
    AdRetryPolicy retryPolicy = AdRetryPolicy.standard,
    AdFrequencyGate? frequencyGate,
    DateTime Function()? clock,
    double Function()? noise,
  }) {
    final loader = InterstitialAdLoader();
    return FullscreenAdPool<InterstitialAd>._(
      adRequest: adRequest,
      load: (timeout) =>
          loader.loadAd(adRequest: adRequest, timeout: timeout),
      listen: (ad, callbacks) => (ad as InterstitialAd).setAdEventListener(
        eventListener: InterstitialAdEventListener(
          onAdShown: callbacks.onShown,
          onAdFailedToShow: callbacks.onFailedToShow,
          onAdDismissed: callbacks.onDismissed,
          onAdClicked: callbacks.onClicked,
          onAdImpression: callbacks.onImpression,
        ),
      ),
      disposeLoader: loader.destroy,
      capacity: capacity,
      timeToLive: timeToLive,
      loadTimeout: loadTimeout,
      showTimeout: showTimeout,
      retryPolicy: retryPolicy,
      frequencyGate: frequencyGate,
      clock: clock,
      noise: noise,
    );
  }

  /// A pool of rewarded ads.
  static FullscreenAdPool<RewardedAd> rewarded({
    required AdRequest adRequest,
    int capacity = 1,
    Duration timeToLive = defaultTimeToLive,
    Duration loadTimeout = const Duration(seconds: 30),
    Duration showTimeout = const Duration(minutes: 5),
    AdRetryPolicy retryPolicy = AdRetryPolicy.standard,
    AdFrequencyGate? frequencyGate,
    DateTime Function()? clock,
    double Function()? noise,
  }) {
    final loader = RewardedAdLoader();
    return FullscreenAdPool<RewardedAd>._(
      adRequest: adRequest,
      load: (timeout) =>
          loader.loadAd(adRequest: adRequest, timeout: timeout),
      listen: (ad, callbacks) => (ad as RewardedAd).setAdEventListener(
        eventListener: RewardedAdEventListener(
          onAdShown: callbacks.onShown,
          onAdFailedToShow: callbacks.onFailedToShow,
          onAdDismissed: callbacks.onDismissed,
          onAdClicked: callbacks.onClicked,
          onAdImpression: callbacks.onImpression,
          onRewarded: callbacks.onRewarded,
        ),
      ),
      disposeLoader: loader.destroy,
      capacity: capacity,
      timeToLive: timeToLive,
      loadTimeout: loadTimeout,
      showTimeout: showTimeout,
      retryPolicy: retryPolicy,
      frequencyGate: frequencyGate,
      clock: clock,
      noise: noise,
    );
  }

  /// A pool of app open ads.
  static FullscreenAdPool<AppOpenAd> appOpen({
    required AdRequest adRequest,
    int capacity = 1,
    Duration timeToLive = const Duration(minutes: 30),
    Duration loadTimeout = const Duration(seconds: 20),
    Duration showTimeout = const Duration(minutes: 5),
    AdRetryPolicy retryPolicy = AdRetryPolicy.standard,
    AdFrequencyGate? frequencyGate,
    DateTime Function()? clock,
    double Function()? noise,
  }) {
    final loader = AppOpenAdLoader();
    return FullscreenAdPool<AppOpenAd>._(
      adRequest: adRequest,
      load: (timeout) =>
          loader.loadAd(adRequest: adRequest, timeout: timeout),
      listen: (ad, callbacks) => (ad as AppOpenAd).setAdEventListener(
        eventListener: AppOpenAdEventListener(
          onAdShown: callbacks.onShown,
          onAdFailedToShow: callbacks.onFailedToShow,
          onAdDismissed: callbacks.onDismissed,
          onAdClicked: callbacks.onClicked,
          onAdImpression: callbacks.onImpression,
        ),
      ),
      disposeLoader: loader.destroy,
      capacity: capacity,
      timeToLive: timeToLive,
      loadTimeout: loadTimeout,
      showTimeout: showTimeout,
      retryPolicy: retryPolicy,
      frequencyGate: frequencyGate,
      clock: clock,
      noise: noise,
    );
  }

  /// Pool state as it changes.
  Stream<FullscreenAdPoolState> get states => _stateController.stream;

  /// Current pool state.
  FullscreenAdPoolState get state {
    // Expiry is checked first so that the status cannot claim a ready ad the
    // very same snapshot reports as gone.
    final available = availableCount;
    return FullscreenAdPoolState(
      status: _status,
      available: available,
      capacity: capacity,
      consecutiveFailures: _consecutiveFailures,
      lastError: _lastError,
    );
  }

  /// Ads ready to show right now.
  int get availableCount {
    _dropExpired();
    return _slots.length;
  }

  /// Whether an ad can be shown without waiting for the network.
  bool get isReady => availableCount > 0;

  /// Whether the frequency policy would allow a show right now.
  AdFrequencyDecision get frequencyDecision =>
      frequencyGate?.evaluate() ?? const AdFrequencyDecision.allowed();

  bool get isDestroyed => _destroyed;

  FullscreenAdPoolStatus get _status {
    if (_destroyed) return FullscreenAdPoolStatus.destroyed;
    if (_slots.isNotEmpty) return FullscreenAdPoolStatus.ready;
    if (_filling) return FullscreenAdPoolStatus.loading;
    if (_retryTimer != null || _retryPending) {
      return FullscreenAdPoolStatus.backingOff;
    }
    if (!retryPolicy.allowsAttempt(_consecutiveFailures)) {
      return FullscreenAdPoolStatus.exhausted;
    }
    return _started
        ? FullscreenAdPoolStatus.loading
        : FullscreenAdPoolStatus.idle;
  }

  /// Starts requesting again after the retry budget was used up.
  Future<void> retry() async {
    _ensureAlive();
    _consecutiveFailures = 0;
    _lastError = null;
    _retryPending = false;
    await start();
    unawaited(_fill());
  }

  /// Starts keeping the pool filled.
  ///
  /// Returns as soon as the first request is on its way: waiting here would
  /// block the caller for the whole network round trip, which is exactly what
  /// preloading exists to avoid. Watch [states] or [isReady] for progress.
  Future<void> start() async {
    _ensureAlive();
    if (_started) return;
    _started = true;
    if (!_observing) {
      _observing = true;
      WidgetsBinding.instance.addObserver(this);
    }
    unawaited(_fill());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_destroyed) return;
    if (state == AppLifecycleState.resumed) {
      if (_retryPending && _retryTimer == null) {
        _retryPending = false;
        unawaited(_fill());
      }
      return;
    }
    // A backgrounded app must not keep asking for inventory it cannot show.
    if (_retryTimer != null) {
      _retryTimer!.cancel();
      _retryTimer = null;
      _retryPending = true;
      _publish();
    }
  }

  /// Takes a ready ad out of the pool.
  ///
  /// The caller owns the returned ad and must destroy it. Returns `null` when
  /// nothing is ready and [waitFor] elapsed; pass `null` to never wait.
  Future<T?> acquire({Duration? waitFor}) async {
    _ensureAlive();
    if (!_started) await start();

    var slot = _takeSlot();
    if (slot == null && waitFor != null && waitFor > Duration.zero) {
      // Ask before waiting: nothing may be in flight at all.
      unawaited(_fill());
      await _waitForSlot(waitFor);
      slot = _takeSlot();
    }
    unawaited(_fill());
    if (slot == null) return null;
    return slot.ad as T;
  }

  /// Shows the next ad, applying the frequency policy.
  ///
  /// The pool sets the event listener, shows the ad, waits for the dismissal
  /// and destroys it, so a placement cannot leak a shown ad. Callbacks are
  /// forwarded to the caller.
  Future<AdShowOutcome> showNext({
    Duration? waitFor,
    bool ignoreStartupGrace = false,
    void Function()? onAdShown,
    void Function()? onAdClicked,
    void Function(ImpressionData impressionData)? onAdImpression,
    void Function()? onAdDismissed,
    void Function(Reward reward)? onRewarded,
  }) async {
    _ensureAlive();
    // Two placements must never race into two ads in a row, and the cap has to
    // be reserved before the first await, not when the platform reports back.
    if (_showInFlight || _AdActivity.isShowing) {
      return const AdShowOutcome._(AdShowStatus.alreadyShowing);
    }
    final gate = frequencyGate;
    if (gate != null) {
      final decision = gate.evaluate(ignoreStartupGrace: ignoreStartupGrace);
      if (!decision.isAllowed) {
        return AdShowOutcome._(AdShowStatus.blocked, frequency: decision);
      }
    }

    _showInFlight = true;
    final reservation = _clock();
    gate?.recordShow(reservation);
    try {
      return await _showReserved(
        gate: gate,
        reservation: reservation,
        waitFor: waitFor,
        onAdShown: onAdShown,
        onAdClicked: onAdClicked,
        onAdImpression: onAdImpression,
        onAdDismissed: onAdDismissed,
        onRewarded: onRewarded,
      );
    } finally {
      _showInFlight = false;
    }
  }

  Future<AdShowOutcome> _showReserved({
    required AdFrequencyGate? gate,
    required DateTime reservation,
    Duration? waitFor,
    void Function()? onAdShown,
    void Function()? onAdClicked,
    void Function(ImpressionData impressionData)? onAdImpression,
    void Function()? onAdDismissed,
    void Function(Reward reward)? onRewarded,
  }) async {
    final ad = await acquire(waitFor: waitFor);
    if (ad == null) {
      gate?._undoShow(reservation);
      return const AdShowOutcome._(AdShowStatus.unavailable);
    }

    final fullscreen = ad as _FullscreenAd;
    Reward? reward;
    AdError? failure;

    try {
      await _listen(
      fullscreen,
      _PoolCallbacks(
        onShown: () => onAdShown?.call(),
        onFailedToShow: (error) => failure ??= error,
        onDismissed: () => onAdDismissed?.call(),
        onClicked: () => onAdClicked?.call(),
          onImpression: (data) => onAdImpression?.call(data),
          onRewarded: (value) {
            reward = value;
            onRewarded?.call(value);
          },
        ),
      );

      _AdActivity.begin();
      await fullscreen.show();
      final dismissed = await fullscreen.waitForDismiss().timeout(
            showTimeout,
            onTimeout: () => null,
          );
      if (dismissed is Reward) reward = dismissed;
    } on AdError catch (error) {
      failure ??= error;
    } on PlatformException catch (error) {
      failure ??= AdError(error.message ?? error.code);
    } catch (error) {
      failure ??= AdError(error.toString());
    } finally {
      _AdActivity.end();
      // Releasing a shown ad must never replace its outcome with an error.
      try {
        await fullscreen.destroy();
      } catch (_) {}
      unawaited(_fill());
    }

    final error = failure;
    if (error != null) {
      gate?._undoShow(reservation);
      return AdShowOutcome._(AdShowStatus.failed, error: error);
    }
    return AdShowOutcome._(AdShowStatus.shown, reward: reward);
  }

  /// Releases every held ad and stops loading.
  Future<void> destroy() => _destroyFuture ??= _destroy();

  Future<void> _destroy() async {
    if (_destroyed) return;
    _destroyed = true;
    if (_observing) {
      _observing = false;
      WidgetsBinding.instance.removeObserver(this);
    }
    _retryTimer?.cancel();
    _expiryTimer?.cancel();
    _retryTimer = null;
    _expiryTimer = null;
    for (final waiter in _waiters) {
      if (!waiter.isCompleted) waiter.complete();
    }
    _waiters.clear();
    final slots = List<_PoolSlot>.from(_slots);
    _slots.clear();
    for (final slot in slots) {
      try {
        await slot.ad.destroy();
      } catch (_) {}
    }
    try {
      await _disposeLoader();
    } catch (_) {}
    _publish();
    await _stateController.close();
  }

  void _ensureAlive() {
    if (_destroyed) {
      throw StateError('Ad pool is destroyed and cannot be used anymore.');
    }
  }

  _PoolSlot? _takeSlot() {
    _dropExpired();
    if (_slots.isEmpty) return null;
    final slot = _slots.removeAt(0);
    _publish();
    return slot;
  }

  /// Waits until a slot is free, or [timeout] elapses.
  ///
  /// A single load wakes every waiter, so a waiter that lost the race keeps
  /// waiting for the rest of its own deadline instead of giving up early.
  Future<void> _waitForSlot(Duration timeout) async {
    final elapsed = Stopwatch()..start();
    while (!_destroyed) {
      _dropExpired();
      if (_slots.isNotEmpty) return;
      final remaining = timeout - elapsed.elapsed;
      if (remaining <= Duration.zero) return;
      await _waitOnce(remaining);
    }
  }

  Future<void> _waitOnce(Duration timeout) async {
    final waiter = Completer<void>();
    _waiters.add(waiter);
    final timer = Timer(timeout, () {
      if (!waiter.isCompleted) waiter.complete();
    });
    try {
      await waiter.future;
    } finally {
      timer.cancel();
      _waiters.remove(waiter);
    }
  }

  void _releaseWaiters() {
    final waiters = List<Completer<void>>.from(_waiters);
    _waiters.clear();
    for (final waiter in waiters) {
      if (!waiter.isCompleted) waiter.complete();
    }
  }

  Future<void> _fill() async {
    if (_destroyed || !_started || _filling) return;
    if (_retryTimer != null || _retryPending) return;
    if (!retryPolicy.allowsAttempt(_consecutiveFailures)) return;
    _dropExpired();
    if (_slots.length >= capacity) {
      _scheduleExpiry();
      return;
    }

    _filling = true;
    _publish();
    try {
      while (!_destroyed && _slots.length < capacity) {
        try {
          final ad = await _load(loadTimeout);
          if (_destroyed) {
            await ad.destroy();
            return;
          }
          _slots.add(_PoolSlot(ad, _clock(), _AdConsent.generation));
          _consecutiveFailures = 0;
          _lastError = null;
          _releaseWaiters();
          _publish();
        } catch (error) {
          if (_destroyed) return;
          _consecutiveFailures++;
          _lastError = error;
          _scheduleRetry();
          return;
        }
      }
    } finally {
      _filling = false;
      if (!_destroyed) {
        _scheduleExpiry();
        _publish();
      }
    }
  }

  void _scheduleRetry() {
    if (_destroyed) return;
    if (!retryPolicy.allowsAttempt(_consecutiveFailures)) {
      _publish();
      return;
    }
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    if (_observing &&
        lifecycle != null &&
        lifecycle != AppLifecycleState.resumed) {
      // Retry when the user is back: inventory cannot be shown in background.
      _retryPending = true;
      _publish();
      return;
    }
    _retryTimer?.cancel();
    final delay = retryPolicy.delayAfter(
      _consecutiveFailures,
      noise: _noise(),
    );
    _retryTimer = Timer(delay, () {
      _retryTimer = null;
      unawaited(_fill());
    });
    _publish();
  }

  void _scheduleExpiry() {
    _expiryTimer?.cancel();
    if (_destroyed || _slots.isEmpty) return;
    final oldest = _slots.first.loadedAt;
    final remaining = oldest.add(timeToLive).difference(_clock());
    _expiryTimer = Timer(
      remaining > Duration.zero ? remaining : Duration.zero,
      () {
        _expiryTimer = null;
        if (_destroyed) return;
        _dropExpired();
        _publish();
        unawaited(_fill());
      },
    );
  }

  void _dropExpired() {
    if (_slots.isEmpty) return;
    final now = _clock();
    final consent = _AdConsent.generation;
    final expired = <_PoolSlot>[];
    _slots.removeWhere((slot) {
      // An ad requested under a consent the user has since changed must not
      // be shown, however fresh it is.
      final isExpired = now.difference(slot.loadedAt) >= timeToLive ||
          slot.consentGeneration != consent;
      if (isExpired) expired.add(slot);
      return isExpired;
    });
    for (final slot in expired) {
      unawaited(slot.ad.destroy().catchError((Object _) {}));
    }
  }

  void _publish() {
    if (_stateController.isClosed) return;
    _stateController.add(state);
  }
}
