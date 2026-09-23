import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chesswardens/models/daily_bonus.dart';
import 'package:chesswardens/services/daily_bonus_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('DailyBonusState', () {
    test('expRewardForDay escalates and caps at day 7', () {
      expect(DailyBonusState.expRewardForDay(1), 50);
      expect(DailyBonusState.expRewardForDay(3), 150);
      expect(DailyBonusState.expRewardForDay(7), 300);
    });
  });

  group('DailyBonusService', () {
    test('first claim starts a 1-day streak and cannot claim again same day', () async {
      final service = DailyBonusService();

      expect(await service.canClaimToday(), isTrue);

      final (state, reward) = await service.claimToday();
      expect(state.consecutiveDays, 1);
      expect(reward, 50);

      expect(await service.canClaimToday(), isFalse);
      final (_, secondReward) = await service.claimToday();
      expect(secondReward, 0, reason: '同日の再クレームは無効');
    });

    test('missions start at zero and reset is tracked per day', () async {
      final service = DailyBonusService();
      final missions = await service.loadMissions();

      expect(missions.length, DailyMissionType.values.length);
      expect(missions.every((m) => m.currentCount == 0), isTrue);
    });

    test('recordProgress increments and clamps to target count', () async {
      final service = DailyBonusService();
      await service.recordProgress(DailyMissionType.winMatch, 1);
      final missions = await service.recordProgress(
        DailyMissionType.winMatch,
        5,
      );

      final winMission =
          missions.firstWhere((m) => m.type == DailyMissionType.winMatch);
      expect(winMission.currentCount, DailyMissionType.winMatch.targetCount);
      expect(winMission.isComplete, isTrue);
    });

    test('claimMissionReward only marks claimed once mission is complete', () async {
      final service = DailyBonusService();

      final beforeComplete =
          await service.claimMissionReward(DailyMissionType.playMatches);
      expect(
        beforeComplete
            .firstWhere((m) => m.type == DailyMissionType.playMatches)
            .rewardClaimed,
        isFalse,
      );

      await service.recordProgress(DailyMissionType.playMatches, 1);
      final afterComplete =
          await service.claimMissionReward(DailyMissionType.playMatches);
      expect(
        afterComplete
            .firstWhere((m) => m.type == DailyMissionType.playMatches)
            .rewardClaimed,
        isTrue,
      );
    });
  });
}
