import 'dart:math';
import '../models/index.dart';

/// Square on chess board (0-63)
typedef Square = int;

/// Chess move representation: from square -> to square, optional promotion
class Move {
  final Square from;
  final Square to;
  final PieceType? promotion;
  final bool isCapture;
  final bool isEnPassant;
  final bool isCastling;

  Move({
    required this.from,
    required this.to,
    this.promotion,
    this.isCapture = false,
    this.isEnPassant = false,
    this.isCastling = false,
  });

  @override
  String toString() => '${squareToAlgebraic(from)}-${squareToAlgebraic(to)}';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Move &&
          runtimeType == other.runtimeType &&
          from == other.from &&
          to == other.to &&
          promotion == other.promotion;

  @override
  int get hashCode => from.hashCode ^ to.hashCode ^ promotion.hashCode;
}

/// Piece on board with Warden attributes (HP, skill)
class Piece {
  final PieceType type;
  final bool isWhite;
  int hp;
  bool skillActive;
  int skillCooldown;

  Piece({
    required this.type,
    required this.isWhite,
    required this.hp,
    this.skillActive = false,
    this.skillCooldown = 0,
  });

  Piece copy() {
    return Piece(
      type: type,
      isWhite: isWhite,
      hp: hp,
      skillActive: skillActive,
      skillCooldown: skillCooldown,
    );
  }
}

/// Chess board state with Warden HP tracking
class Board {
  static const int size = 8;
  late List<Piece?> squares; // 64 squares

  Board() {
    squares = List<Piece?>.filled(64, null);
    initializeStandardPosition();
  }

  Board.copy(Board other) {
    squares = List.from(other.squares.map((p) => p?.copy()));
  }

  /// Initialize standard chess starting position
  void initializeStandardPosition() {
    // Clear
    squares = List<Piece?>.filled(64, null);

    // White pieces (bottom, rank 1-2)
    // Rank 1 (white back rank)
    squares[0] = Piece(type: PieceType.rook, isWhite: true, hp: 100);
    squares[1] = Piece(type: PieceType.knight, isWhite: true, hp: 100);
    squares[2] = Piece(type: PieceType.bishop, isWhite: true, hp: 100);
    squares[3] = Piece(type: PieceType.queen, isWhite: true, hp: 100);
    squares[4] = Piece(type: PieceType.king, isWhite: true, hp: 100);
    squares[5] = Piece(type: PieceType.bishop, isWhite: true, hp: 100);
    squares[6] = Piece(type: PieceType.knight, isWhite: true, hp: 100);
    squares[7] = Piece(type: PieceType.rook, isWhite: true, hp: 100);

    // Rank 2 (white pawns)
    for (int i = 0; i < 8; i++) {
      squares[8 + i] = Piece(type: PieceType.pawn, isWhite: true, hp: 100);
    }

    // Black pieces (top, rank 7-8)
    // Rank 7 (black pawns)
    for (int i = 0; i < 8; i++) {
      squares[48 + i] = Piece(type: PieceType.pawn, isWhite: false, hp: 100);
    }

    // Rank 8 (black back rank)
    squares[56] = Piece(type: PieceType.rook, isWhite: false, hp: 100);
    squares[57] = Piece(type: PieceType.knight, isWhite: false, hp: 100);
    squares[58] = Piece(type: PieceType.bishop, isWhite: false, hp: 100);
    squares[59] = Piece(type: PieceType.queen, isWhite: false, hp: 100);
    squares[60] = Piece(type: PieceType.king, isWhite: false, hp: 100);
    squares[61] = Piece(type: PieceType.bishop, isWhite: false, hp: 100);
    squares[62] = Piece(type: PieceType.knight, isWhite: false, hp: 100);
    squares[63] = Piece(type: PieceType.rook, isWhite: false, hp: 100);
  }

  /// Get piece at square
  Piece? getPiece(Square square) {
    if (square < 0 || square >= 64) return null;
    return squares[square];
  }

  /// Place piece at square
  void setPiece(Square square, Piece? piece) {
    if (square >= 0 && square < 64) {
      squares[square] = piece;
    }
  }

