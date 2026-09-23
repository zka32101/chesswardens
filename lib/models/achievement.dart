/// Achievement definitions ("実績"). Each achievement tracks progress
/// toward a [targetValue] measured against a specific stat in
/// [AchievementStats] (or the number of unlocked wardens).
enum AchievementId {
  firstWin('初勝利', '対局に1回勝利する', 1),
  fiveWins('五段', '対局に5回勝利する', 5),
  tenWins('十段', '対局に10回勝利する', 10),
  winStreak3('三連勝', '3連勝を達成する', 3),
  winStreak5('五連勝', '5連勝を達成する', 5),
  skillMaster('スキルマスター', 'スキルを合計10回発動する', 10),
  matches10('対局10回', '対局を合計10回プレイする', 10),
  matches50('対局50回', '対局を合計50回プレイする', 50),
  allWardensCollected('ワーデン図鑑コンプリート', 'すべてのワーデンを解放する', 7);

  final String title;
  final String description;
  final int targetValue;

  const AchievementId(this.title, this.description, this.targetValue);

  /// EXP reward granted the first time this achievement is unlocked.
  int get expReward => targetValue * 20;
}

/// Cumulative, per-device stats used to evaluate achievement progress.
/// Persisted via SharedPreferences, consistent with [DailyBonusState].
class AchievementStats {
  final int totalMatches;
  final int totalWins;
  final int totalSkillTriggers;
  final int currentWinStreak;
  final int bestWinStreak;

  const AchievementStats({
    this.totalMatches = 0,
    this.totalWins = 0,
    this.totalSkillTriggers = 0,
    this.currentWinStreak = 0,
    this.bestWinStreak = 0,
  });

  /// Progress value for [id] given these stats and the number of
  /// wardens the player currently has unlocked.
  int progressFor(AchievementId id, {int wardensUnlockedCount = 0}) {
    switch (id) {
      case AchievementId.firstWin:
      case AchievementId.fiveWins:
      case AchievementId.tenWins:
        return totalWins;
      case AchievementId.winStreak3:
      case AchievementId.winStreak5:
        return bestWinStreak;
      case AchievementId.skillMaster:
        return totalSkillTriggers;
      case AchievementId.matches10:
      case AchievementId.matches50:
        return totalMatches;
      case AchievementId.allWardensCollected:
        return wardensUnlockedCount;
    }
  }

  bool isUnlocked(AchievementId id, {int wardensUnlockedCount = 0}) {
    return progressFor(id, wardensUnlockedCount: wardensUnlockedCount) >=
        id.targetValue;
  }

  AchievementStats copyWith({
    int? totalMatches,
    int? totalWins,
    int? totalSkillTriggers,
    int? currentWinStreak,
    int? bestWinStreak,
  }) {
    return AchievementStats(
      totalMatches: totalMatches ?? this.totalMatches,
      totalWins: totalWins ?? this.totalWins,
      totalSkillTriggers: totalSkillTriggers ?? this.totalSkillTriggers,
      currentWinStreak: currentWinStreak ?? this.currentWinStreak,
      bestWinStreak: bestWinStreak ?? this.bestWinStreak,
    );
  }

  /// Returns updated stats after recording one match's outcome.
  AchievementStats recordMatch({
    required bool didWin,
    required int skillTriggeredCount,
  }) {
    final newStreak = didWin ? currentWinStreak + 1 : 0;
    return copyWith(
      totalMatches: totalMatches + 1,
      totalWins: didWin ? totalWins + 1 : totalWins,
      totalSkillTriggers: totalSkillTriggers + skillTriggeredCount,
      currentWinStreak: newStreak,
      bestWinStreak: newStreak > bestWinStreak ? newStreak : bestWinStreak,
    );
  }

  Map<String, dynamic> toMap() => {
        'totalMatches': totalMatches,
        'totalWins': totalWins,
        'totalSkillTriggers': totalSkillTriggers,
        'currentWinStreak': currentWinStreak,
        'bestWinStreak': bestWinStreak,
      };

  factory AchievementStats.fromMap(Map<String, dynamic> map) {
    return AchievementStats(
      totalMatches: map['totalMatches'] ?? 0,
      totalWins: map['totalWins'] ?? 0,
      totalSkillTriggers: map['totalSkillTriggers'] ?? 0,
      currentWinStreak: map['currentWinStreak'] ?? 0,
      bestWinStreak: map['bestWinStreak'] ?? 0,
    );
  }

  static const initial = AchievementStats();
}

/// Returns the set of achievement ids satisfied by [stats] given the
/// current number of unlocked wardens. Pure function, independent of
/// persistence, so it's straightforward to unit test.
Set<AchievementId> evaluateUnlockedAchievements(
  AchievementStats stats, {
  int wardensUnlockedCount = 0,
}) {
  return AchievementId.values
      .where((id) => stats.isUnlocked(
            id,
            wardensUnlockedCount: wardensUnlockedCount,
          ))
      .toSet();
}
