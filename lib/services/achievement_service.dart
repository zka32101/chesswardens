import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/achievement.dart';

/// Persists cumulative achievement stats and which achievements have
/// already been unlocked (per-device, SharedPreferences-backed —
/// consistent with [DailyBonusService]).
class AchievementService {
  static const _statsKey = 'achievement_stats';
  static const _unlockedKey = 'achievement_unlocked_ids';

  Future<AchievementStats> loadStats() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_statsKey);
    if (raw == null) return AchievementStats.initial;
    return AchievementStats.fromMap(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> _saveStats(AchievementStats stats) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_statsKey, jsonEncode(stats.toMap()));
  }

  Future<Set<AchievementId>> loadUnlockedIds() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_unlockedKey) ?? [];
    return list
        .map((name) => AchievementId.values
            .where((v) => v.name == name)
            .cast<AchievementId?>()
            .firstWhere((v) => v != null, orElse: () => null))
        .whereType<AchievementId>()
        .toSet();
  }

  Future<void> _saveUnlockedIds(Set<AchievementId> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _unlockedKey,
      ids.map((id) => id.name).toList(),
    );
  }

  /// Records the outcome of one match, then re-evaluates achievements.
  /// Returns the newly-unlocked achievements (empty if none), along with
  /// the updated stats.
  Future<(AchievementStats, Set<AchievementId>)> recordMatch({
    required bool didWin,
    required int skillTriggeredCount,
    int wardensUnlockedCount = 0,
  }) async {
    final stats = await loadStats();
    final updatedStats = stats.recordMatch(
      didWin: didWin,
      skillTriggeredCount: skillTriggeredCount,
    );
    await _saveStats(updatedStats);

    return _evaluateAndPersist(updatedStats, wardensUnlockedCount);
  }

  /// Re-evaluates achievements against the current wardens-unlocked count
  /// without recording a match (e.g. after unlocking a new warden).
  Future<(AchievementStats, Set<AchievementId>)> refreshWithWardenCount(
    int wardensUnlockedCount,
  ) async {
    final stats = await loadStats();
    return _evaluateAndPersist(stats, wardensUnlockedCount);
  }

  Future<(AchievementStats, Set<AchievementId>)> _evaluateAndPersist(
    AchievementStats stats,
    int wardensUnlockedCount,
  ) async {
    final previouslyUnlocked = await loadUnlockedIds();
    final nowUnlocked = evaluateUnlockedAchievements(
      stats,
      wardensUnlockedCount: wardensUnlockedCount,
    );
    final newlyUnlocked = nowUnlocked.difference(previouslyUnlocked);

    if (nowUnlocked.length != previouslyUnlocked.length) {
      await _saveUnlockedIds(nowUnlocked);
    }

    return (stats, newlyUnlocked);
  }
}
