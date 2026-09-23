import 'dart:async';

import 'package:flutter/material.dart';
import '../models/index.dart';
import '../services/chess_engine_service.dart';

/// Replay ("観戦モード") screen - steps through a completed match's move
/// history on a read-only board.
class ReplayScreen extends StatefulWidget {
  final MatchLog matchLog;

  const ReplayScreen({Key? key, required this.matchLog}) : super(key: key);

  @override
  State<ReplayScreen> createState() => _ReplayScreenState();
}

class _ReplayScreenState extends State<ReplayScreen> {
  late Board _board;
  int _currentMoveIndex = 0; // Number of moves applied so far (0 = start)
  Timer? _autoPlayTimer;
  bool _isPlaying = false;

  List<Move> get _moves => widget.matchLog.moves;

  @override
  void initState() {
    super.initState();
    _board = Board();
  }

  @override
  void dispose() {
    _autoPlayTimer?.cancel();
    super.dispose();
  }

  void _rebuildBoardUpTo(int moveCount) {
    final board = Board();
    for (var i = 0; i < moveCount; i++) {
      board.makeMove(_moves[i]);
    }
    setState(() {
      _board = board;
      _currentMoveIndex = moveCount;
    });
  }

  void _stepForward() {
    if (_currentMoveIndex >= _moves.length) {
      _togglePlay(forcePause: true);
      return;
    }
    _rebuildBoardUpTo(_currentMoveIndex + 1);
  }

  void _stepBackward() {
    if (_currentMoveIndex <= 0) return;
    _rebuildBoardUpTo(_currentMoveIndex - 1);
  }

  void _togglePlay({bool forcePause = false}) {
    final shouldPlay = forcePause ? false : !_isPlaying;
    setState(() => _isPlaying = shouldPlay);

    _autoPlayTimer?.cancel();
    if (shouldPlay) {
      _autoPlayTimer = Timer.periodic(const Duration(milliseconds: 800), (_) {
        if (_currentMoveIndex >= _moves.length) {
          _togglePlay(forcePause: true);
          return;
        }
        _stepForward();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_moves.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('リプレイ')),
        body: const Center(
          child: Text('この対局にはリプレイデータがありません'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('リプレイ（$_currentMoveIndex/${_moves.length}手）'),
      ),
      body: Column(
        children: [
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 8,
                childAspectRatio: 1,
              ),
              itemCount: 64,
              itemBuilder: (context, index) {
                final isWhiteSquare = (index ~/ 8 + index % 8) % 2 == 0;
                final piece = _board.getPiece(index);
                final isLastMoveSquare = _currentMoveIndex > 0 &&
                    (_moves[_currentMoveIndex - 1].from == index ||
                        _moves[_currentMoveIndex - 1].to == index);

                return Container(
                  decoration: BoxDecoration(
                    color: isLastMoveSquare
                        ? Colors.amber.shade300
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
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Slider(
              value: _currentMoveIndex.toDouble(),
              min: 0,
              max: _moves.length.toDouble(),
              divisions: _moves.length,
              label: '$_currentMoveIndex / ${_moves.length}',
              onChanged: (value) {
                _togglePlay(forcePause: true);
                _rebuildBoardUpTo(value.round());
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.skip_previous),
                  onPressed: _currentMoveIndex > 0 ? _stepBackward : null,
                ),
                IconButton(
                  iconSize: 40,
                  icon: Icon(_isPlaying ? Icons.pause_circle : Icons.play_circle),
                  onPressed: () => _togglePlay(),
                ),
                IconButton(
                  icon: const Icon(Icons.skip_next),
                  onPressed:
                      _currentMoveIndex < _moves.length ? _stepForward : null,
                ),
              ],
            ),
          ),
        ],
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
