import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/index.dart';
import '../services/chess_engine_service.dart';
import '../services/skill_animation_service.dart';
import '../viewmodels/index.dart';
import 'widgets/skill_animation_overlay.dart';

/// Match screen - Main battle interface
class MatchScreen extends ConsumerStatefulWidget {
  final AIDifficulty aiDifficulty;
  final List<String> playerWardenIds;
  final List<String> aiWardenIds;

  const MatchScreen({
    Key? key,
    required this.aiDifficulty,
    required this.playerWardenIds,
    required this.aiWardenIds,
  }) : super(key: key);

  @override
  ConsumerState<MatchScreen> createState() => _MatchScreenState();
}

class _MatchScreenState extends ConsumerState<MatchScreen> {
  Square? selectedSquare;
  List<Move> legalMoves = [];
  bool isProcessing = false;
  SkillEffectType? displayingSkillAnimation;
  String? displayingWardenName;
  String? displayingSkillName;
  late DateTime _matchStartTime;

  @override
  void initState() {
    super.initState();
    _matchStartTime = DateTime.now();
    _initializeMatch();
  }

  void _initializeMatch() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(gameStateProvider.notifier).startNewMatch(
            widget.aiDifficulty,
            widget.playerWardenIds,
            widget.aiWardenIds,
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameStateProvider);

