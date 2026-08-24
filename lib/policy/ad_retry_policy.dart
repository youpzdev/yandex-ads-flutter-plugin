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

/// How a failed ad request is repeated.
///
/// No-fill is normal and temporary, so a failed request is repeated with a
/// growing delay instead of as fast as the network allows.
class AdRetryPolicy {
  /// Waits 5 seconds, then doubles up to 5 minutes, without giving up.
  static const standard = AdRetryPolicy();

  /// Reacts faster, for placements the user is waiting on right now.
  static const eager = AdRetryPolicy(
    initialDelay: Duration(seconds: 2),
    maximumDelay: Duration(minutes: 1),
  );

  /// Backs off further and stops after ten attempts.
  static const patient = AdRetryPolicy(
    initialDelay: Duration(seconds: 15),
    maximumDelay: Duration(minutes: 15),
    maximumAttempts: 10,
  );

  /// Delay before the first repeat.
  final Duration initialDelay;

  /// Upper bound for the growing delay.
  final Duration maximumDelay;

  /// Growth factor applied to every following attempt.
  final double multiplier;

  /// Random share of the delay, so devices do not retry in lockstep.
  ///
  /// `0.2` spreads each delay by up to ±20%.
  final double jitter;

  /// Number of attempts after which the request is abandoned.
  ///
  /// `null` keeps retrying while the app is in the foreground.
  final int? maximumAttempts;

  const AdRetryPolicy({
    this.initialDelay = const Duration(seconds: 5),
    this.maximumDelay = const Duration(minutes: 5),
    this.multiplier = 2.0,
    this.jitter = 0.2,
    this.maximumAttempts,
  });

  void validate() {
    if (initialDelay <= Duration.zero) {
      throw ArgumentError.value(
          initialDelay, 'initialDelay', 'Must be positive.');
    }
    if (maximumDelay < initialDelay) {
      throw ArgumentError.value(
        maximumDelay,
        'maximumDelay',
        'Must not be shorter than initialDelay.',
      );
    }
    if (multiplier < 1) {
      throw ArgumentError.value(multiplier, 'multiplier', 'Must be at least 1.');
    }
    if (jitter < 0 || jitter > 1) {
      throw ArgumentError.value(jitter, 'jitter', 'Must be between 0 and 1.');
    }
    final attempts = maximumAttempts;
    if (attempts != null && attempts <= 0) {
      throw ArgumentError.value(
          attempts, 'maximumAttempts', 'Must be positive.');
    }
  }

  /// Whether another attempt is allowed after [failedAttempts] failures.
  bool allowsAttempt(int failedAttempts) {
    final attempts = maximumAttempts;
    return attempts == null || failedAttempts < attempts;
  }

  /// Delay before the attempt that follows [failedAttempts] failures.
  ///
  /// [noise] spreads the result within [jitter] and is expected in the
  /// `-1.0 ... 1.0` range.
  Duration delayAfter(int failedAttempts, {double noise = 0}) {
    final steps = failedAttempts <= 1 ? 0 : failedAttempts - 1;
    var micros = initialDelay.inMicroseconds.toDouble();
    for (var step = 0; step < steps; step++) {
      micros *= multiplier;
      if (micros >= maximumDelay.inMicroseconds) break;
    }
    final capped = micros.clamp(
      initialDelay.inMicroseconds.toDouble(),
      maximumDelay.inMicroseconds.toDouble(),
    );
    final spread = capped * jitter * noise.clamp(-1.0, 1.0);
    final result = (capped + spread).round();
    return Duration(microseconds: result < 0 ? 0 : result);
  }
}
