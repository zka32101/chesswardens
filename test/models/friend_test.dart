import 'package:flutter_test/flutter_test.dart';
import 'package:chesswardens/models/friend.dart';
import 'package:chesswardens/models/leaderboard_entry.dart';

LeaderboardEntry _entry(String uid) => LeaderboardEntry(
      uid: uid,
      totalWins: 1,
      totalMatches: 1,
      bestWinStreak: 1,
      updatedAt: DateTime(2026, 1, 1),
    );

void main() {
  group('Friend', () {
    test('toMap/fromMap round-trips', () {
      final friend = Friend(uid: 'friend1', addedAt: DateTime(2026, 3, 1));
      final restored = Friend.fromMap(friend.toMap());

      expect(restored.uid, friend.uid);
      expect(restored.addedAt, friend.addedAt);
    });
  });

  group('filterToUids', () {
    test('keeps only entries whose uid is allowed', () {
      final entries = [_entry('a'), _entry('b'), _entry('c')];

      final filtered = filterToUids(entries, {'a', 'c'});

      expect(filtered.map((e) => e.uid).toSet(), {'a', 'c'});
    });

    test('returns an empty list when nothing matches', () {
      final entries = [_entry('a')];
      expect(filterToUids(entries, {'z'}), isEmpty);
    });

    test('returns everything when all uids are allowed', () {
      final entries = [_entry('a'), _entry('b')];
      final filtered = filterToUids(entries, {'a', 'b'});
      expect(filtered.length, 2);
    });
  });
}
