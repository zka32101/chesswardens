import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/daily_bonus.dart';

/// Persists and evaluates the daily login bonus streak and daily missions.
///
/// State lives in SharedPreferences (per-device) rather than Firestore:
/// losing a streak on reinstall is an acceptable tradeoff for the low
/// implementation cost, consistent with how onboarding completion is
/// already tracked in this app.
class DailyBonusService {
  static const _bonusKey = 'daily_bonus_state';
  static const _missionsKey = 'daily_missions_state';
  static const _missionsDateKey = 'daily_missions_date';

  String todayKey([DateTime? now]) {
    final d = now ?? DateTime.now();
    return '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  String _yesterdayKey([DateTime? now]) {
    final d = (now ?? DateTime.now()).subtract(const Duration(days: 1));
    return todayKey(d);
  }

  Future<DailyBonusState> loadBonusState() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_bonusKey);
    if (raw == null) return DailyBonusState.initial();
    return DailyBonusState.fromMap(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> _saveBonusState(DailyBonusState state) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_bonusKey, jsonEncode(state.toMap()));
  }

  /// Returns true if today's bonus has not yet been claimed.
  Future<bool> canClaimToday() async {
    final state = await loadBonusState();
    return !state.hasClaimedOn(todayKey());
  }

  /// Claims today's bonus, advancing (or resetting) the consecutive-day
  /// streak, and returns the updated state plus the EXP reward granted.
  Future<(DailyBonusState, int)> claimToday() async {
    final state = await loadBonusState();
    final today = todayKey();

    if (state.hasClaimedOn(today)) {
      return (state, 0);
    }

    final continuesStreak = state.lastClaimedDate == _yesterdayKey();
    final newStreakDay =
        continuesStreak ? (state.consecutiveDays % 7) + 1 : 1;

    final updated = state.copyWith(
      consecutiveDays: newStreakDay,
      lastClaimedDate: today,
    );
    await _saveBonusState(updated);

    return (updated, DailyBonusState.expRewardForDay(newStreakDay));
  }

  Future<List<DailyMissionProgress>> loadMissions() async {
    final prefs = await SharedPreferences.getInstance();
    final storedDate = prefs.getString(_missionsDateKey);
    final today = todayKey();

    if (storedDate != today) {
      // New day: reset missions.
      final fresh = DailyMissionType.values
          .map((t) => DailyMissionProgress(type: t, currentCount: 0))
          .toList();
      await _saveMissions(fresh, today);
      return fresh;
    }

    final raw = prefs.getString(_missionsKey);
    if (raw == null) {
      return DailyMissionType.values
          .map((t) => DailyMissionProgress(type: t, currentCount: 0))
          .toList();
    }

    final list = (jsonDecode(raw) as List)
        .map((m) => DailyMissionProgress.fromMap(m as Map<String, dynamic>))
        .toList();
    return list;
  }

  Future<void> _saveMissions(
    List<DailyMissionProgress> missions,
    String dateKey,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _missionsKey,
      jsonEncode(missions.map((m) => m.toMap()).toList()),
    );
    await prefs.setString(_missionsDateKey, dateKey);
  }

  /// Increments progress for [type] by [amount], persisting the result.
  Future<List<DailyMissionProgress>> recordProgress(
    DailyMissionType type,
    int amount,
  ) async {
    final missions = await loadMissions();
    final updated = missions.map((m) {
      if (m.type != type) return m;
      final newCount = (m.currentCount + amount).clamp(0, m.type.targetCount);
      return m.copyWith(currentCount: newCount);
    }).toList();
    await _saveMissions(updated, todayKey());
    return updated;
  }

  /// Marks a completed mission's reward as claimed.
  Future<List<DailyMissionProgress>> claimMissionReward(
    DailyMissionType type,
  ) async {
    final missions = await loadMissions();
    final updated = missions.map((m) {
      if (m.type != type || !m.isComplete || m.rewardClaimed) return m;
      return m.copyWith(rewardClaimed: true);
    }).toList();
    await _saveMissions(updated, todayKey());
    return updated;
  }
}
