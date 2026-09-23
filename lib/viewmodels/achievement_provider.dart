import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/achievement.dart';
import '../services/achievement_service.dart';
import 'warden_provider.dart';

final achievementServiceProvider = Provider<AchievementService>((ref) {
  return AchievementService();
});

/// Number of wardens the player currently has unlocked (used to evaluate
/// the "全ワーデン解放" achievement).
final wardensUnlockedCountProvider = Provider<int>((ref) {
  return ref.watch(userWardensProvider).valueOrNull?.length ?? 0;
});

class AchievementState {
  final AchievementStats stats;
  final Set<AchievementId> unlockedIds;

  const AchievementState({
    required this.stats,
    required this.unlockedIds,
  });

  static const initial = AchievementState(
    stats: AchievementStats.initial,
    unlockedIds: {},
  );
}

/// Tracks cumulative achievement stats and which achievements are
/// unlocked. Call [recordMatch] after each match to update progress.
class AchievementNotifier extends StateNotifier<AsyncValue<AchievementState>> {
  final AchievementService _service;

  AchievementNotifier(this._service) : super(const AsyncValue.loading()) {
    _load();
  }

  Future<void> _load() async {
    state = const AsyncValue.loading();
    try {
      final stats = await _service.loadStats();
      final unlockedIds = await _service.loadUnlockedIds();
      state = AsyncValue.data(
        AchievementState(stats: stats, unlockedIds: unlockedIds),
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Records a match outcome and returns the set of achievements newly
  /// unlocked by this match (empty if none).
  Future<Set<AchievementId>> recordMatch({
    required bool didWin,
    required int skillTriggeredCount,
    int wardensUnlockedCount = 0,
  }) async {
    final (stats, newlyUnlocked) = await _service.recordMatch(
      didWin: didWin,
      skillTriggeredCount: skillTriggeredCount,
      wardensUnlockedCount: wardensUnlockedCount,
    );
    final unlockedIds = await _service.loadUnlockedIds();
    state = AsyncValue.data(
      AchievementState(stats: stats, unlockedIds: unlockedIds),
    );
    return newlyUnlocked;
  }

  /// Re-evaluates achievements against the current warden count without
  /// recording a match (e.g. right after unlocking a new warden).
  Future<Set<AchievementId>> refreshWithWardenCount(
    int wardensUnlockedCount,
  ) async {
    final (stats, newlyUnlocked) = await _service.refreshWithWardenCount(
      wardensUnlockedCount,
    );
    final unlockedIds = await _service.loadUnlockedIds();
    state = AsyncValue.data(
      AchievementState(stats: stats, unlockedIds: unlockedIds),
    );
    return newlyUnlocked;
  }
}

final achievementProvider =
    StateNotifierProvider<AchievementNotifier, AsyncValue<AchievementState>>(
  (ref) => AchievementNotifier(ref.watch(achievementServiceProvider)),
);
