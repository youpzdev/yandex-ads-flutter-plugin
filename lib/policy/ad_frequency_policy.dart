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

/// Why a full-screen ad may not be shown right now.
enum AdFrequencyBlock {
  /// Nothing blocks the show.
  none,

  /// The session is younger than the configured grace period.
  startupGrace,

  /// The previous ad was shown too recently.
  minimumInterval,

  /// The hourly cap is used up.
  hourlyCap,

  /// The daily cap is used up.
  dailyCap,

  /// The session cap is used up.
  sessionCap,
}

/// The answer of an [AdFrequencyGate] for one moment in time.
class AdFrequencyDecision {
  /// Whether a show is allowed right now.
  final bool isAllowed;

  /// What holds the show back.
  final AdFrequencyBlock block;

  /// How long until the same question can be answered with yes.
  ///
  /// `null` means no waiting helps within the tracked window — a session cap
  /// only resets with a new session.
  final Duration? retryAfter;

  const AdFrequencyDecision._(this.isAllowed, this.block, this.retryAfter);

  const AdFrequencyDecision.allowed()
      : this._(true, AdFrequencyBlock.none, null);

  const AdFrequencyDecision.blocked(AdFrequencyBlock block, Duration? after)
      : this._(false, block, after);

  @override
  String toString() => isAllowed
      ? 'AdFrequencyDecision(allowed)'
      : 'AdFrequencyDecision($block, retryAfter: $retryAfter)';
}

/// How often a full-screen ad may be shown.
///
/// Interstitials earn less per user when they are shown too often: the session
/// gets shorter, retention drops and the placement loses the impressions it
/// would have earned tomorrow. The caps here are the plugin's own policy and
/// do not replace the rules of the ad network.
class AdFrequencyPolicy {
  /// One ad every 3 minutes, at most 6 an hour and 20 a day.
  static const standard = AdFrequencyPolicy();

  /// Rare shows for placements that must stay unobtrusive.
  static const conservative = AdFrequencyPolicy(
    minimumInterval: Duration(minutes: 8),
    maximumPerHour: 3,
    maximumPerDay: 10,
    startupGrace: Duration(minutes: 1),
  );

  /// Denser shows for sessions built around short loops.
  static const engaged = AdFrequencyPolicy(
    minimumInterval: Duration(minutes: 2),
    maximumPerHour: 10,
    maximumPerDay: 40,
    startupGrace: Duration(seconds: 20),
  );

  /// No caps at all. Use it only when another layer enforces pacing.
  static const unlimited = AdFrequencyPolicy(
    minimumInterval: Duration.zero,
    startupGrace: Duration.zero,
  );

  /// Shortest gap between two shows.
  final Duration minimumInterval;

  /// How long after the session start the first ad stays blocked.
  final Duration startupGrace;

  /// Shows allowed within a rolling hour.
  final int? maximumPerHour;

  /// Shows allowed within a rolling day.
  final int? maximumPerDay;

  /// Shows allowed within one session.
  final int? maximumPerSession;

  const AdFrequencyPolicy({
    this.minimumInterval = const Duration(minutes: 3),
    this.startupGrace = const Duration(seconds: 30),
    this.maximumPerHour = 6,
    this.maximumPerDay = 20,
    this.maximumPerSession,
  });

  void validate() {
    if (minimumInterval < Duration.zero) {
      throw ArgumentError.value(
          minimumInterval, 'minimumInterval', 'Must not be negative.');
    }
    if (startupGrace < Duration.zero) {
      throw ArgumentError.value(
          startupGrace, 'startupGrace', 'Must not be negative.');
    }
    for (final entry in {
      'maximumPerHour': maximumPerHour,
      'maximumPerDay': maximumPerDay,
      'maximumPerSession': maximumPerSession,
    }.entries) {
      final value = entry.value;
      if (value != null && value <= 0) {
        throw ArgumentError.value(value, entry.key, 'Must be positive.');
      }
    }
  }
}

/// Applies an [AdFrequencyPolicy] to the shows that already happened.
///
/// The gate keeps its history in memory. Pass [history] from your own storage
/// to keep daily caps meaningful across app launches, and persist
/// [showTimestamps] when the app goes to the background.
class AdFrequencyGate {
  static const _day = Duration(hours: 24);
  static const _hour = Duration(hours: 1);

  final AdFrequencyPolicy policy;
  final DateTime Function() _clock;
  final List<DateTime> _shows;
  late final DateTime _sessionStart;
  int _sessionShows = 0;

