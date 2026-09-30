import 'package:flutter_test/flutter_test.dart';
import 'package:chesswardens/models/index.dart';
import 'package:chesswardens/services/chess_engine_service.dart' show Move;

void main() {
  group('MatchLog as a spectate share payload', () {
    test('fromMap tolerates the extra "code" field added when sharing', () {
      final original = MatchLog(
        id: 'match1',
        uid: 'user1',
        aiDifficulty: AIDifficulty.hard,
        result: MatchResult.win,
        skillTriggeredCount: 2,
        playerScore: 10,
        aiScore: 8,
        movesPlayed: 4,
        playedAt: DateTime(2026, 1, 1),
        moves: [Move(from: 12, to: 28), Move(from: 52, to: 36)],
      );

      // createSpectateShare stores matchLog.toMap() plus a 'code' key.
      final shared = {...original.toMap(), 'code': 'ABC123'};
      final restored = MatchLog.fromMap(shared);

      expect(restored.uid, original.uid);
      expect(restored.result, original.result);
      expect(restored.moves.length, original.moves.length);
      expect(restored.hasReplay, true);
    });
  });
}
