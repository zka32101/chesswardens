import 'package:flutter_test/flutter_test.dart';
import 'package:chesswardens/models/index.dart';
import 'package:chesswardens/services/chess_engine_service.dart';
import 'package:chesswardens/viewmodels/game_state_provider.dart';

void main() {
  late GameStateNotifier notifier;

  setUp(() async {
    notifier = GameStateNotifier();
    await notifier.startNewMatch(AIDifficulty.easy, ['w1'], ['a1']);
  });

  group('hints', () {
    test('useHint returns a legal move without mutating the board', () {
      final boardBefore = notifier.state!.board.squares.map((p) => p?.type).toList();

      final hint = notifier.useHint();

      expect(hint, isNotNull);
      final legalMoves = ChessEngineService(
        initialBoard: Board.copy(notifier.state!.board),
      ).generateLegalMoves(true);
      expect(legalMoves, contains(hint));

      final boardAfter = notifier.state!.board.squares.map((p) => p?.type).toList();
      expect(boardAfter, boardBefore);
    });

    test('consumes one hint per call and stops at zero', () {
      expect(notifier.state!.hintsRemaining, GameStateNotifier.maxHintsPerMatch);

      for (var i = 0; i < GameStateNotifier.maxHintsPerMatch; i++) {
        expect(notifier.useHint(), isNotNull);
      }

      expect(notifier.state!.hintsRemaining, 0);
      expect(notifier.useHint(), isNull);
    });

    test('returns null when it is not the player\'s turn', () async {
      await notifier.makePlayerMove(Move(from: 12, to: 28)); // e2-e4 style
      expect(notifier.state!.isPlayerTurn, false);

      expect(notifier.useHint(), isNull);
    });
  });

  group('undo', () {
    test('does nothing before any moves are made', () {
      expect(notifier.undoLastExchange(), false);
    });

    test('rewinds one full exchange back to the player\'s turn', () async {
      await notifier.makePlayerMove(Move(from: 12, to: 28));
      await notifier.makeAIMove();
      expect(notifier.state!.moveHistory.length, 2);
      expect(notifier.state!.isPlayerTurn, true);

      final undone = notifier.undoLastExchange();

      expect(undone, true);
      expect(notifier.state!.moveHistory, isEmpty);
      expect(notifier.state!.isPlayerTurn, true);
      expect(notifier.state!.undosRemaining, GameStateNotifier.maxUndosPerMatch - 1);
    });

    test('is capped at maxUndosPerMatch', () async {
      for (var i = 0; i < GameStateNotifier.maxUndosPerMatch; i++) {
        await notifier.makePlayerMove(Move(from: 12, to: 28));
        await notifier.makeAIMove();
        expect(notifier.undoLastExchange(), true);
      }

      expect(notifier.state!.undosRemaining, 0);
      // One more exchange, then a further undo attempt should be refused.
      await notifier.makePlayerMove(Move(from: 12, to: 28));
      await notifier.makeAIMove();
      expect(notifier.undoLastExchange(), false);
    });
  });
}
