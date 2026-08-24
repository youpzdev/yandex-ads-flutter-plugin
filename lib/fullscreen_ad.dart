/*
 * This file is a part of the Yandex Advertising Network
 *
 * Version for Flutter (C) 2023 YANDEX
 *
 * You may not use this file except in compliance with the License.
 * You may obtain a copy of the License at https://legal.yandex.com/partner_ch/
 */

part of 'mobile_ads.dart';

abstract class _FullscreenAd with _Ad {
  _FullScreenAdEventListener? _eventListener;

  final int id;
  final String channelName;
  final AdInfo? adInfo;

  @override
  String get methodChannelName => '$channelName.$id';

  final int _consentGeneration = _AdConsent.generation;
  bool _shown = false;
  bool _holdsScreen = false;
  Timer? _screenGuard;

  /// Upper bound for holding the screen claim without a dismissal.
  static const screenGuard = Duration(minutes: 10);

  _FullscreenAd({required this.channelName, required this.id, this.adInfo});

  /// Whether this ad may still be shown.
  ///
  /// Becomes false once the ad was shown, or once consent, age or location
  /// settings changed after it was loaded.
  bool get canShow =>
      !isDestroyed && !_shown && _consentGeneration == _AdConsent.generation;

  Future<void> _setAdEventListener({
    required _FullScreenAdEventListener eventListener,
  }) async {
    if (_holdsScreen) {
      throw StateError('Cannot replace the event listener of a shown ad.');
    }
    await _eventListener?.dispose();
    _eventListener = eventListener;
    _eventListener?.setupCallbacks();
  }

  /// Shows ad on top of the application.
  ///
  /// Set an event listener before calling this method for callbacks
  /// about events that occur when an ad is displayed.
  Future<void> show() async {
    ensureAlive();
    if (_shown) {
      throw StateError('This ad was already shown.');
    }
    if (_consentGeneration != _AdConsent.generation) {
      throw StateError(
        'Consent, age or location settings changed after this ad was loaded. '
        'Load a new ad.',
      );
    }
    if (!_AdActivity.tryBegin()) {
      throw _ScreenBusyError();
    }
    _shown = true;
    _holdsScreen = true;
    _screenGuard = Timer(screenGuard, _releaseScreen);
    try {
      await _channel.invokeMethod<void>('show');
    } catch (_) {
      _releaseScreen();
      rethrow;
    }
    final listener = _eventListener;
    if (listener == null) {
      _releaseScreen();
      return;
    }
    unawaited(
      listener.waitForTerminal().then(
        (_) => _releaseScreen(),
        onError: (Object _) {
          if (identical(_eventListener, listener)) _releaseScreen();
        },
      ),
    );
  }

  void _releaseScreen() {
    _screenGuard?.cancel();
    _screenGuard = null;
    if (!_holdsScreen) return;
    _holdsScreen = false;
    _AdActivity.end();
  }

  Future waitForDismiss();

  @override
  Future<void> destroy() async {
    _releaseScreen();
    await _eventListener?.dispose();
    await super.destroy();
  }
}
