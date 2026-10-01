import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/weekly_challenge.dart';

/// Persists and evaluates weekly challenges, the same way
/// [DailyBonusService] handles daily missions but reset on ISO week
/// boundaries instead of calendar days — a longer-horizon goal to
/// complement the daily loop.
class WeeklyChallengeService {
  static const _challengesKey = 'weekly_challenge_state';
  static const _challengesWeekKey = 'weekly_challenge_week';

  String weekKey([DateTime? now]) => computeWeekKey(now ?? DateTime.now());

  Future<List<WeeklyChallengeProgress>> loadChallenges() async {
    final prefs = await SharedPreferences.getInstance();
    final storedWeek = prefs.getString(_challengesWeekKey);
    final thisWeek = weekKey();

    if (storedWeek != thisWeek) {
      // New week: reset challenges.
      final fresh = WeeklyChallengeType.values
          .map((t) => WeeklyChallengeProgress(type: t, currentCount: 0))
          .toList();
      await _saveChallenges(fresh, thisWeek);
      return fresh;
    }

    final raw = prefs.getString(_challengesKey);
    if (raw == null) {
      return WeeklyChallengeType.values
          .map((t) => WeeklyChallengeProgress(type: t, currentCount: 0))
          .toList();
    }

    return (jsonDecode(raw) as List)
        .map((c) =>
            WeeklyChallengeProgress.fromMap(c as Map<String, dynamic>))
        .toList();
  }

  Future<void> _saveChallenges(
    List<WeeklyChallengeProgress> challenges,
    String weekKey,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _challengesKey,
      jsonEncode(challenges.map((c) => c.toMap()).toList()),
    );
    await prefs.setString(_challengesWeekKey, weekKey);
  }

  /// Increments progress for [type] by [amount], persisting the result.
  Future<List<WeeklyChallengeProgress>> recordProgress(
    WeeklyChallengeType type,
    int amount,
  ) async {
    final challenges = await loadChallenges();
    final updated = challenges.map((c) {
      if (c.type != type) return c;
      final newCount = (c.currentCount + amount).clamp(0, c.type.targetCount);
      return c.copyWith(currentCount: newCount);
    }).toList();
    await _saveChallenges(updated, weekKey());
    return updated;
  }

  /// Marks a completed challenge's reward as claimed.
  Future<List<WeeklyChallengeProgress>> claimReward(
    WeeklyChallengeType type,
  ) async {
    final challenges = await loadChallenges();
    final updated = challenges.map((c) {
      if (c.type != type || !c.isComplete || c.rewardClaimed) return c;
      return c.copyWith(rewardClaimed: true);
    }).toList();
    await _saveChallenges(updated, weekKey());
    return updated;
  }
}
