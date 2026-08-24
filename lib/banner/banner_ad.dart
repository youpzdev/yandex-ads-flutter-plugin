/*
 * This file is a part of the Yandex Advertising Network
 *
 * Version for Flutter (C) 2023 YANDEX
 *
 * You may not use this file except in compliance with the License.
 * You may obtain a copy of the License at https://legal.yandex.com/partner_ch/
 */

part of '../mobile_ads.dart';

/// This class is responsible for loading and displaying a banner ad.
///
/// Create a [BannerAd] with the desired [BannerAdSize], then call [load]
/// to request an ad. Observe [loadStateStream] and [events] to react to
/// state changes and user interactions. Pass the instance to an [AdWidget]
/// to render it.
class BannerAd with _Ad {
  static const _channelPath = 'yandex_mobileads.bannerAd';
  static var _idCount = 0;

  static const _adUnitIdKey = 'adUnitId';
  static const _pluginType = 'plugin_type';
  static const _pluginVersion = 'plugin_version';
  static const _flutter = 'flutter';

  final BannerAdSize adSize;
  final int _id = _idCount++;

  @override
  String get methodChannelName => '$_channelPath.$_id';

  Widget? _widget;
  bool _isPlatformViewCreated = false;
  Future<void>? _bannerDestroyFuture;
  Future<void>? _loadFuture;
  final _platformViewCreated = Completer<void>();

  final _loadStateController = StreamController<BannerAdLoadState>.broadcast();
  final _eventsController = StreamController<BannerAdEvent>.broadcast();

  BannerAdLoadState _loadState = BannerAdLoadStateInitial();

  /// The current load state of the ad.
  BannerAdLoadState get loadState => _loadState;

  /// A broadcast stream of load state changes.
  Stream<BannerAdLoadState> get loadStateStream => _loadStateController.stream;

  /// A broadcast stream of ad events (clicks, impressions).
  Stream<BannerAdEvent> get events => _eventsController.stream;

  late final _BannerAdEventListener _eventListener;
  late final StreamSubscription<BannerAdLoadState> _loadStateSubscription;

  BannerAd({required this.adSize}) {
    _eventListener = _BannerAdEventListener(
      channelName: '$_channelPath.$_id.events',
      loadStateController: _loadStateController,
      eventsController: _eventsController,
    );

    _loadStateSubscription = _loadStateController.stream.listen((state) {
      _loadState = state;
    });
    unawaited(_platformViewCreated.future.catchError((Object _) {}));
  }

  /// Loads an ad with the given [adRequest].
  ///
  /// Can be called multiple times to reload. Emits [BannerAdLoadStateLoading]
  /// immediately, then [BannerAdLoadStateLoaded] or [BannerAdLoadStateError]
  /// when the native side responds.
  ///
  /// The returned future completes once the native side has accepted the
  /// request, which requires the matching [AdWidget] to be in the widget tree.
  /// If the widget never appears, the load fails with a [TimeoutException]
  /// after [timeout] instead of waiting forever.
  Future<void> load(
    AdRequest adRequest, {
    Duration timeout = const Duration(seconds: 30),
  }) async {
    ensureAlive();
    if (timeout <= Duration.zero) {
      throw ArgumentError.value(timeout, 'timeout', 'Must be positive.');
    }
    if (_loadFuture != null) {
      throw StateError('Another banner ad load is already in progress.');
    }

    late final Future<void> load;
    load = _load(adRequest, timeout);
    _loadFuture = load;
    try {
      await load;
    } finally {
      if (identical(_loadFuture, load)) {
        _loadFuture = null;
      }
    }
  }

