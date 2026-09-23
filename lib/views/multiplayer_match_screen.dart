import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/index.dart';
import '../services/index.dart';
import '../services/notification_service.dart';
import '../viewmodels/index.dart';

/// Live-ish (Firestore-polled) board for an asynchronous friend match.
/// Each player only submits a move on their own turn; the board is
/// rebuilt from the shared move list on every update, the same
/// technique used by [ReplayScreen].
class MultiplayerMatchScreen extends ConsumerStatefulWidget {
  final String matchId;

  const MultiplayerMatchScreen({Key? key, required this.matchId})
      : super(key: key);

  @override
  ConsumerState<MultiplayerMatchScreen> createState() =>
      _MultiplayerMatchScreenState();
}

class _MultiplayerMatchScreenState
    extends ConsumerState<MultiplayerMatchScreen> {
  int? selectedSquare;
  List<Move> legalMoves = [];
  bool _isSubmitting = false;
  bool? _lastIsMyTurn;

  void _handleMatchUpdate(MultiplayerMatch match, String? myUid) {
    if (!match.isFull || match.status != MultiplayerMatchStatus.active) {
      _lastIsMyTurn = null;
      return;
    }

    final isMyTurn = match.currentTurnUid == myUid;
    if (_lastIsMyTurn == false && isMyTurn) {
      NotificationService.instance.showYourTurnNotification(
        matchId: match.id,
      );
    }
    _lastIsMyTurn = isMyTurn;
  }

  Board _boardFromMoves(List<Move> moves) {
    final board = Board();
    for (final m in moves) {
      board.makeMove(m);
    }
    return board;
  }

  Future<void> _handleSquareTap(
    int square,
    MultiplayerMatch match,
    Board board,
    bool isMyTurn,
    bool isHost,
  ) async {
    if (!isMyTurn || _isSubmitting) return;

    final piece = board.getPiece(square);

    if (selectedSquare == null) {
      if (piece != null && piece.isWhite == isHost) {
        final engine = ChessEngineService(initialBoard: board);
        setState(() {
          selectedSquare = square;
          legalMoves = engine
              .generateLegalMoves(isHost)
              .where((m) => m.from == square)
              .toList();
        });
      }
      return;
    }

    if (selectedSquare == square) {
      setState(() {
        selectedSquare = null;
        legalMoves = [];
      });
      return;
    }

    final matchingMoves = legalMoves.where((m) => m.to == square);
    final move = matchingMoves.isEmpty ? null : matchingMoves.first;
    setState(() {
      selectedSquare = null;
      legalMoves = [];
    });
    if (move == null) return;

    setState(() => _isSubmitting = true);
    try {
      final updatedMoves = [...match.moves, move];
      await ref
          .read(multiplayerServiceProvider)
          .submitMove(match.id, updatedMoves);

      final newBoard = _boardFromMoves(updatedMoves);
      final engine = ChessEngineService(initialBoard: newBoard);
      final nextIsHostTurn = updatedMoves.length % 2 == 0;
      if (engine.generateLegalMoves(nextIsHostTurn).isEmpty) {
        final winnerUid = nextIsHostTurn ? match.guestUid : match.hostUid;
        await ref
            .read(multiplayerServiceProvider)
            .finishMatch(match.id, winnerUid);
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final matchAsync =
        ref.watch(multiplayerMatchStreamProvider(widget.matchId));
    final myUid = ref.watch(userIdProvider);

    ref.listen<AsyncValue<MultiplayerMatch>>(
      multiplayerMatchStreamProvider(widget.matchId),
      (previous, next) {
        final match = next.valueOrNull;
        if (match != null) _handleMatchUpdate(match, myUid);
      },
    );

    return Scaffold(
      appBar: AppBar(title: const Text('フレンド対戦')),
      body: matchAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (match) {
          if (!match.isFull) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('相手の参加を待っています…'),
                  const SizedBox(height: 16),
                  Text(
                    match.inviteCode,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 24),
                  const CircularProgressIndicator(),
                ],
              ),
            );
          }

          final isHost = myUid == match.hostUid;
          final isMyTurn = match.status == MultiplayerMatchStatus.active &&
              match.currentTurnUid == myUid;
          final board = _boardFromMoves(match.moves);

          if (match.status == MultiplayerMatchStatus.finished) {
            final didWin = match.winnerUid == myUid;
            final isDraw = match.winnerUid == null;
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isDraw ? '引き分け' : (didWin ? '勝利！' : '敗北'),
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('ロビーに戻る'),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  isMyTurn ? 'あなたの番です' : '相手の番を待っています…',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(8),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 8,
                    childAspectRatio: 1,
                  ),
                  itemCount: 64,
                  itemBuilder: (context, index) {
                    final isWhiteSquare = (index ~/ 8 + index % 8) % 2 == 0;
                    final piece = board.getPiece(index);
                    final isSelected = selectedSquare == index;
                    final isLegalMove =
                        legalMoves.any((m) => m.to == index);

                    return GestureDetector(
                      onTap: () =>
                          _handleSquareTap(index, match, board, isMyTurn, isHost),
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
                            _pieceSymbol(piece),
                            style: const TextStyle(fontSize: 32),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _pieceSymbol(Piece? piece) {
    if (piece == null) return '';

    final baseSymbol = {
      PieceType.pawn: '♟',
      PieceType.knight: '♞',
      PieceType.bishop: '♝',
      PieceType.rook: '♜',
      PieceType.queen: '♛',
      PieceType.king: '♚',
    }[piece.type]!;

    if (!piece.isWhite) return baseSymbol;

    return {
      '♟': '♙',
      '♞': '♘',
      '♝': '♗',
      '♜': '♖',
      '♛': '♕',
      '♚': '♔',
    }[baseSymbol]!;
  }
}
