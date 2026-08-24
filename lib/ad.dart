/*
 * This file is a part of the Yandex Advertising Network
 *
 * Version for Flutter (C) 2023 YANDEX
 *
 * You may not use this file except in compliance with the License.
 * You may obtain a copy of the License at https://legal.yandex.com/partner_ch/
 */

part of 'mobile_ads.dart';

final _finalizer = Finalizer<MethodChannel>((channel) {
  unawaited(_finalizeAd(channel));
});

Future<void> _finalizeAd(MethodChannel channel) async {
  try {
    await channel.invokeMethod<void>('destroy');
  } catch (_) {}
}

mixin _Ad {
  abstract final String methodChannelName;

  bool _destroyed = false;
  Future<void>? _destroyFuture;

  MethodChannel _createMethodChannel() {
    final channel = MethodChannel(methodChannelName);
    _finalizer.attach(this, channel, detach: this);
    return channel;
  }

  late final MethodChannel _channel = _createMethodChannel();

  bool get isDestroyed => _destroyed;

  void ensureAlive() {
    if (_destroyed) {
      throw StateError('Ad is destroyed and cannot be used anymore.');
    }
  }

  Future<void> destroy() {
    return _destroyFuture ??= _destroy();
  }

  Future<void> _destroy() async {
    if (_destroyed) return;
    _destroyed = true;
    _finalizer.detach(this);
    await _channel.invokeMethod<void>('destroy');
  }
}
