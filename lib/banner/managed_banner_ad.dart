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

class ManagedBannerRefreshPolicy {
  static const minimumInterval = Duration(seconds: 30);

  static const conservative = ManagedBannerRefreshPolicy(
    refreshInterval: Duration(seconds: 120),
    retryInterval: Duration(seconds: 30),
  );

  static const standard = ManagedBannerRefreshPolicy(
    refreshInterval: Duration(seconds: 60),
    retryInterval: Duration(seconds: 30),
  );

  static const engaged = ManagedBannerRefreshPolicy(
    refreshInterval: Duration(seconds: 30),
    retryInterval: Duration(seconds: 30),
  );

  final Duration refreshInterval;
  final Duration retryInterval;

  const ManagedBannerRefreshPolicy({
    required this.refreshInterval,
    required this.retryInterval,
  });

  void validate() {
    if (refreshInterval < minimumInterval) {
      throw ArgumentError.value(
        refreshInterval,
        'refreshInterval',
        'Must be at least ${minimumInterval.inSeconds} seconds.',
      );
    }
    if (retryInterval < minimumInterval) {
      throw ArgumentError.value(
        retryInterval,
        'retryInterval',
        'Must be at least ${minimumInterval.inSeconds} seconds.',
      );
    }
  }
}

class ManagedBannerAdController extends ChangeNotifier {
  final BannerAdSize adSize;
  final AdRequest adRequest;
  final ManagedBannerRefreshPolicy refreshPolicy;

  /// How long a single load may stay unanswered before it counts as failed.
  final Duration loadTimeout;

  Duration get refreshInterval => refreshPolicy.refreshInterval;
  Duration get retryInterval => refreshPolicy.retryInterval;

  BannerAd? _bannerAd;
  StreamSubscription<BannerAdLoadState>? _loadSubscription;
  Timer? _refreshTimer;
  Timer? _loadWatchdog;
  DateTime? _visibleSince;
  late Duration _remaining;
  bool _visible = false;
  bool _started = false;
  bool _loading = false;
  bool _loadAttempted = false;
  bool _destroyed = false;
  bool _notifierDisposed = false;

  ManagedBannerAdController({
    required this.adSize,
    required this.adRequest,
    ManagedBannerRefreshPolicy? refreshPolicy,
    Duration? refreshInterval,
    Duration? retryInterval,
    this.loadTimeout = const Duration(seconds: 30),
  }) : refreshPolicy = refreshPolicy ??
            ManagedBannerRefreshPolicy(
              refreshInterval: refreshInterval ??
                  ManagedBannerRefreshPolicy.standard.refreshInterval,
              retryInterval: retryInterval ??
                  ManagedBannerRefreshPolicy.standard.retryInterval,
            ) {
    if (refreshPolicy != null &&
        (refreshInterval != null || retryInterval != null)) {
      throw ArgumentError(
        'Use either refreshPolicy or refreshInterval and retryInterval.',
      );
    }
    this.refreshPolicy.validate();
    if (loadTimeout <= Duration.zero) {
      throw ArgumentError.value(loadTimeout, 'loadTimeout', 'Must be positive.');
    }
    _remaining = this.refreshPolicy.refreshInterval;
  }

  BannerAd? get bannerAd => _bannerAd;

  bool get isLoading => _loading;

  bool get isDestroyed => _destroyed;

  Future<void> start() async {
    if (_destroyed) {
      throw StateError('Managed banner is destroyed.');
    }
    if (_started) return;
    _started = true;
    final banner = BannerAd(adSize: adSize);
    _bannerAd = banner;
    _loadSubscription = banner.loadStateStream.listen(_handleLoadState);
    notifyListeners();
    if (_visible) {
      await _requestLoad();
    }
  }

  void setVisible(bool value) {
    if (_destroyed || _visible == value) return;
    if (!value) {
      _pauseVisibleTime();
      return;
    }
    _visible = true;
    _visibleSince = DateTime.now();
    unawaited(_resumeVisibleWork());
  }

  Future<void> _resumeVisibleWork() async {
    if (!_started || _destroyed || !_visible || _bannerAd == null) return;
    if (_loading) return;
    if (_loadAttempted) {
      _scheduleRefresh();
    } else {
      await _requestLoad();
    }
  }

  void _handleLoadState(BannerAdLoadState state) {
    if (_destroyed) return;
    if (state is BannerAdLoadStateLoading) {
      _loading = true;
      _refreshTimer?.cancel();
    } else if (state is BannerAdLoadStateLoaded) {
      _loadWatchdog?.cancel();
      _loading = false;
      _remaining = refreshInterval;
      _restartVisibleClock();
    } else if (state is BannerAdLoadStateError) {
      _loadWatchdog?.cancel();
      _loading = false;
      _remaining = retryInterval;
      _restartVisibleClock();
    }
    notifyListeners();
  }

  void _pauseVisibleTime() {
    if (!_visible) return;
    final startedAt = _visibleSince;
    if (startedAt != null && !_loading) {
      final elapsed = DateTime.now().difference(startedAt);
      _remaining = elapsed >= _remaining ? Duration.zero : _remaining - elapsed;
    }
    _visible = false;
    _visibleSince = null;
    _refreshTimer?.cancel();
  }

  void _restartVisibleClock() {
    _refreshTimer?.cancel();
    if (!_visible) return;
    _visibleSince = DateTime.now();
    _scheduleRefresh();
  }

