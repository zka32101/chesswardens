import 'package:flutter_test/flutter_test.dart';
import 'package:chesswardens/models/achievement.dart';

void main() {
  group('AchievementStats', () {
    test('recordMatch accumulates totals and win streak', () {
      var stats = AchievementStats.initial;
      stats = stats.recordMatch(didWin: true, skillTriggeredCount: 2);
      stats = stats.recordMatch(didWin: true, skillTriggeredCount: 1);
      stats = stats.recordMatch(didWin: false, skillTriggeredCount: 0);
      stats = stats.recordMatch(didWin: true, skillTriggeredCount: 3);

      expect(stats.totalMatches, 4);
      expect(stats.totalWins, 3);
      expect(stats.totalSkillTriggers, 6);
      expect(stats.currentWinStreak, 1);
      expect(stats.bestWinStreak, 2);
    });

    test('toMap/fromMap round trip preserves values', () {
      const stats = AchievementStats(
        totalMatches: 12,
        totalWins: 7,
        totalSkillTriggers: 9,
        currentWinStreak: 2,
        bestWinStreak: 5,
      );
      final restored = AchievementStats.fromMap(stats.toMap());

      expect(restored.totalMatches, stats.totalMatches);
      expect(restored.totalWins, stats.totalWins);
      expect(restored.totalSkillTriggers, stats.totalSkillTriggers);
      expect(restored.currentWinStreak, stats.currentWinStreak);
      expect(restored.bestWinStreak, stats.bestWinStreak);
    });

    test('isUnlocked reflects targetValue thresholds', () {
      const stats = AchievementStats(totalWins: 5);

      expect(stats.isUnlocked(AchievementId.firstWin), true);
      expect(stats.isUnlocked(AchievementId.fiveWins), true);
      expect(stats.isUnlocked(AchievementId.tenWins), false);
    });

    test('allWardensCollected uses wardensUnlockedCount, not stats', () {
      const stats = AchievementStats();

      expect(
        stats.isUnlocked(AchievementId.allWardensCollected,
            wardensUnlockedCount: 6),
        false,
      );
      expect(
        stats.isUnlocked(AchievementId.allWardensCollected,
            wardensUnlockedCount: 7),
        true,
      );
    });
  });

  group('evaluateUnlockedAchievements', () {
    test('returns only satisfied achievements', () {
      const stats = AchievementStats(
        totalMatches: 10,
        totalWins: 5,
        totalSkillTriggers: 10,
        bestWinStreak: 3,
      );

      final unlocked = evaluateUnlockedAchievements(
        stats,
        wardensUnlockedCount: 4,
      );

      expect(unlocked, contains(AchievementId.firstWin));
      expect(unlocked, contains(AchievementId.fiveWins));
      expect(unlocked, contains(AchievementId.winStreak3));
      expect(unlocked, contains(AchievementId.skillMaster));
      expect(unlocked, contains(AchievementId.matches10));
      expect(unlocked, isNot(contains(AchievementId.tenWins)));
      expect(unlocked, isNot(contains(AchievementId.winStreak5)));
      expect(unlocked, isNot(contains(AchievementId.allWardensCollected)));
    });
  });
}
