import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/leaderboard_entry.dart';
import '../services/firestore_service.dart';

final _firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});

/// Streams the top leaderboard entries, ranked by wins (see
/// [rankLeaderboardEntries]).
final leaderboardProvider = StreamProvider<List<LeaderboardEntry>>((ref) {
  return ref
      .watch(_firestoreServiceProvider)
      .streamTopLeaderboard()
      .map(rankLeaderboardEntries);
});

/// Publishes the caller's latest cumulative stats to the leaderboard.
class LeaderboardNotifier {
  final FirestoreService _service;

  LeaderboardNotifier(this._service);

  Future<void> submitStats({
    required String uid,
    required int totalWins,
    required int totalMatches,
    required int bestWinStreak,
  }) async {
    await _service.upsertLeaderboardEntry(
      LeaderboardEntry(
        uid: uid,
        totalWins: totalWins,
        totalMatches: totalMatches,
        bestWinStreak: bestWinStreak,
        updatedAt: DateTime.now(),
      ),
    );
  }
}

final leaderboardNotifierProvider = Provider<LeaderboardNotifier>((ref) {
  return LeaderboardNotifier(ref.watch(_firestoreServiceProvider));
});
