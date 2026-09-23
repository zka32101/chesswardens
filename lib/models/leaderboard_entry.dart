/// A single row in the global leaderboard, aggregating one user's
/// cumulative match stats (client-computed and synced to Firestore,
/// consistent with how [MatchLog] and warden progress are stored today).
class LeaderboardEntry {
  final String uid;
  final int totalWins;
  final int totalMatches;
  final int bestWinStreak;
  final DateTime updatedAt;

  const LeaderboardEntry({
    required this.uid,
    required this.totalWins,
    required this.totalMatches,
    required this.bestWinStreak,
    required this.updatedAt,
  });

  double get winRate => totalMatches == 0 ? 0.0 : totalWins / totalMatches;

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'totalWins': totalWins,
        'totalMatches': totalMatches,
        'bestWinStreak': bestWinStreak,
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory LeaderboardEntry.fromMap(Map<String, dynamic> map) {
    return LeaderboardEntry(
      uid: map['uid'],
      totalWins: map['totalWins'] ?? 0,
      totalMatches: map['totalMatches'] ?? 0,
      bestWinStreak: map['bestWinStreak'] ?? 0,
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'])
          : DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

/// Computes (totalWins, totalMatches, bestWinStreak) from a list of match
/// results, in chronological order (oldest first). Pure function so the
/// win-streak logic can be unit tested without touching Firestore.
(int, int, int) computeLeaderboardStats(List<bool> didWinInOrder) {
  var wins = 0;
  var currentStreak = 0;
  var bestStreak = 0;

  for (final didWin in didWinInOrder) {
    if (didWin) {
      wins++;
      currentStreak++;
      if (currentStreak > bestStreak) bestStreak = currentStreak;
    } else {
      currentStreak = 0;
    }
  }

  return (wins, didWinInOrder.length, bestStreak);
}

/// Ranks entries by total wins (descending), breaking ties by win rate
/// then best win streak, so a new player with a lucky single win doesn't
/// outrank a consistent top player.
List<LeaderboardEntry> rankLeaderboardEntries(List<LeaderboardEntry> entries) {
  final sorted = [...entries];
  sorted.sort((a, b) {
    final byWins = b.totalWins.compareTo(a.totalWins);
    if (byWins != 0) return byWins;
    final byWinRate = b.winRate.compareTo(a.winRate);
    if (byWinRate != 0) return byWinRate;
    return b.bestWinStreak.compareTo(a.bestWinStreak);
  });
  return sorted;
}