    if (gameState == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Battle')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Battle'),
        elevation: 0,
      ),
      body: Stack(
        children: [
          Column(
            children: [
          // AI Status Bar
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.grey.shade200,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('AI (Black)'),
                Text('♖ ♗ ♘ ♕ ♔'),
              ],
            ),
          ),

          // Chess Board
          Expanded(
            child: GestureDetector(
              onTapDown: (details) {
                _handleBoardTap(context, details.localPosition, gameState.board);
              },
              child: _buildChessBoard(gameState),
            ),
          ),

          // Player Status Bar
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.grey.shade200,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('You (White)'),
                Text('♜ ♝ ♞ ♛ ♚'),
              ],
            ),
          ),

          // Info Panel
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  gameState.isPlayerTurn ? 'Your Turn' : 'AI is thinking...',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: gameState.isPlayerTurn ? Colors.green : Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Skills Triggered: ${gameState.skillTriggeredCount}',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
            ],
          ),
          // Skill Animation Overlay
          if (displayingSkillAnimation != null)
            SkillAnimationDisplay(
              effectType: displayingSkillAnimation!,
              wardenName: displayingWardenName ?? 'Warden',
              skillName: displayingSkillName ?? 'Skill',
              onAnimationComplete: () {
                setState(() {
                  displayingSkillAnimation = null;
                  displayingWardenName = null;
                  displayingSkillName = null;
                });
              },
            ),
        ],
      ),
    );
  }

  Widget _buildChessBoard(GameState gameState) {
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 8,
        childAspectRatio: 1,
      ),
      itemCount: 64,
      itemBuilder: (context, index) {
        final isWhiteSquare = (index ~/ 8 + index % 8) % 2 == 0;
        final piece = gameState.board.getPiece(index);
        final isSelected = selectedSquare == index;
        final isLegalMove = legalMoves.any((m) => m.to == index);

        return GestureDetector(
          onTap: () {
            _handleSquareTap(index, gameState.board);
          },
          child: Container(
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.blue.shade400
                  : isLegalMove
                      ? Colors.green.shade400
                      : isWhiteSquare
                          ? Colors.brown.shade100
                          : Colors.brown.shade400,
            ),
            child: Center(
              child: Text(
                _getPieceSymbol(piece),
                style: const TextStyle(fontSize: 32),
              ),
            ),
          ),
        );
      },
    );
  }

  void _handleSquareTap(int square, Board board) {
    if (isProcessing || !ref.read(gameStateProvider)!.isPlayerTurn) return;

    final piece = board.getPiece(square);

    if (selectedSquare == null) {
      if (piece != null && piece.isWhite) {
        setState(() {
          selectedSquare = square;
          // Generate legal moves for this piece
          final engine = ChessEngineService(initialBoard: board);
          legalMoves = engine.generateLegalMoves(true)
              .where((m) => m.from == square)
              .toList();
        });
      }
    } else {
      if (selectedSquare == square) {
        // Deselect
        setState(() {
          selectedSquare = null;
          legalMoves = [];
        });
      } else {
        // Try to move
        final move = Move(
          from: selectedSquare!,
          to: square,
          isCapture: piece != null,
        );

        _makePlayerMove(move);
      }
    }
  }

  void _handleBoardTap(BuildContext context, Offset localPosition, Board board) {
    // Alternative touch handling if needed
  }

  Future<void> _makePlayerMove(Move move) async {
    setState(() => isProcessing = true);

    final success = await ref.read(gameStateProvider.notifier).makePlayerMove(move);

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid move')),
      );
      setState(() {
        selectedSquare = null;
        legalMoves = [];
        isProcessing = false;
      });
      return;
    }

    setState(() {
      selectedSquare = null;
      legalMoves = [];
    });

    // Check for game over after player move
    var gameState = ref.read(gameStateProvider);
    if (gameState != null && mounted) {
      await _checkGameOver(gameState);
      if (!mounted) return; // Navigation occurred
    }

    // Check if skill was triggered and show animation
    if (move.isCapture) {
      final allSkills = ref.read(mvpSkillsProvider);
      final randomSkill = allSkills.isNotEmpty
          ? allSkills[DateTime.now().millisecond % allSkills.length]
          : null;

      if (randomSkill != null) {
        final playerWarden = ref.read(userWardensProvider).maybeWhen(
          data: (wardens) => wardens.isNotEmpty ? wardens.first : null,
          orElse: () => null,
        );

        if (playerWarden != null) {
          setState(() {
            displayingSkillAnimation = randomSkill.effectType;
            displayingWardenName = playerWarden.wardenId;
            displayingSkillName = randomSkill.name;
          });

          // Wait for animation to complete
          await Future.delayed(
            SkillAnimationService.getAnimationDuration(randomSkill.effectType),
          );
        }
      }
    }

    // Wait a bit, then let AI move
    await Future.delayed(const Duration(milliseconds: 500));

    if (mounted && ref.read(gameStateProvider) != null) {
      await ref.read(gameStateProvider.notifier).makeAIMove();

      // Check for game over after AI move
      final gameState = ref.read(gameStateProvider);
      if (gameState != null && mounted) {
        await _checkGameOver(gameState);
      }
    }

    setState(() => isProcessing = false);
  }

  String _getPieceSymbol(Piece? piece) {
    if (piece == null) return '';

    final baseSymbol = {
      PieceType.pawn: '♟',
      PieceType.knight: '♞',
      PieceType.bishop: '♝',
      PieceType.rook: '♜',
      PieceType.queen: '♛',
      PieceType.king: '♚',
    }[piece.type]!;

    // Use different symbols for white
    if (piece.isWhite) {
      return {
        '♟': '♙',
        '♞': '♘',
        '♝': '♗',
        '♜': '♖',
        '♛': '♕',
        '♚': '♔',
      }[baseSymbol]!;
    }

    return baseSymbol;
  }

  Future<void> _checkGameOver(GameState gameState) async {
    final engine = ChessEngineService(initialBoard: gameState.board);
    final legalMoves = engine.generateLegalMoves(gameState.isPlayerTurn);

    if (legalMoves.isEmpty) {
      // No legal moves - game over
      final matchDuration = DateTime.now().difference(_matchStartTime);

      // Simplified result calculation
      int playerScore = gameState.board.board
          .whereType<Piece>()
          .where((p) => p.isWhite)
          .fold(0, (sum, p) => sum + (p.type == PieceType.king ? 10 : 1));

      int aiScore = gameState.board.board
          .whereType<Piece>()
          .where((p) => !p.isWhite)
          .fold(0, (sum, p) => sum + (p.type == PieceType.king ? 10 : 1));

      final result = playerScore > aiScore
          ? MatchResult.win
          : playerScore < aiScore
              ? MatchResult.loss
              : MatchResult.draw;

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => MatchResultScreen(
              result: result,
              playerScore: playerScore,
              aiScore: aiScore,
              skillTriggeredCount: gameState.skillTriggeredCount,
              movesPlayed: gameState.moveHistory.length,
              matchDuration: matchDuration,
              aiDifficulty: widget.aiDifficulty,
              playerWardenIds: widget.playerWardenIds,
            ),
          ),
        );
      }
    }
  }
}
