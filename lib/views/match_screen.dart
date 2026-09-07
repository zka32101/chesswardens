import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/index.dart';
import '../services/chess_engine_service.dart';
import '../viewmodels/index.dart';

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

  @override
  void initState() {
    super.initState();
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
      body: Column(
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

    // Wait a bit, then let AI move
    await Future.delayed(const Duration(milliseconds: 500));

    if (mounted && ref.read(gameStateProvider) != null) {
      await ref.read(gameStateProvider.notifier).makeAIMove();
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
}
