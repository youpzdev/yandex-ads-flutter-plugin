/*
 * This file is a part of the Yandex Advertising Network
 *
 * Version for Flutter (C) 2023 YANDEX
 *
 * You may not use this file except in compliance with the License.
 * You may obtain a copy of the License at https://legal.yandex.com/partner_ch/
 */

part of 'mobile_ads.dart';

abstract class _FullscreenAdLoader {
  static const _pluginType = 'plugin_type';
  static const _pluginVersion = 'plugin_version';
  static const _flutter = 'flutter';

  static const _createChannel = MethodChannel(
    'yandex_mobileads.createAdLoader',
  );

  static var _nextId = 0;

  late final int _id;
  late final MethodChannel _channel;
  Future<void>? _initialization;
  StreamSubscription? _eventSubscription;
  bool _destroyed = false;
  Future<void>? _destroyFuture;

  int _nextRequestId = 0;
  final _pendingLoads = <int, Completer<Map<String, dynamic>>>{};
  _PendingFullscreenLoad? _activeLoad;

  late final AdFormat _format;

  void _init(String loaderType, String channelPath, AdFormat format) {
    _format = format;
    _id = _nextId++;
    final name = 'yandex_mobileads.$channelPath.$_id';
    _channel = MethodChannel(name);
    _finalizer.attach(this, _channel, detach: this);

    _loaderType = loaderType;
  }

  late final String _loaderType;

  Future<void> _ensureInitialized() async {
    final active = _initialization;
    if (active != null) {
      await active;
      return;
    }

    final initialization = _initialize();
    _initialization = initialization;
    try {
      await initialization;
    } catch (_) {
      if (identical(_initialization, initialization)) {
        _initialization = null;
      }
      rethrow;
    }
  }

  Future<void> _initialize() async {
    await _createChannel.invokeMethod<void>(_loaderType, {'id': _id});
    final eventChannel = EventChannel('${_channel.name}.events');
    _eventSubscription = eventChannel.receiveBroadcastStream().listen(
          (event) => _dispatchEvent(Map<String, dynamic>.from(event as Map)),
          onError: _completePendingWithError,
          onDone: () => _completePendingWithError(
            StateError('Ad loader event stream closed before completion.'),
          ),
        );
  }

  void _dispatchEvent(Map<String, dynamic> result) {
    final name = result['name'];
    final requestId = result['requestId'] as int?;
    final completer =
        requestId == null ? null : _pendingLoads.remove(requestId);

    if (name == _FullScreenAdCallbackName.onAdLoaded.name) {
      if (completer == null) {
        unawaited(_discardOrphanAd(result['id'] as int?));
        return;
      }
      _AdEventBus.emit(
        type: AdEventType.loaded,
        format: _format,
        adUnitId: result['adUnitId'] as String?,
      );
    } else if (name == _FullScreenAdCallbackName.onAdFailedToLoad.name &&
        completer != null) {
      _AdEventBus.emit(
        type: AdEventType.failedToLoad,
        format: _format,
        adUnitId: result['adUnitId'] as String?,
        error: AdRequestError(
          result['code'] as int? ?? -1,
          result['description'] as String? ?? 'Ad failed to load.',
          result['adUnitId'] as String?,
        ),
      );
    }
    completer?.complete(result);
  }

  String get _adChannelPath {
    switch (_format) {
      case AdFormat.interstitial:
        return InterstitialAd._channelPath;
      case AdFormat.rewarded:
        return RewardedAd._channelPath;
      case AdFormat.appOpen:
        return AppOpenAd._channelPath;
      case AdFormat.banner:
      case AdFormat.native:
        return '';
    }
  }

  Future<void> _discardOrphanAd(int? id) async {
    if (id == null) return;
    final path = _adChannelPath;
    if (path.isEmpty) return;
    try {
      await MethodChannel('$path.$id').invokeMethod<void>('destroy');
    } catch (_) {}
  }