  AdFrequencyGate({
    this.policy = AdFrequencyPolicy.standard,
    DateTime Function()? clock,
    List<DateTime>? history,
    DateTime? sessionStart,
  })  : _clock = clock ?? DateTime.now,
        _shows = List<DateTime>.from(history ?? const <DateTime>[]) {
    policy.validate();
    _sessionStart = sessionStart ?? _clock();
    _shows.sort();
    _forget(_clock());
  }

  /// Show timestamps still inside the tracked day, oldest first.
  List<DateTime> get showTimestamps => List<DateTime>.unmodifiable(_shows);

  /// Shows recorded since this gate was created.
  int get sessionShowCount => _sessionShows;

  /// Whether a show is allowed right now.
  bool get isAllowed => evaluate().isAllowed;

  /// Full answer for the current moment, including the reason and the wait.
  AdFrequencyDecision evaluate() {
    final now = _clock();
    _forget(now);

    final sinceStart = now.difference(_sessionStart);
    if (sinceStart < policy.startupGrace) {
      return AdFrequencyDecision.blocked(
        AdFrequencyBlock.startupGrace,
        policy.startupGrace - sinceStart,
      );
    }

    final sessionCap = policy.maximumPerSession;
    if (sessionCap != null && _sessionShows >= sessionCap) {
      return const AdFrequencyDecision.blocked(
          AdFrequencyBlock.sessionCap, null);
    }

    if (_shows.isNotEmpty) {
      final sinceLast = now.difference(_shows.last);
      if (sinceLast < policy.minimumInterval) {
        return AdFrequencyDecision.blocked(
          AdFrequencyBlock.minimumInterval,
          policy.minimumInterval - sinceLast,
        );
      }
    }

    final hourly = _capBlock(
      now: now,
      window: _hour,
      cap: policy.maximumPerHour,
      block: AdFrequencyBlock.hourlyCap,
    );
    if (hourly != null) return hourly;

    return _capBlock(
          now: now,
          window: _day,
          cap: policy.maximumPerDay,
          block: AdFrequencyBlock.dailyCap,
        ) ??
        const AdFrequencyDecision.allowed();
  }

  /// Records a show that actually reached the user.
  ///
  /// Call it when the ad was displayed, not when it was loaded: a request that
  /// never became an impression must not consume the cap.
  void recordShow([DateTime? at]) {
    final moment = at ?? _clock();
    _shows.add(moment);
    _shows.sort();
    _sessionShows++;
    _forget(moment);
  }

  /// The history in a form that survives an app restart.
  ///
  /// Daily caps only mean something when the history outlives the process, so
  /// persist this map and hand it back to [AdFrequencyGate.fromJson] on the
  /// next launch. It contains no user data — only the moments ads were shown.
  Map<String, Object?> toJson() => {
        'shows': _shows
            .map((show) => show.toUtc().millisecondsSinceEpoch)
            .toList(growable: false),
      };

  /// Restores a gate from [toJson].
  ///
  /// Timestamps that are unreadable or in the future are dropped rather than
  /// trusted: a clock change must not unlock an exhausted cap.
  static AdFrequencyGate fromJson(
    Map<String, Object?> json, {
    AdFrequencyPolicy policy = AdFrequencyPolicy.standard,
    DateTime Function()? clock,
    DateTime? sessionStart,
  }) {
    final now = (clock ?? DateTime.now)();
    final raw = json['shows'];
    final shows = <DateTime>[];
    if (raw is List) {
      for (final entry in raw) {
        if (entry is! num) continue;
        final moment =
            DateTime.fromMillisecondsSinceEpoch(entry.toInt(), isUtc: true)
                .toLocal();
        if (moment.isAfter(now)) continue;
        shows.add(moment);
      }
    }
    return AdFrequencyGate(
      policy: policy,
      clock: clock,
      history: shows,
      sessionStart: sessionStart,
    );
  }

  /// Drops the recorded history, for example after a consent change.
  void reset() {
    _shows.clear();
    _sessionShows = 0;
  }

  AdFrequencyDecision? _capBlock({
    required DateTime now,
    required Duration window,
    required int? cap,
    required AdFrequencyBlock block,
  }) {
    if (cap == null) return null;
    final since = now.subtract(window);
    final inWindow = _shows.where((show) => show.isAfter(since)).toList();
    if (inWindow.length < cap) return null;
    final oldest = inWindow[inWindow.length - cap];
    final wait = oldest.add(window).difference(now);
    return AdFrequencyDecision.blocked(
      block,
      wait > Duration.zero ? wait : Duration.zero,
    );
  }

  void _forget(DateTime now) {
    final horizon = now.subtract(_day);
    _shows.removeWhere((show) => !show.isAfter(horizon));
  }
}
