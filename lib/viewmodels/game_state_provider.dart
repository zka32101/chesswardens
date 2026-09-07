import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/index.dart';
import '../services/index.dart';

/// Current game state
class GameState {
  final Board board;
  final AIDifficulty aiDifficulty;
  final List<String> playerWardenIds;
  final List<String> aiWardenIds;
  final bool isPlayerTurn;
  final List<Move> moveHistory;
  final int skillTriggeredCount;
  final DateTime? gameStartedAt;

  const GameState({
    required this.board,
    required this.aiDifficulty,
    required this.playerWardenIds,
    required this.aiWardenIds,
    required this.isPlayerTurn,
    required this.moveHistory,
    required this.skillTriggeredCount,
    this.gameStartedAt,
  });

  GameState copyWith({
    Board? board,
    AIDifficulty? aiDifficulty,
    List<String>? playerWardenIds,
    List<String>? aiWardenIds,
    bool? isPlayerTurn,
    List<Move>? moveHistory,
    int? skillTriggeredCount,
    DateTime? gameStartedAt,
  }) {
    return GameState(
      board: board ?? this.board,
      aiDifficulty: aiDifficulty ?? this.aiDifficulty,
      playerWardenIds: playerWardenIds ?? this.playerWardenIds,
      aiWardenIds: aiWardenIds ?? this.aiWardenIds,
      isPlayerTurn: isPlayerTurn ?? this.isPlayerTurn,
      moveHistory: moveHistory ?? this.moveHistory,
      skillTriggeredCount: skillTriggeredCount ?? this.skillTriggeredCount,
      gameStartedAt: gameStartedAt ?? this.gameStartedAt,
    );
  }
}

/// Game state notifier
class GameStateNotifier extends StateNotifier<GameState?> {
  final ChessEngineService _engine = ChessEngineService();
  final SkillEvaluationService _skillService = SkillEvaluationService();

  GameStateNotifier() : super(null);

  /// Start a new match
  Future<void> startNewMatch(
    AIDifficulty difficulty,
    List<String> playerWardenIds,
    List<String> aiWardenIds,
  ) async {
    state = GameState(
      board: Board(),
      aiDifficulty: difficulty,
      playerWardenIds: playerWardenIds,
      aiWardenIds: aiWardenIds,
      isPlayerTurn: true, // White (player) starts
      moveHistory: [],
      skillTriggeredCount: 0,
      gameStartedAt: DateTime.now(),
    );
  }

  /// Make a player move
  Future<bool> makePlayerMove(Move move) async {
    if (state == null || !state!.isPlayerTurn) return false;

    final board = state!.board;
    final piece = board.getPiece(move.from);

    if (piece == null || !piece.isWhite) return false;

    // Validate move
    final legalMoves = _engine.generateLegalMoves(true);
    if (!legalMoves.contains(move)) return false;

    // Make the move
    board.makeMove(move);
    final newHistory = [...state!.moveHistory, move];

    // Check for skill trigger (simplified)
    int skillTriggered = state!.skillTriggeredCount;
    if (_shouldTriggerSkill(move, piece)) {
      skillTriggered++;
    }

    state = state!.copyWith(
      moveHistory: newHistory,
      isPlayerTurn: false,
      skillTriggeredCount: skillTriggered,
    );

    return true;
  }

  /// Make AI move (asynchronous)
  Future<void> makeAIMove() async {
    if (state == null || state!.isPlayerTurn) return;

    // Find best move using minimax
    final bestMove = _engine.findBestMove(
      false, // Black (AI)
      depth: state!.aiDifficulty.minimax_depth,
    );

    if (bestMove == null) {
      // No legal moves - checkmate or stalemate
      endGame();
      return;
    }

    // Make the move
    state!.board.makeMove(bestMove);
    final newHistory = [...state!.moveHistory, bestMove];

    state = state!.copyWith(
      moveHistory: newHistory,
      isPlayerTurn: true,
    );
  }

  /// Check if a skill should trigger on this move
  bool _shouldTriggerSkill(Move move, Piece piece) {
    // Simplified: random chance based on move type
    final isCapture = move.isCapture;

    // Capture moves are more likely to trigger skills (Aha Moment)
    if (isCapture) {
      return _skillService.shouldTriggerSkill(
        SkillDefinition.mvpSkills().first,
        1, // Simplified: level 1
      );
    }

    return false;
  }

  /// End the current game
  void endGame() {
    // Game will be finalized by the view layer
    if (state != null) {
      state = state!.copyWith(isPlayerTurn: false);
    }
  }

  /// Reset game state
  void resetGame() {
    state = null;
  }
}

/// Game state provider
final gameStateProvider = StateNotifierProvider<GameStateNotifier, GameState?>(
  (ref) => GameStateNotifier(),
);

/// AI difficulty selector provider
final selectedAIDifficultyProvider = StateProvider<AIDifficulty>(
  (ref) => AIDifficulty.normal,
);