  /// Make a move on the board
  void makeMove(Move move) {
    final piece = squares[move.from];
    if (piece == null) return;

    // Move piece
    squares[move.to] = piece;
    squares[move.from] = null;

    // Handle promotion
    if (move.promotion != null && move.to >= 56) {
      squares[move.to] = Piece(
        type: move.promotion!,
        isWhite: piece.isWhite,
        hp: 100,
      );
    }
  }

  /// Undo a move
  void undoMove(Move move, Piece? capturedPiece) {
    final piece = squares[move.to];
    if (piece == null) return;

    squares[move.from] = piece;
    squares[move.to] = capturedPiece;
  }

  /// Check if king is in check
  bool isKingInCheck(bool isWhite) {
    final kingSquare = findKing(isWhite);
    if (kingSquare == null) return false;
    return isSquareAttacked(kingSquare, !isWhite);
  }

  /// Find king square
  Square? findKing(bool isWhite) {
    for (int i = 0; i < 64; i++) {
      final piece = squares[i];
      if (piece != null &&
          piece.type == PieceType.king &&
          piece.isWhite == isWhite) {
        return i;
      }
    }
    return null;
  }

  /// Check if square is attacked by opponent
  bool isSquareAttacked(Square square, bool byWhite) {
    for (int i = 0; i < 64; i++) {
      final piece = squares[i];
      if (piece != null && piece.isWhite == byWhite) {
        // Simple: check if this piece can move to target square
        // TODO: Implement proper attack detection
      }
    }
    return false;
  }
}

/// Chess Engine with Minimax + Alpha-Beta Pruning
class ChessEngineService {
  late Board board;
  static const int maxDepth = 3;
  static const int maxEval = 10000;
  static const int minEval = -10000;

  ChessEngineService({Board? initialBoard}) {
    board = initialBoard ?? Board();
  }

  /// Find best move using minimax with alpha-beta pruning
  Move? findBestMove(bool isWhiteToMove, {int depth = maxDepth}) {
    final moves = generateLegalMoves(isWhiteToMove);
    if (moves.isEmpty) return null;

    Move? bestMove;
    int bestEval = minEval;

    for (final move in moves) {
      board.makeMove(move);
      final eval = -minimax(depth - 1, minEval, maxEval, !isWhiteToMove);
      board.undoMove(move, null); // TODO: Track captured pieces

      if (eval > bestEval) {
        bestEval = eval;
        bestMove = move;
      }
    }

    return bestMove;
  }

  /// Minimax with alpha-beta pruning
  int minimax(
    int depth,
    int alpha,
    int beta,
    bool isWhiteToMove,
  ) {
    if (depth == 0) {
      return evaluatePosition(isWhiteToMove);
    }

    final moves = generateLegalMoves(isWhiteToMove);
    if (moves.isEmpty) {
      // Checkmate or stalemate
      return board.isKingInCheck(isWhiteToMove) ? minEval : 0;
    }

    int maxEval = alpha;
    for (final move in moves) {
      board.makeMove(move);
      final eval = -minimax(depth - 1, -beta, -maxEval, !isWhiteToMove);
      board.undoMove(move, null);

      maxEval = max(maxEval, eval);
      if (maxEval >= beta) break; // Beta cutoff
    }

    return maxEval;
  }

  /// Evaluate board position with Warden HP/skill consideration
  int evaluatePosition(bool isWhiteToMove) {
    int eval = 0;

    // Material evaluation with Warden HP
    for (int i = 0; i < 64; i++) {
      final piece = board.getPiece(i);
      if (piece == null) continue;

      final value = _getPieceValue(piece.type);
      final hpBonus = (piece.hp / 100.0 * value * 0.3).round(); // HP affects value

      if (piece.isWhite) {
        eval += value + hpBonus;
      } else {
        eval -= value + hpBonus;
      }
    }

    // Positional bonuses (simplified)
    eval += _evaluatePositions(true) - _evaluatePositions(false);

    // Skill activation bonus
    eval += _evaluateSkills(true) - _evaluateSkills(false);

    return isWhiteToMove ? eval : -eval;
  }

