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

class NativeAd with _Ad {
  static const _channelPath = 'yandex_mobileads.nativeAd';
  static var _idCount = 0;

  final AdRequest adRequest;
  final NativeAdTemplate template;
  final NativeAdStyle style;
  final int width;
  final int height;
  final Duration loadTimeout;
  final int _id = _idCount++;

  final _loadStateController = StreamController<NativeAdLoadState>.broadcast();
  final _eventsController = StreamController<NativeAdEvent>.broadcast();
  final _loadedCompleter = Completer<void>();
  final _platformViewReady = Completer<void>();

  late final Widget _widget;
  StreamSubscription<dynamic>? _eventSubscription;
  Timer? _loadTimer;
  bool _platformViewCreated = false;
  bool _loadStarted = false;
  bool _loadFinished = false;
  bool _nativeLoadInvoked = false;
  bool _loadSucceeded = false;
  bool _cancelWhenPlatformViewReady = false;
  Map<String, dynamic>? _nativeLoadArguments;
  Future<void>? _nativeDestroyFuture;

  NativeAd({
    required this.adRequest,
    required this.width,
    required this.height,
    this.template = NativeAdTemplate.media,
    this.style = const NativeAdStyle(),
    this.loadTimeout = const Duration(seconds: 30),
  }) {
    if (width <= 0) throw ArgumentError.value(width, 'width');
    if (height <= 0) throw ArgumentError.value(height, 'height');
    if (loadTimeout <= Duration.zero) {
      throw ArgumentError.value(loadTimeout, 'loadTimeout');
    }
    template.validateSize(
      width: width,
      height: height,
      contentPadding: style.contentPadding,
    );
    unawaited(_loadedCompleter.future.catchError((Object _) {}));
    _widget = _PlatformInterface.instance.buildNativeAd(
      id: _id,
      width: width,
      height: height,
      template: template,
      style: style,
      onPlatformViewCreated: (_) {
        if (isDestroyed) {
          unawaited(_destroyLateView());
          return;
        }
        final recreated = _platformViewCreated;
        _platformViewCreated = true;
        _listenToEvents();
        if (!_platformViewReady.isCompleted) {
          _platformViewReady.complete();
        }
        if (_cancelWhenPlatformViewReady) {
          unawaited(_cancelNativeLoad());
          return;
        }
        if (recreated && _nativeLoadInvoked && !_loadFinished) {
          unawaited(_resendNativeLoad());
        }
      },
    );
  }

  @override
  String get methodChannelName => '$_channelPath.$_id';

  Stream<NativeAdLoadState> get loadStateStream => _loadStateController.stream;

  Stream<NativeAdEvent> get events => _eventsController.stream;

  Future<void> get loaded => _loadedCompleter.future;

  Future<void> load() async {
    ensureAlive();
    if (_loadStarted) {
      throw StateError('Native ad load has already been requested.');
    }
    _loadStarted = true;
    _loadTimer = Timer(loadTimeout, () => unawaited(_cancelTimedOutLoad()));
    try {
      await Future.any<void>([
        _platformViewReady.future,
        _loadedCompleter.future,
      ]);
      if (_loadFinished) {
        await _loadedCompleter.future;
        return;
      }
      ensureAlive();
      await (YandexAds._initFuture ?? Future<void>.value());
      if (_loadFinished) {
        await _loadedCompleter.future;
        return;
      }
      _loadStateController.add(NativeAdLoadStateLoading());
      final map = adRequest._toMap();
      map['adUnitId'] = adRequest.adUnitId;
      map['parameters'] = {
        'plugin_type': 'flutter',
        'plugin_version': YandexAds.pluginVersion,
      }..addAll(adRequest.parameters ?? {});
      _nativeLoadArguments = map;
      _nativeLoadInvoked = true;
      await _channel.invokeMethod<void>('load', map);
      await _loadedCompleter.future;
    } catch (error, stackTrace) {
      _completeLoadError(error, stackTrace);
      rethrow;
    }
  }

  /// Repeats the request when the platform view is recreated mid-load.
  ///
  /// A recreated view is a fresh native instance: the interrupted request
  /// belonged to the previous one and would never report back.
  Future<void> _resendNativeLoad() async {
    final arguments = _nativeLoadArguments;
    if (arguments == null || isDestroyed || _loadFinished) return;
    try {
      await _channel.invokeMethod<void>('load', arguments);
    } catch (error, stackTrace) {
      _completeLoadError(error, stackTrace);
    }
  }

