import 'enums.dart';
import '../services/chess_engine_service.dart' show Move;

/// 対局履歴
class MatchLog {
  final String id;
  final String uid;
  final AIDifficulty aiDifficulty;
  final MatchResult result;
  final int skillTriggeredCount;
  final int playerScore;
  final int aiScore;
  final int movesPlayed;
  final DateTime playedAt;

  /// Full move-by-move record of the match, used for replay/観戦モード.
  /// Empty for match logs recorded before this field existed.
  final List<Move> moves;

  const MatchLog({
    required this.id,
    required this.uid,
    required this.aiDifficulty,
    required this.result,
    required this.skillTriggeredCount,
    required this.playerScore,
    required this.aiScore,
    required this.movesPlayed,
    required this.playedAt,
    this.moves = const [],
  });

  bool get hasReplay => moves.isNotEmpty;

  /// Calculate experience gain
  int calculateExpGain() {
    int baseExp = 50;

    // Win bonus
    if (result == MatchResult.win) {
      baseExp += 50;
    }

    // Difficulty multiplier
    baseExp = (baseExp * (aiDifficulty.minimax_depth / 2)).round();

    // Skill trigger bonus (Aha Moment metric)
    baseExp += skillTriggeredCount * 10;

    return baseExp;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'uid': uid,
      'aiDifficulty': aiDifficulty.label,
      'result': result.label,
      'skillTriggeredCount': skillTriggeredCount,
      'playerScore': playerScore,
      'aiScore': aiScore,
      'movesPlayed': movesPlayed,
      'playedAt': playedAt.toIso8601String(),
      'moves': moves.map((m) => m.toMap()).toList(),
    };
  }

  factory MatchLog.fromMap(Map<String, dynamic> map) {
    return MatchLog(
      id: map['id'],
      uid: map['uid'],
      aiDifficulty: AIDifficulty.values.firstWhere(
        (e) => e.label == map['aiDifficulty'],
        orElse: () => AIDifficulty.normal,
      ),
      result: MatchResult.values.firstWhere(
        (e) => e.label == map['result'],
        orElse: () => MatchResult.draw,
      ),
      skillTriggeredCount: map['skillTriggeredCount'] ?? 0,
      playerScore: map['playerScore'] ?? 0,
      aiScore: map['aiScore'] ?? 0,
      movesPlayed: map['movesPlayed'] ?? 0,
      playedAt: DateTime.parse(map['playedAt']),
      moves: (map['moves'] as List<dynamic>?)
              ?.map((m) => Move.fromMap(Map<String, dynamic>.from(m as Map)))
              .toList() ??
          const [],
    );
  }
}
