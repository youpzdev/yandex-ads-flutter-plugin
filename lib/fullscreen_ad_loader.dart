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

  static const _createChannel =
      MethodChannel('yandex_mobileads.createAdLoader');

  static var _nextId = 0;

  late final int _id;
  late final MethodChannel _channel;
  late final Future<void> _initialized;
  StreamSubscription? _eventSubscription;

  int _nextRequestId = 0;
  final _pendingLoads = <int, Completer<Map<String, dynamic>>>{};

  void _init(String loaderType, String channelPath) {
    _id = _nextId++;
    final name = 'yandex_mobileads.$channelPath.$_id';
    _channel = MethodChannel(name);
    _finalizer.attach(this, _channel, detach: this);

    _initialized =
        _createChannel.invokeMethod(loaderType, {'id': _id}).then((_) {
      // Subscribe to EventChannel only AFTER native has created it
      final eventChannel = EventChannel('$name.events');
      _eventSubscription =
          eventChannel.receiveBroadcastStream().listen((event) {
        _dispatchEvent(Map<String, dynamic>.from(event as Map));
      });
    });
  }

  void _dispatchEvent(Map<String, dynamic> result) {
    final requestId = result['requestId'] as int?;
    if (requestId == null) return;
    final completer = _pendingLoads.remove(requestId);
    completer?.complete(result);
  }

  /// Loads an ad with the given [AdRequest].
  Future<Map<String, dynamic>> _invokeLoad(AdRequest adRequest) async {
    await (YandexAds._initFuture ?? Future<void>.value());
    await _initialized;
    final requestId = _nextRequestId++;
    final completer = Completer<Map<String, dynamic>>();
    _pendingLoads[requestId] = completer;

    final map = adRequest._toMap();
    map['requestId'] = requestId;
    map['parameters'] = {
      _pluginType: _flutter,
      _pluginVersion: YandexAds.pluginVersion,
    }..addAll(adRequest.parameters ?? {});

    _channel.invokeMethod('load', map);
    return completer.future;
  }

  void cancelLoading() {
    _channel.invokeMethod('cancelLoading');
  }

  void destroy() {
    _channel.invokeMethod('destroy');
    _eventSubscription?.cancel();
    _finalizer.detach(this);
  }
}