  void _listenToEvents() {
    final previous = _eventSubscription;
    if (previous != null) {
      unawaited(previous.cancel());
    }
    _eventSubscription = EventChannel('$methodChannelName.events')
        .receiveBroadcastStream()
        .listen(
      (event) {
        final map = Map<dynamic, dynamic>.from(event as Map);
        switch (map['name']) {
          case 'onAdLoaded':
            if (_loadFinished && !_loadSucceeded) return;
            _loadTimer?.cancel();
            if (!_loadStateController.isClosed) {
              _loadStateController.add(
                NativeAdLoadStateLoaded(
                  width: (map['width'] as num?)?.toInt() ?? width,
                  height: (map['height'] as num?)?.toInt() ?? height,
                ),
              );
            }
            _completeLoadSuccess();
            break;
          case 'onAdFailedToLoad':
            if (_loadFinished) return;
            _loadTimer?.cancel();
            final error = AdRequestError(
              (map['code'] as num?)?.toInt() ?? -1,
              map['description'] as String? ?? 'Native ad failed to load.',
              map['adUnitId'] as String?,
            );
            _completeLoadError(error);
            break;
          case 'onAdClicked':
            _eventsController.add(NativeAdClickedEvent());
            break;
          case 'onImpression':
            _eventsController.add(
              NativeAdImpressionEvent(
                impressionData: _SimpleImpressionData(
                  rawData: map['impressionData'] as String? ?? '',
                ),
              ),
            );
            break;
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        _completeLoadError(error, stackTrace);
      },
    );
  }

  void _completeLoadSuccess() {
    if (_loadFinished) return;
    _loadFinished = true;
    _loadSucceeded = true;
    _loadTimer?.cancel();
    if (!_loadedCompleter.isCompleted) {
      _loadedCompleter.complete();
    }
  }

  void _completeLoadError(Object error, [StackTrace? stackTrace]) {
    if (!_markLoadFinished()) return;
    _publishLoadError(error, stackTrace);
  }

  Future<void> _cancelTimedOutLoad() async {
    if (!_markLoadFinished()) return;
    if (_nativeLoadInvoked) {
      await _cancelNativeLoad();
    } else if (!_platformViewCreated) {
      _cancelWhenPlatformViewReady = true;
    }
    _publishLoadError(
        TimeoutException('Native ad load timed out.', loadTimeout));
  }

  Future<void> _destroyLateView() async {
    try {
      await _channel.invokeMethod<void>('destroy');
    } catch (_) {}
  }

  Future<void> _cancelNativeLoad() async {
    try {
      await _channel.invokeMethod<void>('cancelLoading');
    } catch (_) {}
  }

  bool _markLoadFinished() {
    if (_loadFinished) return false;
    _loadFinished = true;
    _loadTimer?.cancel();
    return true;
  }

  void _publishLoadError(Object error, [StackTrace? stackTrace]) {
    if (!_loadStateController.isClosed) {
      _loadStateController.add(
        NativeAdLoadStateError(
          error: error is AdRequestError
              ? error
              : AdRequestError(-1, error.toString(), adRequest.adUnitId),
        ),
      );
    }
    if (!_loadedCompleter.isCompleted) {
      _loadedCompleter.completeError(error, stackTrace);
    }
  }

  @override
  Future<void> destroy() {
    return _nativeDestroyFuture ??= _destroyNativeAd();
  }

  Future<void> _destroyNativeAd() async {
    _loadTimer?.cancel();
    await _eventSubscription?.cancel();
    if (!_platformViewReady.isCompleted && _loadStarted) {
      _platformViewReady.completeError(
        StateError(
            'Native ad was destroyed before its platform view was ready.'),
      );
    }
    try {
      if (_platformViewCreated) {
        try {
          await super.destroy();
        } on MissingPluginException {
          // The platform view was already disposed and released its channel.
        }
      } else {
        _destroyed = true;
        _finalizer.detach(this);
      }
    } finally {
      _completeLoadError(StateError('Native ad was destroyed.'));
      await _loadStateController.close();
      await _eventsController.close();
    }
  }
}

class NativeAdWidget extends StatelessWidget {
  final NativeAd nativeAd;

  const NativeAdWidget({super.key, required this.nativeAd});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: ValueKey(nativeAd._id),
      width: nativeAd.width.toDouble(),
      height: nativeAd.height.toDouble(),
      child: nativeAd._widget,
    );
  }
}
