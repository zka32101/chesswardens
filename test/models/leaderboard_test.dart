import 'package:flutter_test/flutter_test.dart';
import 'package:chesswardens/models/leaderboard_entry.dart';

LeaderboardEntry _entry({
  required String uid,
  int wins = 0,
  int matches = 0,
  int streak = 0,
}) {
  return LeaderboardEntry(
    uid: uid,
    totalWins: wins,
    totalMatches: matches,
    bestWinStreak: streak,
    updatedAt: DateTime(2026, 1, 1),
  );
}

void main() {
  group('LeaderboardEntry', () {
    test('winRate is zero when no matches played', () {
      final entry = _entry(uid: 'u1');
      expect(entry.winRate, 0.0);
    });

    test('winRate divides wins by matches', () {
      final entry = _entry(uid: 'u1', wins: 3, matches: 4);
      expect(entry.winRate, 0.75);
    });

    test('toMap/fromMap round trip preserves values', () {
      final entry = _entry(uid: 'u1', wins: 5, matches: 10, streak: 3);
      final restored = LeaderboardEntry.fromMap(entry.toMap());

      expect(restored.uid, entry.uid);
      expect(restored.totalWins, entry.totalWins);
      expect(restored.totalMatches, entry.totalMatches);
      expect(restored.bestWinStreak, entry.bestWinStreak);
    });
  });

  group('computeLeaderboardStats', () {
    test('counts wins, matches, and the longest streak', () {
      final (wins, matches, bestStreak) = computeLeaderboardStats(
        [true, true, false, true, true, true, false],
      );

      expect(wins, 5);
      expect(matches, 7);
      expect(bestStreak, 3);
    });

    test('returns zeros for an empty history', () {
      final (wins, matches, bestStreak) = computeLeaderboardStats([]);
      expect(wins, 0);
      expect(matches, 0);
      expect(bestStreak, 0);
    });

    test('a streak that continues to the end counts fully', () {
      final (wins, matches, bestStreak) = computeLeaderboardStats(
        [false, true, true, true],
      );
      expect(wins, 3);
      expect(matches, 4);
      expect(bestStreak, 3);
    });
  });

  group('rankLeaderboardEntries', () {
    test('sorts by total wins descending', () {
      final entries = [
        _entry(uid: 'low', wins: 2, matches: 5),
        _entry(uid: 'high', wins: 10, matches: 12),
        _entry(uid: 'mid', wins: 5, matches: 8),
      ];

      final ranked = rankLeaderboardEntries(entries);

      expect(ranked.map((e) => e.uid).toList(), ['high', 'mid', 'low']);
    });

    test('breaks ties in total wins by win rate, then best streak', () {
      final entries = [
        _entry(uid: 'lowRate', wins: 5, matches: 20, streak: 5),
        _entry(uid: 'highRate', wins: 5, matches: 5, streak: 2),
        _entry(uid: 'sameRateLongerStreak', wins: 5, matches: 5, streak: 5),
      ];

      final ranked = rankLeaderboardEntries(entries);

      expect(
        ranked.map((e) => e.uid).toList(),
        ['sameRateLongerStreak', 'highRate', 'lowRate'],
      );
    });

    test('does not mutate the input list', () {
      final entries = [
        _entry(uid: 'a', wins: 1),
        _entry(uid: 'b', wins: 5),
      ];
      final original = [...entries];

      rankLeaderboardEntries(entries);

      expect(entries.map((e) => e.uid).toList(),
          original.map((e) => e.uid).toList());
    });
  });
}