  /// Get piece base value
  int _getPieceValue(PieceType type) {
    switch (type) {
      case PieceType.pawn:
        return 1;
      case PieceType.knight:
      case PieceType.bishop:
        return 3;
      case PieceType.rook:
        return 5;
      case PieceType.queen:
        return 9;
      case PieceType.king:
        return 0; // King value handled separately
    }
  }

  /// Evaluate positional factors
  int _evaluatePositions(bool isWhite) {
    // Simplified: center control bonus
    int score = 0;
    for (final centerSquare in [27, 28, 35, 36]) {
      final piece = board.getPiece(centerSquare);
      if (piece != null && piece.isWhite == isWhite) {
        score += 10;
      }
    }
    return score;
  }

  /// Evaluate skill states
  int _evaluateSkills(bool isWhite) {
    int score = 0;
    for (int i = 0; i < 64; i++) {
      final piece = board.getPiece(i);
      if (piece != null && piece.isWhite == isWhite && piece.skillActive) {
        score += 50; // Skill active bonus
      }
    }
    return score;
  }

  /// Generate all legal moves for a side
  List<Move> generateLegalMoves(bool isWhiteToMove) {
    final moves = <Move>[];

    for (int from = 0; from < 64; from++) {
      final piece = board.getPiece(from);
      if (piece == null || piece.isWhite != isWhiteToMove) continue;

      final pieceMoves = _generatePieceMoves(from, piece);
      moves.addAll(pieceMoves);
    }

    // Filter out moves that leave king in check
    return moves.where((move) {
      board.makeMove(move);
      final inCheck = board.isKingInCheck(isWhiteToMove);
      board.undoMove(move, null);
      return !inCheck;
    }).toList();
  }

  /// Generate pseudo-legal moves for a piece
  List<Move> _generatePieceMoves(Square from, Piece piece) {
    final moves = <Move>[];

    switch (piece.type) {
      case PieceType.pawn:
        moves.addAll(_generatePawnMoves(from, piece));
      case PieceType.knight:
        moves.addAll(_generateKnightMoves(from, piece));
      case PieceType.bishop:
        moves.addAll(_generateBishopMoves(from, piece));
      case PieceType.rook:
        moves.addAll(_generateRookMoves(from, piece));
      case PieceType.queen:
        moves.addAll(_generateQueenMoves(from, piece));
      case PieceType.king:
        moves.addAll(_generateKingMoves(from, piece));
    }

    return moves;
  }

  List<Move> _generatePawnMoves(Square from, Piece piece) {
    // TODO: Implement pawn movement logic
    return [];
  }

  List<Move> _generateKnightMoves(Square from, Piece piece) {
    // TODO: Implement knight movement logic
    return [];
  }

  List<Move> _generateBishopMoves(Square from, Piece piece) {
    // TODO: Implement bishop movement logic
    return [];
  }

  List<Move> _generateRookMoves(Square from, Piece piece) {
    // TODO: Implement rook movement logic
    return [];
  }

  List<Move> _generateQueenMoves(Square from, Piece piece) {
    // TODO: Implement queen movement logic
    return [];
  }

  List<Move> _generateKingMoves(Square from, Piece piece) {
    // TODO: Implement king movement logic
    return [];
  }
}

/// Convert square index to algebraic notation (a1 - h8)
String squareToAlgebraic(Square square) {
  final file = String.fromCharCode(97 + (square % 8)); // a-h
  final rank = '${8 - (square ~/ 8)}'; // 1-8
  return '$file$rank';
}

/// Convert algebraic notation to square index
Square? algebraicToSquare(String notation) {
  if (notation.length != 2) return null;
  final file = notation.codeUnitAt(0) - 97; // a = 0, h = 7
  final rank = int.tryParse(notation[1]);
  if (file < 0 || file >= 8 || rank == null || rank < 1 || rank > 8) {
    return null;
  }
  return (8 - rank) * 8 + file;
}