  /// Loads an ad with the given [AdRequest].
  Future<Map<String, dynamic>> _invokeLoad(
    AdRequest adRequest, {
    required Duration timeout,
  }) async {
    if (_destroyed) {
      throw StateError('Ad loader is destroyed and cannot be used anymore.');
    }
    if (_activeLoad != null) {
      throw StateError('Another ad load is already in progress.');
    }
    final pending = _PendingFullscreenLoad();
    _activeLoad = pending;
    final timeoutTimer = Timer(
      timeout,
      () => unawaited(_completeTimedOutLoad(pending, timeout)),
    );

    try {
      final initialization = (YandexAds._initFuture ?? Future<void>.value())
          .then((_) => _ensureInitialized());
      await Future.any<void>([
        initialization,
        pending.completer.future.then<void>((_) {}),
      ]);
      if (_destroyed) {
        throw StateError('Ad loader is destroyed and cannot be used anymore.');
      }
      if (pending.cancelled) {
        return await pending.completer.future;
      }

      final requestId = _nextRequestId++;
      pending.requestId = requestId;
      _pendingLoads[requestId] = pending.completer;
      final map = adRequest._toMap();
      map['requestId'] = requestId;
      map['parameters'] = {
        _pluginType: _flutter,
        _pluginVersion: YandexAds.pluginVersion,
      }..addAll(adRequest.parameters ?? {});

      pending.nativeLoadStarted = true;
      final requestedConsent = _AdConsent.generation;
      await Future.any<void>([
        _channel.invokeMethod<void>('load', map),
        pending.completer.future.then<void>((_) {}),
      ]);
      final result = await pending.completer.future;
      if (requestedConsent != _AdConsent.generation &&
          result['name'] == _FullScreenAdCallbackName.onAdLoaded.name) {
        unawaited(_discardOrphanAd(result['id'] as int?));
        throw StateError(
          'Consent, age or location settings changed while the ad was '
          'loading. Load a new ad.',
        );
      }
      return result;
    } finally {
      timeoutTimer.cancel();
      final requestId = pending.requestId;
      if (requestId != null) {
        _pendingLoads.remove(requestId);
      }
      if (identical(_activeLoad, pending)) {
        _activeLoad = null;
      }
    }
  }

  Future<void> _cancelNativeLoad(_PendingFullscreenLoad pending) async {
    if (!pending.nativeLoadStarted || _destroyed) return;
    try {
      await _channel.invokeMethod<void>('cancelLoading');
    } catch (_) {
      if (!pending.completer.isCompleted) {
        rethrow;
      }
    }
  }

  Future<void> _completeTimedOutLoad(
    _PendingFullscreenLoad pending,
    Duration timeout,
  ) async {
    if (pending.completer.isCompleted) return;
    pending.cancelled = true;
    try {
      await _cancelNativeLoad(pending);
    } catch (_) {}
    if (!pending.completer.isCompleted) {
      pending.completer.completeError(
        TimeoutException('Ad load timed out.', timeout),
      );
    }
  }

  Future<void> cancelLoading() async {
    if (_destroyed) return;
    final pending = _activeLoad;
    if (pending == null) return;
    pending.cancelled = true;
    await _cancelNativeLoad(pending);
    if (!pending.completer.isCompleted) {
      pending.completer.completeError(
        StateError('Ad loading was cancelled.'),
        StackTrace.current,
      );
    }
  }

  Future<void> destroy() {
    return _destroyFuture ??= _destroy();
  }

  Future<void> _destroy() async {
    if (_destroyed) return;
    _destroyed = true;
    _finalizer.detach(this);
    _completePendingWithError(
      StateError('Ad loader was destroyed.'),
      StackTrace.current,
    );
    final initialization = _initialization;
    if (initialization == null) {
      return;
    }
    try {
      await initialization;
    } catch (_) {
      return;
    }
    await _eventSubscription?.cancel();
    try {
      await _channel.invokeMethod<void>('destroy');
    } on MissingPluginException {
      _finalizer.detach(this);
    }
  }

  void _completePendingWithError(Object error, [StackTrace? stackTrace]) {
    final pending = _pendingLoads.values.toSet();
    final active = _activeLoad;
    if (active != null) {
      pending.add(active.completer);
    }
    _pendingLoads.clear();
    for (final completer in pending) {
      if (!completer.isCompleted) {
        completer.completeError(error, stackTrace ?? StackTrace.current);
      }
    }
  }
}

class _PendingFullscreenLoad {
  final Completer<Map<String, dynamic>> completer = Completer();
  int? requestId;
  bool nativeLoadStarted = false;
  bool cancelled = false;
}
