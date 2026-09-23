import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/daily_bonus.dart';
import '../services/daily_bonus_service.dart';

final dailyBonusServiceProvider = Provider<DailyBonusService>((ref) {
  return DailyBonusService();
});

/// Current daily login bonus streak state.
class DailyBonusNotifier extends StateNotifier<AsyncValue<DailyBonusState>> {
  final DailyBonusService _service;

  DailyBonusNotifier(this._service) : super(const AsyncValue.loading()) {
    _load();
  }

  Future<void> _load() async {
    state = const AsyncValue.loading();
    try {
      final loaded = await _service.loadBonusState();
      state = AsyncValue.data(loaded);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  bool get canClaimToday {
    final value = state.valueOrNull;
    if (value == null) return false;
    return !value.hasClaimedOn(_service.todayKey());
  }

  /// Claims today's bonus and returns the EXP reward granted (0 if
  /// already claimed).
  Future<int> claim() async {
    final (updated, expReward) = await _service.claimToday();
    state = AsyncValue.data(updated);
    return expReward;
  }
}

final dailyBonusProvider =
    StateNotifierProvider<DailyBonusNotifier, AsyncValue<DailyBonusState>>(
  (ref) => DailyBonusNotifier(ref.watch(dailyBonusServiceProvider)),
);

/// Today's daily mission progress list.
class DailyMissionsNotifier
    extends StateNotifier<AsyncValue<List<DailyMissionProgress>>> {
  final DailyBonusService _service;

  DailyMissionsNotifier(this._service) : super(const AsyncValue.loading()) {
    _load();
  }

  Future<void> _load() async {
    state = const AsyncValue.loading();
    try {
      final missions = await _service.loadMissions();
      state = AsyncValue.data(missions);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> recordProgress(DailyMissionType type, [int amount = 1]) async {
    final updated = await _service.recordProgress(type, amount);
    state = AsyncValue.data(updated);
  }

  /// Claims a completed mission's reward and returns the EXP granted
  /// (0 if the mission wasn't complete or was already claimed).
  Future<int> claimReward(DailyMissionType type) async {
    final current = state.valueOrNull ?? [];
    final matches = current.where((m) => m.type == type);
    if (matches.isEmpty) return 0;
    final mission = matches.first;
    if (!mission.isComplete || mission.rewardClaimed) {
      return 0;
    }

    final updated = await _service.claimMissionReward(type);
    state = AsyncValue.data(updated);
    return DailyMissionProgress.expReward;
  }
}

final dailyMissionsProvider = StateNotifierProvider<DailyMissionsNotifier,
    AsyncValue<List<DailyMissionProgress>>>(
  (ref) => DailyMissionsNotifier(ref.watch(dailyBonusServiceProvider)),
);
