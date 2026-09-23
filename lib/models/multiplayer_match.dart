import '../services/chess_engine_service.dart' show Move;

/// Status of an asynchronous friend match.
enum MultiplayerMatchStatus {
  waiting('待機中'),
  active('対戦中'),
  finished('終了');

  const MultiplayerMatchStatus(this.label);
  final String label;
}

/// An asynchronous (turn-by-turn, non-realtime) friend match, coordinated
/// through Firestore. The host always plays White (moves at even indices),
/// the guest always plays Black (odd indices) - see [isHostTurn].
class MultiplayerMatch {
  final String id;
  final String inviteCode;
  final String hostUid;
  final String? guestUid;
  final List<String> hostWardenIds;
  final List<String> guestWardenIds;
  final List<Move> moves;
  final MultiplayerMatchStatus status;
  final String? winnerUid;
  final DateTime createdAt;

  const MultiplayerMatch({
    required this.id,
    required this.inviteCode,
    required this.hostUid,
    this.guestUid,
    required this.hostWardenIds,
    required this.guestWardenIds,
    required this.moves,
    required this.status,
    this.winnerUid,
    required this.createdAt,
  });

  bool get isFull => guestUid != null;

  /// Whose turn it is: host (White) moves first and on every even ply.
  bool get isHostTurn => moves.length % 2 == 0;

  /// The uid of the player whose turn it currently is, or null if the
  /// match hasn't started (no guest yet) or has finished.
  String? get currentTurnUid {
    if (status != MultiplayerMatchStatus.active) return null;
    return isHostTurn ? hostUid : guestUid;
  }

  bool isParticipant(String uid) => uid == hostUid || uid == guestUid;

  MultiplayerMatch copyWith({
    String? guestUid,
    List<String>? guestWardenIds,
    List<Move>? moves,
    MultiplayerMatchStatus? status,
    String? winnerUid,
  }) {
    return MultiplayerMatch(
      id: id,
      inviteCode: inviteCode,
      hostUid: hostUid,
      guestUid: guestUid ?? this.guestUid,
      hostWardenIds: hostWardenIds,
      guestWardenIds: guestWardenIds ?? this.guestWardenIds,
      moves: moves ?? this.moves,
      status: status ?? this.status,
      winnerUid: winnerUid ?? this.winnerUid,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'inviteCode': inviteCode,
        'hostUid': hostUid,
        'guestUid': guestUid,
        'hostWardenIds': hostWardenIds,
        'guestWardenIds': guestWardenIds,
        'moves': moves.map((m) => m.toMap()).toList(),
        'status': status.name,
        'winnerUid': winnerUid,
        'createdAt': createdAt.toIso8601String(),
      };

  factory MultiplayerMatch.fromMap(Map<String, dynamic> map) {
    return MultiplayerMatch(
      id: map['id'] as String,
      inviteCode: map['inviteCode'] as String,
      hostUid: map['hostUid'] as String,
      guestUid: map['guestUid'] as String?,
      hostWardenIds: List<String>.from(map['hostWardenIds'] as List? ?? []),
      guestWardenIds: List<String>.from(map['guestWardenIds'] as List? ?? []),
      moves: (map['moves'] as List<dynamic>? ?? [])
          .map((m) => Move.fromMap(Map<String, dynamic>.from(m as Map)))
          .toList(),
      status: MultiplayerMatchStatus.values.firstWhere(
        (s) => s.name == map['status'],
        orElse: () => MultiplayerMatchStatus.waiting,
      ),
      winnerUid: map['winnerUid'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }
}
