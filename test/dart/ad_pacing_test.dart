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

import 'package:flutter_test/flutter_test.dart';
import 'package:yandex_mobileads/mobile_ads.dart';

void main() {
  group('retry policy', () {
    test('grows the delay and stops at the ceiling', () {
      const policy = AdRetryPolicy(
        initialDelay: Duration(seconds: 4),
        maximumDelay: Duration(seconds: 30),
        jitter: 0,
      );

      expect(policy.delayAfter(1), const Duration(seconds: 4));
      expect(policy.delayAfter(2), const Duration(seconds: 8));
      expect(policy.delayAfter(3), const Duration(seconds: 16));
      expect(policy.delayAfter(4), const Duration(seconds: 30));
      expect(policy.delayAfter(9), const Duration(seconds: 30));
    });

    test('spreads the delay within the configured jitter', () {
      const policy = AdRetryPolicy(
        initialDelay: Duration(seconds: 10),
        maximumDelay: Duration(seconds: 10),
        jitter: 0.5,
      );

      expect(policy.delayAfter(1, noise: 1), const Duration(seconds: 15));
      expect(policy.delayAfter(1, noise: -1), const Duration(seconds: 5));
      expect(policy.delayAfter(1, noise: 0), const Duration(seconds: 10));
    });

    test('respects a limited number of attempts', () {
      const limited = AdRetryPolicy(maximumAttempts: 2);

      expect(limited.allowsAttempt(1), isTrue);
      expect(limited.allowsAttempt(2), isFalse);
      expect(AdRetryPolicy.standard.allowsAttempt(1000), isTrue);
    });

    test('rejects a policy that cannot back off', () {
      expect(
        () => const AdRetryPolicy(
          initialDelay: Duration(seconds: 10),
          maximumDelay: Duration(seconds: 5),
        ).validate(),
        throwsArgumentError,
      );
      expect(
        () => const AdRetryPolicy(jitter: 2).validate(),
        throwsArgumentError,
      );
    });
  });

  group('frequency gate', () {
    late DateTime now;
    DateTime clock() => now;

    setUp(() => now = DateTime(2026, 8, 24, 12));

    test('holds the first show back during the startup grace', () {
      final gate = AdFrequencyGate(
        policy: const AdFrequencyPolicy(
          startupGrace: Duration(seconds: 30),
          minimumInterval: Duration.zero,
          maximumPerHour: null,
          maximumPerDay: null,
        ),
        clock: clock,
      );

      final blocked = gate.evaluate();
      expect(blocked.isAllowed, isFalse);
      expect(blocked.block, AdFrequencyBlock.startupGrace);
      expect(blocked.retryAfter, const Duration(seconds: 30));

      now = now.add(const Duration(seconds: 31));
      expect(gate.isAllowed, isTrue);
    });

    test('keeps the minimum interval between shows', () {
      final gate = AdFrequencyGate(
        policy: const AdFrequencyPolicy(
          startupGrace: Duration.zero,
          minimumInterval: Duration(minutes: 3),
          maximumPerHour: null,
          maximumPerDay: null,
        ),
        clock: clock,
      );

      gate.recordShow();
      final blocked = gate.evaluate();
      expect(blocked.block, AdFrequencyBlock.minimumInterval);
      expect(blocked.retryAfter, const Duration(minutes: 3));

      now = now.add(const Duration(minutes: 3));
      expect(gate.isAllowed, isTrue);
    });

    test('applies the hourly cap on a rolling window', () {
      final gate = AdFrequencyGate(
        policy: const AdFrequencyPolicy(
          startupGrace: Duration.zero,
          minimumInterval: Duration.zero,
          maximumPerHour: 2,
          maximumPerDay: null,
        ),
        clock: clock,
      );

      gate.recordShow();
      now = now.add(const Duration(minutes: 10));
      gate.recordShow();

      final blocked = gate.evaluate();
      expect(blocked.block, AdFrequencyBlock.hourlyCap);
      expect(blocked.retryAfter, const Duration(minutes: 50));

      now = now.add(const Duration(minutes: 51));
      expect(gate.isAllowed, isTrue);
    });

    test('a session cap cannot be waited out', () {
      final gate = AdFrequencyGate(
        policy: const AdFrequencyPolicy(
          startupGrace: Duration.zero,
          minimumInterval: Duration.zero,
          maximumPerHour: null,
          maximumPerDay: null,
          maximumPerSession: 1,
        ),
        clock: clock,
      );

      gate.recordShow();
      now = now.add(const Duration(hours: 5));

      final blocked = gate.evaluate();
      expect(blocked.block, AdFrequencyBlock.sessionCap);
      expect(blocked.retryAfter, isNull);
    });

    test('restores history and forgets shows older than a day', () {
      final gate = AdFrequencyGate(
        policy: const AdFrequencyPolicy(
          startupGrace: Duration.zero,
          minimumInterval: Duration.zero,
          maximumPerHour: null,
          maximumPerDay: 2,
        ),
        clock: clock,
        history: [
          now.subtract(const Duration(hours: 30)),
          now.subtract(const Duration(hours: 5)),
        ],
      );

      expect(gate.showTimestamps, hasLength(1));
      expect(gate.isAllowed, isTrue);

      gate.recordShow();
      expect(gate.evaluate().block, AdFrequencyBlock.dailyCap);
      expect(gate.sessionShowCount, 1);
    });

    test('history survives a restart and ignores future timestamps', () {
      final gate = AdFrequencyGate(
        policy: const AdFrequencyPolicy(
          startupGrace: Duration.zero,
          minimumInterval: Duration.zero,
          maximumPerHour: null,
          maximumPerDay: 2,
        ),
        clock: clock,
      );
      gate.recordShow();

      final stored = <String, Object?>{
        'shows': [
          ...(gate.toJson()['shows']! as List),
          now.add(const Duration(days: 1)).millisecondsSinceEpoch,
          'not a timestamp',
        ],
      };

      final restored = AdFrequencyGate.fromJson(
        stored,
        policy: const AdFrequencyPolicy(
          startupGrace: Duration.zero,
          minimumInterval: Duration.zero,
          maximumPerHour: null,
          maximumPerDay: 2,
        ),
        clock: clock,
      );

      expect(restored.showTimestamps, hasLength(1));
      expect(restored.sessionShowCount, 0);
      expect(restored.isAllowed, isTrue);

      restored.recordShow();
      expect(restored.evaluate().block, AdFrequencyBlock.dailyCap);
    });

    test('a long ad earns a longer gap after it', () {
      final gate = AdFrequencyGate(
        policy: const AdFrequencyPolicy(
          startupGrace: Duration.zero,
          minimumInterval: Duration(seconds: 30),
          maximumPerHour: null,
          maximumPerDay: null,
          durationPenalty: 2,
        ),
        clock: clock,
      );

      gate.noteShowDuration(const Duration(seconds: 30));
      gate.recordShow();

      expect(gate.effectiveMinimumInterval, const Duration(seconds: 90));
      now = now.add(const Duration(seconds: 45));
      final blocked = gate.evaluate();
      expect(blocked.block, AdFrequencyBlock.minimumInterval);
      expect(blocked.retryAfter, const Duration(seconds: 45));

      now = now.add(const Duration(seconds: 46));
      expect(gate.isAllowed, isTrue);

      // A creative that closes at once barely moves the next show.
      gate.noteShowDuration(const Duration(seconds: 2));
      gate.recordShow();
      expect(gate.effectiveMinimumInterval, const Duration(seconds: 34));
    });

    test('the duration penalty can be switched off', () {
      final gate = AdFrequencyGate(
        policy: const AdFrequencyPolicy(
          startupGrace: Duration.zero,
          minimumInterval: Duration(seconds: 30),
          maximumPerHour: null,
          maximumPerDay: null,
          durationPenalty: 0,
        ),
        clock: clock,
      );

      gate.noteShowDuration(const Duration(minutes: 5));
      expect(gate.effectiveMinimumInterval, const Duration(seconds: 30));
      expect(
        () => const AdFrequencyPolicy(durationPenalty: -1).validate(),
        throwsArgumentError,
      );
    });

    test('presets stay inside safe bounds', () {
      expect(
        AdFrequencyPolicy.conservative.minimumInterval,
        const Duration(minutes: 8),
      );
      expect(AdFrequencyPolicy.standard.maximumPerHour, 6);
      expect(AdFrequencyPolicy.engaged.maximumPerDay, 40);
      expect(
        () => const AdFrequencyPolicy(maximumPerHour: 0).validate(),
        throwsArgumentError,
      );
    });
  });
}
