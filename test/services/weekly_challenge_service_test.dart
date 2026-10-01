import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chesswardens/models/weekly_challenge.dart';
import 'package:chesswardens/services/weekly_challenge_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late WeeklyChallengeService service;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    service = WeeklyChallengeService();
  });

  group('computeWeekKey', () {
    test('groups dates within the same ISO week under the same key', () {
      // Monday 2026-09-28 through Sunday 2026-10-04 are the same ISO week.
      final monday = computeWeekKey(DateTime(2026, 9, 28));
      final wednesday = computeWeekKey(DateTime(2026, 9, 30));
      final sunday = computeWeekKey(DateTime(2026, 10, 4));

      expect(wednesday, monday);
      expect(sunday, monday);
    });

    test('gives adjacent weeks different keys', () {
      final thisWeek = computeWeekKey(DateTime(2026, 9, 28));
      final nextWeek = computeWeekKey(DateTime(2026, 10, 5));

      expect(thisWeek, isNot(nextWeek));
    });

    test('a year-end week credits the ISO year of its Thursday', () {
      // 2025-12-29 (Mon) .. 2026-01-04 (Sun) is one ISO week, whose
      // Thursday (2026-01-01) falls in 2026, so the whole week is "2026-W01".
      final key = computeWeekKey(DateTime(2025, 12, 29));
      expect(key, '2026-W01');
    });
  });

  group('WeeklyChallengeService', () {
    test('missions start at zero and reset is tracked per week', () async {
      final challenges = await service.loadChallenges();
      expect(challenges.length, WeeklyChallengeType.values.length);
      expect(challenges.every((c) => c.currentCount == 0), true);
    });

    test('recordProgress increments and clamps to target count', () async {
      await service.recordProgress(WeeklyChallengeType.winMatches, 3);
      var challenges = await service.loadChallenges();
      expect(
        challenges
            .firstWhere((c) => c.type == WeeklyChallengeType.winMatches)
            .currentCount,
        3,
      );

      await service.recordProgress(WeeklyChallengeType.winMatches, 100);
      challenges = await service.loadChallenges();
      expect(
        challenges
            .firstWhere((c) => c.type == WeeklyChallengeType.winMatches)
            .currentCount,
        WeeklyChallengeType.winMatches.targetCount,
      );
    });

    test('claimReward only marks claimed once challenge is complete',
        () async {
      // Not complete yet: claiming does nothing.
      var challenges =
          await service.claimReward(WeeklyChallengeType.playMatches);
      expect(
        challenges
            .firstWhere((c) => c.type == WeeklyChallengeType.playMatches)
            .rewardClaimed,
        false,
      );

      await service.recordProgress(
        WeeklyChallengeType.playMatches,
        WeeklyChallengeType.playMatches.targetCount,
      );
      challenges =
          await service.claimReward(WeeklyChallengeType.playMatches);
      expect(
        challenges
            .firstWhere((c) => c.type == WeeklyChallengeType.playMatches)
            .rewardClaimed,
        true,
      );
    });
  });
}