  void _scheduleRefresh() {
    _refreshTimer?.cancel();
    if (_destroyed || !_visible || _loading || _bannerAd == null) return;
    if (_remaining <= Duration.zero) {
      unawaited(_refresh());
      return;
    }
    _refreshTimer = Timer(_remaining, () => unawaited(_refresh()));
  }

  Future<void> _refresh() async {
    if (_destroyed || !_visible || _loading) return;
    _remaining = refreshInterval;
    _visibleSince = DateTime.now();
    await _requestLoad();
  }

  Future<void> _requestLoad() async {
    final banner = _bannerAd;
    if (_destroyed || !_visible || _loading || banner == null) return;
    _loading = true;
    _loadAttempted = true;
    notifyListeners();
    try {
      await banner.load(adRequest, timeout: loadTimeout);
      _startLoadWatchdog();
    } catch (_) {
      if (_destroyed) return;
      _failCurrentLoad();
    }
  }

  /// Recovers the refresh cycle when the native side accepts a request and
  /// then never reports back.
  void _startLoadWatchdog() {
    _loadWatchdog?.cancel();
    if (_destroyed || !_loading) return;
    _loadWatchdog = Timer(loadTimeout, () {
      if (_destroyed || !_loading) return;
      _failCurrentLoad();
    });
  }

  void _failCurrentLoad() {
    _loadWatchdog?.cancel();
    _loading = false;
    _remaining = retryInterval;
    _restartVisibleClock();
    notifyListeners();
  }

  Future<void> destroy() async {
    if (_destroyed) return;
    _destroyed = true;
    _refreshTimer?.cancel();
    _loadWatchdog?.cancel();
    try {
      await _loadSubscription?.cancel();
      await _bannerAd?.destroy();
    } finally {
      _bannerAd = null;
      if (!_notifierDisposed) {
        _notifierDisposed = true;
        super.dispose();
      }
    }
  }

  @override
  void dispose() {
    if (!_notifierDisposed) {
      _notifierDisposed = true;
      super.dispose();
    }
    unawaited(destroy().catchError((_) {}));
  }
}

class ManagedBannerAdWidget extends StatefulWidget {
  final ManagedBannerAdController controller;

  const ManagedBannerAdWidget({super.key, required this.controller});

  @override
  State<ManagedBannerAdWidget> createState() => _ManagedBannerAdWidgetState();
}

class _ManagedBannerAdWidgetState extends State<ManagedBannerAdWidget>
    with WidgetsBindingObserver {
  ScrollPosition? _scrollPosition;
  AppLifecycleState _lifecycleState =
      WidgetsBinding.instance.lifecycleState ?? AppLifecycleState.resumed;

  @override
  void initState() {
    super.initState();
    if (widget.controller.isDestroyed) {
      throw StateError(
        'ManagedBannerAdWidget was given a destroyed controller. '
        'Create a new controller for a new placement.',
      );
    }
    WidgetsBinding.instance.addObserver(this);
    unawaited(widget.controller.start());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _attachScrollPosition(Scrollable.maybeOf(context)?.position);
    _scheduleVisibilityUpdate();
  }

  @override
  void didUpdateWidget(ManagedBannerAdWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.controller, widget.controller)) {
      oldWidget.controller.setVisible(false);
      unawaited(widget.controller.start());
    }
    _scheduleVisibilityUpdate();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _lifecycleState = state;
    _updateVisibility();
  }

  @override
  void didChangeMetrics() {
    _scheduleVisibilityUpdate();
  }

  void _attachScrollPosition(ScrollPosition? position) {
    if (identical(_scrollPosition, position)) return;
    _scrollPosition?.removeListener(_updateVisibility);
    _scrollPosition = position;
    _scrollPosition?.addListener(_updateVisibility);
  }

  void _scheduleVisibilityUpdate() {
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateVisibility());
  }

  void _updateVisibility() {
    if (!mounted) return;
    final renderObject = context.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) {
      widget.controller.setVisible(false);
      return;
    }
    final offset = renderObject.localToGlobal(Offset.zero);
    final bounds = offset & renderObject.size;
    final viewport = Offset.zero & MediaQuery.of(context).size;
    final scrollViewport = RenderAbstractViewport.maybeOf(renderObject);
    final scrollPosition = _scrollPosition;
    var inScrollViewport = true;
    if (scrollViewport != null && scrollPosition != null) {
      // getOffsetToReveal(0) is the scroll offset of the placement itself.
      final leading = scrollViewport.getOffsetToReveal(renderObject, 0).offset;
      final extent = scrollPosition.axis == Axis.vertical
          ? renderObject.size.height
          : renderObject.size.width;
      final firstVisibleOffset = scrollPosition.pixels;
      final lastVisibleOffset =
          firstVisibleOffset + scrollPosition.viewportDimension;
      inScrollViewport = firstVisibleOffset < leading + extent &&
          lastVisibleOffset > leading;
    }
    final visible = _lifecycleState == AppLifecycleState.resumed &&
        // ignore: deprecated_member_use
        TickerMode.of(context) &&
        bounds.overlaps(viewport) &&
        inScrollViewport &&
        renderObject.size.width > 0 &&
        renderObject.size.height > 0;
    widget.controller.setVisible(visible);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollPosition?.removeListener(_updateVisibility);
    widget.controller.setVisible(false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _scheduleVisibilityUpdate();
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final banner = widget.controller.bannerAd;
        if (banner == null) {
          return SizedBox(width: widget.controller.adSize.width.toDouble());
        }
        return AdWidget(bannerAd: banner);
      },
    );
  }
}
