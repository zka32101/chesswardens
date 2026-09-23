import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/multiplayer_match.dart';
import 'chess_engine_service.dart' show Move;

/// Characters used for invite codes - excludes visually ambiguous
/// characters (0/O, 1/I).
const String _inviteCodeAlphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

/// Generates a random 6-character invite code. Pure function, easy to
/// unit test without touching Firestore.
String generateInviteCode({Random? random}) {
  final rng = random ?? Random();
  return List.generate(
    6,
    (_) => _inviteCodeAlphabet[rng.nextInt(_inviteCodeAlphabet.length)],
  ).join();
}

/// Coordinates asynchronous (turn-by-turn) friend matches through
/// Firestore. Unlike [FirestoreService]'s other collections, matches are
/// stored top-level (`multiplayerMatches`) since they're shared between
/// two players rather than owned by one.
class MultiplayerService {
  static const String collection = 'multiplayerMatches';
  final FirebaseFirestore _firestore;
  final Uuid _uuid = const Uuid();

  MultiplayerService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Creates a new match waiting for a guest, returning its invite code.
  Future<MultiplayerMatch> createMatch(
    String hostUid,
    List<String> hostWardenIds,
  ) async {
    final match = MultiplayerMatch(
      id: _uuid.v4(),
      inviteCode: generateInviteCode(),
      hostUid: hostUid,
      hostWardenIds: hostWardenIds,
      guestWardenIds: const [],
      moves: const [],
      status: MultiplayerMatchStatus.waiting,
      createdAt: DateTime.now(),
    );

    await _firestore.collection(collection).doc(match.id).set(match.toMap());
    return match;
  }

  /// Joins a waiting match by its invite code. Returns null if no such
  /// match exists or it's no longer waiting for a guest.
  Future<MultiplayerMatch?> joinMatch(
    String inviteCode,
    String guestUid,
    List<String> guestWardenIds,
  ) async {
    final query = await _firestore
        .collection(collection)
        .where('inviteCode', isEqualTo: inviteCode.toUpperCase())
        .where('status', isEqualTo: MultiplayerMatchStatus.waiting.name)
        .limit(1)
        .get();

    if (query.docs.isEmpty) return null;

    final doc = query.docs.first;
    final updated = {
      'guestUid': guestUid,
      'guestWardenIds': guestWardenIds,
      'status': MultiplayerMatchStatus.active.name,
    };
    await doc.reference.update(updated);

    return MultiplayerMatch.fromMap({...doc.data(), ...updated});
  }

  /// Streams live updates for a match (used by both players).
  Stream<MultiplayerMatch> streamMatch(String matchId) {
    return _firestore
        .collection(collection)
        .doc(matchId)
        .snapshots()
        .where((snap) => snap.exists)
        .map((snap) => MultiplayerMatch.fromMap(snap.data()!));
  }

  /// Appends a move to the match's move list.
  Future<void> submitMove(String matchId, List<Move> updatedMoves) async {
    await _firestore.collection(collection).doc(matchId).update({
      'moves': updatedMoves.map((m) => m.toMap()).toList(),
    });
  }

  /// Marks the match finished with the given winner (or null for a draw).
  Future<void> finishMatch(String matchId, String? winnerUid) async {
    await _firestore.collection(collection).doc(matchId).update({
      'status': MultiplayerMatchStatus.finished.name,
      'winnerUid': winnerUid,
    });
  }
}