  Future<void> _load(AdRequest adRequest, Duration timeout) async {
    await (YandexAds._initFuture ?? Future<void>.value());
    ensureAlive();

    _loadState = BannerAdLoadStateLoading();
    _loadStateController.add(_loadState);

    if (!_isPlatformViewCreated) {
      _widget = _PlatformInterface.instance.buildBannerAd(
        adSize: adSize,
        id: _id,
        onPlatformViewCreated: (_) {
          if (isDestroyed) return;
          _isPlatformViewCreated = true;
          _eventListener.setupCallbacks();
          if (!_platformViewCreated.isCompleted) {
            _platformViewCreated.complete();
          }
        },
      );
    }
    await _platformViewCreated.future.timeout(
      timeout,
      onTimeout: () {
        final error = AdRequestError(
          -1,
          'Banner ad load timed out before its widget was displayed.',
          adRequest.adUnitId,
        );
        if (!_loadStateController.isClosed) {
          _loadStateController.add(BannerAdLoadStateError(error: error));
        }
        throw TimeoutException(
          'Banner ad load timed out before its widget was displayed.',
          timeout,
        );
      },
    );
    ensureAlive();
    await _invokeLoad(adRequest);
  }

  Future<void> _invokeLoad(AdRequest adRequest) async {
    _eventListener.adUnitId = adRequest.adUnitId;
    final map = adRequest._toMap();
    map[_adUnitIdKey] = adRequest.adUnitId;
    map['parameters'] = {
      _pluginType: _flutter,
      _pluginVersion: YandexAds.pluginVersion,
    }..addAll(adRequest.parameters ?? {});
    try {
      await _channel.invokeMethod<void>('load', map);
    } on PlatformException catch (error) {
      if (!_loadStateController.isClosed) {
        _loadStateController.add(
          BannerAdLoadStateError(
            error: AdRequestError(
              -1,
              error.message ?? error.code,
              adRequest.adUnitId,
            ),
          ),
        );
      }
      rethrow;
    }
  }

  @override
  Future<void> destroy() {
    return _bannerDestroyFuture ??= _destroyBanner();
  }

  Future<void> _destroyBanner() async {
    if (!_platformViewCreated.isCompleted && _loadFuture != null) {
      _platformViewCreated.completeError(
        StateError(
            'Banner ad was destroyed before its platform view was ready.'),
      );
    }
    try {
      if (_isPlatformViewCreated) {
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
      await _eventListener.dispose();
      await _loadStateSubscription.cancel();
      await _loadStateController.close();
      await _eventsController.close();
    }
  }
}

/// A widget that displays a [BannerAd].
///
/// The widget automatically resizes when the ad loads.
class AdWidget extends StatefulWidget {
  final BannerAd bannerAd;

  const AdWidget({super.key, required this.bannerAd});

  @override
  State<AdWidget> createState() => _AdWidgetState();
}

class _AdWidgetState extends State<AdWidget> {
  late int _width;
  late int _height;
  StreamSubscription<BannerAdLoadState>? _subscription;

  @override
  void initState() {
    super.initState();
    _resetLayoutForBanner();
    _listenToLoadState();
  }

  @override
  void didUpdateWidget(AdWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.bannerAd, widget.bannerAd)) {
      _subscription?.cancel();
      _resetLayoutForBanner();
      _listenToLoadState();
    }
  }

  void _resetLayoutForBanner() {
    _width = widget.bannerAd.adSize.width;
    _height = BannerAdSize._initialHeight;
    _applyCurrentState(widget.bannerAd.loadState);
  }

  void _listenToLoadState() {
    _subscription = widget.bannerAd.loadStateStream.listen((state) {
      if (!mounted) return;
      // Every state can be the first one that has a platform view to show.
      setState(() {
        if (state is BannerAdLoadStateLoaded) {
          _width = state.width;
          _height = state.height;
        }
      });
    });
  }

  void _applyCurrentState(BannerAdLoadState state) {
    if (state is BannerAdLoadStateLoaded) {
      _width = state.width;
      _height = state.height;
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: ValueKey(widget.bannerAd._id),
      width: _width.toDouble(),
      height: _height.toDouble(),
      child: widget.bannerAd._widget,
    );
  }
}
