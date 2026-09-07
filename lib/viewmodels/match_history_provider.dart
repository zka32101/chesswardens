import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/index.dart';
import '../services/index.dart';
import 'auth_provider.dart';

/// Match history provider (Firestore)
final matchHistoryProvider = FutureProvider<List<MatchLog>>((ref) async {
  final uid = ref.watch(userIdProvider);
  if (uid == null) return [];

  final firestoreService = FirestoreService();
  return firestoreService.getRecentMatchLogs(uid, limit: 50);
});

/// Match history notifier
class MatchHistoryNotifier extends StateNotifier<List<MatchLog>> {
  final FirestoreService _firestoreService = FirestoreService();
  final String uid;

  MatchHistoryNotifier(this.uid, this.state);

  /// Add a new match to history
  Future<String> recordMatch(
    AIDifficulty difficulty,
    MatchResult result,
    int skillTriggeredCount,
    int playerScore,
    int aiScore,
    int movesPlayed,
  ) async {
    final matchId = await _firestoreService.addMatchLog(
      uid,
      difficulty,
      result,
      skillTriggeredCount,
      playerScore,
      aiScore,
      movesPlayed,
    );

    // Add to local state
    final matchLog = MatchLog(
      id: matchId,
      uid: uid,
      aiDifficulty: difficulty,
      result: result,
      skillTriggeredCount: skillTriggeredCount,
      playerScore: playerScore,
      aiScore: aiScore,
      movesPlayed: movesPlayed,
      playedAt: DateTime.now(),
    );

    state = [matchLog, ...state];

    return matchId;
  }

  /// Get match by ID
  MatchLog? getMatchById(String matchId) {
    try {
      return state.firstWhere((m) => m.id == matchId);
    } catch (_) {
      return null;
    }
  }
}

/// Get match history notifier
final matchHistoryNotifierProvider =
    StateNotifierProvider.family<MatchHistoryNotifier, List<MatchLog>, String?>(
  (ref, uid) {
    final matches = ref.watch(matchHistoryProvider);
    return MatchHistoryNotifier(uid ?? '', matches.valueOrNull ?? []);
  },
);

/// Win rate calculation
final winRateProvider = Provider<double>((ref) {
  final matches = ref.watch(matchHistoryProvider).valueOrNull ?? [];
  if (matches.isEmpty) return 0.0;

  final wins = matches.where((m) => m.result == MatchResult.win).length;
  return wins / matches.length;
});

/// Average skill triggers
final averageSkillTriggersProvider = Provider<double>((ref) {
  final matches = ref.watch(matchHistoryProvider).valueOrNull ?? [];
  if (matches.isEmpty) return 0.0;

  final total = matches.fold<int>(0, (sum, m) => sum + m.skillTriggeredCount);
  return total / matches.length;
});
