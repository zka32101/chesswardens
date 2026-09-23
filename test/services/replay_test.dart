import 'package:flutter_test/flutter_test.dart';
import 'package:chesswardens/models/index.dart';
import 'package:chesswardens/services/chess_engine_service.dart';

void main() {
  group('Move serialization (for replay persistence)', () {
    test('round-trips a plain move', () {
      final move = Move(from: 8, to: 16);
      final restored = Move.fromMap(move.toMap());

      expect(restored.from, move.from);
      expect(restored.to, move.to);
      expect(restored.promotion, isNull);
      expect(restored.isCapture, isFalse);
    });

    test('round-trips a capturing promotion move', () {
      final move = Move(
        from: 52,
        to: 61,
        promotion: PieceType.queen,
        isCapture: true,
      );
      final restored = Move.fromMap(move.toMap());

      expect(restored.promotion, PieceType.queen);
      expect(restored.isCapture, isTrue);
    });
  });

  group('MatchLog replay data', () {
    test('hasReplay is false when no moves are recorded', () {
      final log = MatchLog(
        id: '1',
        uid: 'u1',
        aiDifficulty: AIDifficulty.normal,
        result: MatchResult.win,
        skillTriggeredCount: 0,
        playerScore: 1,
        aiScore: 0,
        movesPlayed: 0,
        playedAt: DateTime(2026, 1, 1),
      );
      expect(log.hasReplay, isFalse);
    });

    test('round-trips moves through toMap/fromMap', () {
      final log = MatchLog(
        id: '1',
        uid: 'u1',
        aiDifficulty: AIDifficulty.normal,
        result: MatchResult.win,
        skillTriggeredCount: 1,
        playerScore: 1,
        aiScore: 0,
        movesPlayed: 2,
        playedAt: DateTime(2026, 1, 1),
        moves: [
          Move(from: 8, to: 16),
          Move(from: 48, to: 32, isCapture: true),
        ],
      );

      final restored = MatchLog.fromMap(log.toMap());
      expect(restored.hasReplay, isTrue);
      expect(restored.moves.length, 2);
      expect(restored.moves[1].isCapture, isTrue);
    });
  });

  group('Replay board reconstruction', () {
    test('replaying recorded moves reproduces the same board state', () {
      final board = Board();
      final moves = [
        Move(from: 12, to: 28), // e2-e4 equivalent in this indexing
        Move(from: 52, to: 36),
      ];

      for (final m in moves) {
        board.makeMove(m);
      }

      // Rebuild from scratch using the same recorded moves.
      final replayBoard = Board();
      for (final m in moves) {
        replayBoard.makeMove(m);
      }

      for (var i = 0; i < 64; i++) {
        expect(replayBoard.getPiece(i)?.type, board.getPiece(i)?.type);
        expect(replayBoard.getPiece(i)?.isWhite, board.getPiece(i)?.isWhite);
      }
    });
  });
}
