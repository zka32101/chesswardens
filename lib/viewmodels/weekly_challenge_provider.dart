import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/weekly_challenge.dart';
import '../services/weekly_challenge_service.dart';

final weeklyChallengeServiceProvider = Provider<WeeklyChallengeService>((ref) {
  return WeeklyChallengeService();
});

/// This week's challenge progress list.
class WeeklyChallengesNotifier
    extends StateNotifier<AsyncValue<List<WeeklyChallengeProgress>>> {
  final WeeklyChallengeService _service;

  WeeklyChallengesNotifier(this._service) : super(const AsyncValue.loading()) {
    _load();
  }

  Future<void> _load() async {
    state = const AsyncValue.loading();
    try {
      final challenges = await _service.loadChallenges();
      state = AsyncValue.data(challenges);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> recordProgress(WeeklyChallengeType type, [int amount = 1]) async {
    final updated = await _service.recordProgress(type, amount);
    state = AsyncValue.data(updated);
  }

  /// Claims a completed challenge's reward and returns the EXP granted
  /// (0 if the challenge wasn't complete or was already claimed).
  Future<int> claimReward(WeeklyChallengeType type) async {
    final current = state.valueOrNull ?? [];
    final matches = current.where((c) => c.type == type);
    if (matches.isEmpty) return 0;
    final challenge = matches.first;
    if (!challenge.isComplete || challenge.rewardClaimed) {
      return 0;
    }

    final updated = await _service.claimReward(type);
    state = AsyncValue.data(updated);
    return WeeklyChallengeProgress.expReward;
  }
}

final weeklyChallengesProvider = StateNotifierProvider<WeeklyChallengesNotifier,
    AsyncValue<List<WeeklyChallengeProgress>>>(
  (ref) => WeeklyChallengesNotifier(ref.watch(weeklyChallengeServiceProvider)),
);
