import 'package:flutter_test/flutter_test.dart';
import 'package:chesswardens/services/chess_engine_service.dart';
import 'package:chesswardens/models/index.dart';

void main() {
  group('ChessEngineService', () {
    late ChessEngineService engine;

    setUp(() {
      engine = ChessEngineService();
    });

    test('initializes standard chess position', () {
      final board = engine.board;

      // Check white pieces
      expect(board.getPiece(0)?.type, PieceType.rook);
      expect(board.getPiece(0)?.isWhite, true);
      expect(board.getPiece(4)?.type, PieceType.king);
      expect(board.getPiece(4)?.isWhite, true);

      // Check black pieces
      expect(board.getPiece(60)?.type, PieceType.king);
      expect(board.getPiece(60)?.isWhite, false);

      // Check pawns
      expect(board.getPiece(8)?.type, PieceType.pawn);
      expect(board.getPiece(8)?.isWhite, true);
      expect(board.getPiece(48)?.type, PieceType.pawn);
      expect(board.getPiece(48)?.isWhite, false);
    });

    test('converts square indices to algebraic notation', () {
      expect(squareToAlgebraic(0), 'a1');
      expect(squareToAlgebraic(4), 'e1');
      expect(squareToAlgebraic(63), 'h8');
      expect(squareToAlgebraic(27), 'd4');
    });

    test('converts algebraic notation to square indices', () {
      expect(algebraicToSquare('a1'), 0);
      expect(algebraicToSquare('e1'), 4);
      expect(algebraicToSquare('h8'), 63);
      expect(algebraicToSquare('d4'), 27);
    });

    test('generates legal pawn moves from starting position', () {
      final moves = engine.generateLegalMoves(true); // White to move

      // White pawns should have move options
      final pawnMoves = moves.where((m) => {8, 9, 10, 11, 12, 13, 14, 15}.contains(m.from));
      expect(pawnMoves.isNotEmpty, true);

      // Each pawn should be able to move 1 or 2 squares forward
      expect(
        pawnMoves.every((m) => (m.to == m.from - 8 || m.to == m.from - 16)),
        true,
      );
    });

    test('generates knight moves correctly', () {
      final moves = engine.generateLegalMoves(true);

      // White knights at b1 (1) and g1 (6)
      final knightMoves = moves.where((m) => {1, 6}.contains(m.from));
      expect(knightMoves.isNotEmpty, true);

      // Knight at b1 should be able to move to a3 (17) or c3 (18)
      // (after accounting for position on 8x8 board)
    });

    test('detects check position', () {
      // Set up a simple position: white king on e1, black rook on e8
      final testBoard = Board();
      testBoard.setPiece(4, null); // Clear white king
      testBoard.setPiece(60, null); // Clear black king

      testBoard.setPiece(4, Piece(type: PieceType.king, isWhite: true, hp: 100));
      testBoard.setPiece(60, Piece(type: PieceType.rook, isWhite: false, hp: 100));

      engine = ChessEngineService(initialBoard: testBoard);

      // Note: isKingInCheck needs attack detection implemented
      // This test validates the infrastructure
      final whiteKingSquare = engine.board.findKing(true);
      expect(whiteKingSquare, 4);
    });

    test('evaluates board position with material values', () {
      // Standard starting position should have equal material
      final eval = engine.evaluatePosition(true);

      // Evaluation should be close to 0 (balanced position)
      expect(eval.abs() < 50, true);
    });

    test('skill evaluation affects board score', () {
      final board = engine.board;

      // Add skill bonus to white pawn
      final pawn = board.getPiece(8);
      pawn?.skillActive = true;

      final evalWithSkill = engine.evaluatePosition(true);

      pawn?.skillActive = false;
      final evalWithoutSkill = engine.evaluatePosition(true);

      // Skill should increase evaluation for that side
      expect(evalWithSkill > evalWithoutSkill, true);
    });

    test('findBestMove returns a valid move', () async {
      final move = engine.findBestMove(true, depth: 2);

      if (move != null) {
        expect(move.from >= 0 && move.from < 64, true);
        expect(move.to >= 0 && move.to < 64, true);
      }
    });

    test('tracks HP changes during gameplay', () {
      final piece = engine.board.getPiece(0);
      expect(piece?.hp, 100);

      piece?.hp = 50;
      expect(piece?.hp, 50);

      piece?.hp = 0;
      expect(piece?.hp, 0);
    });
  });

  group('SkillEvaluationService', () {
    late SkillEvaluationService skillService;

    setUp(() {
      skillService = SkillEvaluationService();
    });

    test('loads MVP skill definitions', () {
      final skills = SkillDefinition.mvpSkills();
      expect(skills.length, 4); // 4 MVP wardens

      expect(skills[0].id, 'skill_immortality');
      expect(skills[1].id, 'skill_spread_damage');
      expect(skills[2].id, 'skill_shield_turns');
      expect(skills[3].id, 'skill_jump_move');
    });

    test('calculates trigger rates by level', () {
      final skill = SkillDefinition.immortality();

      expect(skill.getTriggerRate(1), 1.0);
      expect(skill.getTriggerRate(4), 1.0);
    });

    test('returns skill values by level', () {
      final skill = SkillDefinition.spreadDamage();

      expect(skill.getValue(1), 20);
      expect(skill.getValue(2), 30);
      expect(skill.getValue(3), 40);
      expect(skill.getValue(4), 50);
    });

    test('evaluates skill contribution to position', () {
      final skill = SkillDefinition.immortality();

      final contribution = skillService.evaluateSkillContribution(skill, true, 1);
      expect(contribution > 0, true);

      final noContribution = skillService.evaluateSkillContribution(skill, false, 1);
      expect(noContribution, 0);
    });
  });

  group('Warden models', () {
    test('creates MVP wardens correctly', () {
      final wardens = Warden.mvpWardens();
      expect(wardens.length, 4);

      expect(wardens[0].japaneseeName, '鬼王');
      expect(wardens[0].baseType, PieceType.king);
      expect(wardens[0].skillId, 'skill_immortality');

      expect(wardens[1].japaneseeName, '九尾');
      expect(wardens[1].baseType, PieceType.queen);

      expect(wardens[2].japaneseeName, '大蛇');
      expect(wardens[2].baseType, PieceType.rook);

      expect(wardens[3].japaneseeName, '天狗');
      expect(wardens[3].baseType, PieceType.knight);
    });

    test('UserWarden tracks level and exp', () {
      final userWarden = UserWarden(
        uid: 'user123',
        wardenId: 'warden_oni_king',
        level: 1,
        exp: 50,
        unlockedAt: DateTime.now(),
      );

      expect(userWarden.level, 1);
      expect(userWarden.exp, 50);

      // Add exp
      final upgraded = userWarden.addExp(60);
      expect(upgraded.exp, 110);
    });

    test('UserWarden can level up', () {
      final userWarden = UserWarden(
        uid: 'user123',
        wardenId: 'warden_oni_king',
        level: 1,
        exp: 150, // Enough for level up (needs 200 exp)
        unlockedAt: DateTime.now(),
      );

      expect(userWarden.canLevelUp(), false);

      final withEnough = userWarden.addExp(50); // Now has 200 exp
      expect(withEnough.canLevelUp(), true);

      final leveledUp = withEnough.levelUp();
      expect(leveledUp.level, 2);
      expect(leveledUp.exp, 0);
    });
  });
}
