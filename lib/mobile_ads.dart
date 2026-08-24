/*
 * This file is a part of the Yandex Advertising Network
 *
 * Version for Flutter (C) 2023 YANDEX
 *
 * You may not use this file except in compliance with the License.
 * You may obtain a copy of the License at https://legal.yandex.com/partner_ch/
 */

library yandex_mobileads;

import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

part 'ad.dart';
part 'ad_request.dart';
part 'ad_request_configuration.dart';
part 'ad_targeting.dart';
part 'ad_theme.dart';
part 'ad_location.dart';
part 'ad_info.dart';
part 'impression_data.dart';
part 'simple_impression_data.dart';
part 'banner/banner_ad_size.dart';
part 'banner/banner_ad_state.dart';
part 'banner/banner_ad.dart';
part 'banner/managed_banner_ad.dart';
part 'policy/ad_retry_policy.dart';
part 'policy/ad_frequency_policy.dart';
part 'pool/fullscreen_ad_pool.dart';
part 'native/native_ad_state.dart';
part 'native/native_ad.dart';
part 'events/ad_telemetry.dart';
part 'events/callback_name.dart';
part 'events/fullscreen_callback_name.dart';
part 'events/error.dart';
part 'events/banner_ad_event_listener.dart';
part 'events/fullscreen_event_listener.dart';
part 'fullscreen_ad.dart';
part 'fullscreen_ad_loader.dart';
part 'appopenad/app_open_ad.dart';
part 'appopenad/app_open_ad_listener.dart';
part 'appopenad/app_open_ad_loader.dart';
part 'appopenad/app_open_ad_controller.dart';
part 'interstitial/interstitial_ad.dart';
part 'interstitial/interstitial_ad_event_listener.dart';
part 'interstitial/interstitial_ad_loader.dart';
part 'platform/android_interface.dart';
part 'platform/ios_interface.dart';
part 'platform/platform_interface.dart';
part 'rewarded/reward.dart';
part 'rewarded/rewarded_ad.dart';
part 'rewarded/rewarded_ad_event_listener.dart';
part 'rewarded/rewarded_ad_loader.dart';

/// This class allows you to set general SDK settings.
class YandexAds {
  static const _path = 'yandex_mobileads.mobileAds';
  static const _channel = MethodChannel(_path);

  static var _loggingEnabled = false;
  static var _locationTracking = false;
  static var _userConsent = false;
  static var _debugErrorIndicatorEnabled = false;
  static var _ageRestricted = false;

  static Future<void>? _initFuture;

  /// Returns the plugin version as a string.
  static const pluginVersion = '8.3.0';

  /// Lifecycle events of every ad created by this plugin.
  ///
  /// Forward them to your analytics to see load failures, fill rate and
  /// impression revenue per ad unit without wiring a callback into every
  /// placement.
  static Stream<AdEvent> get events => _AdEventBus.stream;

  /// A private constructor to prevent instancing.
  YandexAds._();

  /// Whether the library outputs log messages.
  static bool get loggingEnabled => _loggingEnabled;

  /// Enables logging.
  static Future<void> setLogging(bool value) async {
    await _channel.invokeMethod('enableLogging', value);
    _loggingEnabled = value;
  }

  /// Whether using location for targeting ads is allowed.
  static bool get locationTracking => _locationTracking;

  /// Sets the location tracking.
  static Future<void> setLocationTracking(bool value) async {
    await _channel.invokeMethod('setLocationTracking', value);
    _locationTracking = value;
    _AdConsent.invalidate();
  }

  /// Whether the user from a GDPR country has allowed
  /// using their personal data for targeting ads.
  static bool get userConsent => _userConsent;

  /// Sets the user consent.
  static Future<void> setUserConsent(bool value) async {
    await _channel.invokeMethod('setUserConsent', value);
    _userConsent = value;
    _AdConsent.invalidate();
  }

  /// Whether the indicator for native ad integration errors is shown.
  static bool get debugErrorIndicatorEnabled => _debugErrorIndicatorEnabled;

  /// Enables or disables the debug error indicator.
  static Future<void> setDebugErrorIndicator(bool value) async {
    await _channel.invokeMethod('enableDebugErrorIndicator', value);
    _debugErrorIndicatorEnabled = value;
  }

  static bool get ageRestricted => _ageRestricted;

  static Future<void> setAgeRestricted(bool value) async {
    await _channel.invokeMethod('setAgeRestricted', value);
    _ageRestricted = value;
    _AdConsent.invalidate();
  }

  /// Initializes the Mobile Ads SDK.
  /// Call this in the `initState` method of your app widget.
  static Future<void> initialize() async {
    final active = _initFuture;
    if (active != null) {
      await active;
      return;
    }
    final initialization = _channel.invokeMethod<void>('initialize');
    _initFuture = initialization;
    try {
      await initialization;
    } catch (_) {
      if (identical(_initFuture, initialization)) {
        _initFuture = null;
      }
      rethrow;
    }
  }

  /// Shows Debug Panel.
  static Future<void> showDebugPanel() async {
    await _channel.invokeMethod("showDebugPanel");
  }

  /// Sets whether the audio session is automatically managed by the SDK. iOS only.
  static Future<void> setAutomaticAudioSessionManagement(bool value) async {
    await _channel.invokeMethod('setAutomaticAudioSessionManagement', value);
  }
}
