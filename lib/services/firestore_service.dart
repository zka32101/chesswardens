import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/index.dart';

/// Firestore database service for Chess Wardens
class FirestoreService {
  static const String usersCollection = 'users';
  static const String userWardensSubcollection = 'wardens';
  static const String matchLogsSubcollection = 'matchLogs';
  static const String shareCardsCollection = 'shareCards';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const _uuid = Uuid();

  /// Create or get user document
  Future<void> initializeUser(String uid) async {
    final docRef = _firestore.collection(usersCollection).doc(uid);
    final doc = await docRef.get();

    if (!doc.exists) {
      await docRef.set({
        'uid': uid,
        'createdAt': FieldValue.serverTimestamp(),
        'lastPlayedAt': FieldValue.serverTimestamp(),
      });

      // Initialize all MVP wardens for the user
      for (final warden in Warden.mvpWardens()) {
        await addUserWarden(uid, warden.id);
      }
    }
  }

  /// Add a warden to user's collection
  Future<void> addUserWarden(String uid, String wardenId) async {
    final userWardenRef = _firestore
        .collection(usersCollection)
        .doc(uid)
        .collection(userWardensSubcollection)
        .doc(wardenId);

    await userWardenRef.set({
      'uid': uid,
      'wardenId': wardenId,
      'level': 1,
      'exp': 0,
      'unlockedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Get user's wardens
  Future<List<UserWarden>> getUserWardens(String uid) async {
    final snapshot = await _firestore
        .collection(usersCollection)
        .doc(uid)
        .collection(userWardensSubcollection)
        .get();

    return snapshot.docs
        .map((doc) => UserWarden.fromMap(doc.data()))
        .toList();
  }

  /// Update user warden (level up, exp)
  Future<void> updateUserWarden(String uid, UserWarden userWarden) async {
    await _firestore
        .collection(usersCollection)
        .doc(uid)
        .collection(userWardensSubcollection)
        .doc(userWarden.wardenId)
        .update(userWarden.toMap());
  }

  /// Add match log
  Future<String> addMatchLog(
    String uid,
    AIDifficulty difficulty,
    MatchResult result,
    int skillTriggeredCount,
    int playerScore,
    int aiScore,
    int movesPlayed,
  ) async {
    final matchId = _uuid.v4();
    final matchLog = MatchLog(
      id: matchId,
      uid: uid,
      aiDifficulty: difficulty,
      result: result,
      skillTriggeredCount: skillTriggeredCount,
      playerScore: playerScore,
      aiScore: aiScore,
      movesPlayed: movesPlayed,
      playedAt: DateTime.now(),
    );

    await _firestore
        .collection(usersCollection)
        .doc(uid)
        .collection(matchLogsSubcollection)
        .doc(matchId)
        .set(matchLog.toMap());

    return matchId;
  }

  /// Get recent match logs
  Future<List<MatchLog>> getRecentMatchLogs(
    String uid, {
    int limit = 20,
  }) async {
    final snapshot = await _firestore
        .collection(usersCollection)
        .doc(uid)
        .collection(matchLogsSubcollection)
        .orderBy('playedAt', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs
        .map((doc) => MatchLog.fromMap(doc.data()))
        .toList();
  }

  /// Create share card
  Future<String> createShareCard(
    String uid,
    String matchLogId,
    String imageUrl, {
    String? caption,
  }) async {
    final cardId = _uuid.v4();
    final shareCard = ShareCard(
      id: cardId,
      uid: uid,
      matchLogId: matchLogId,
      imageUrl: imageUrl,
      createdAt: DateTime.now(),
      caption: caption,
    );

    await _firestore
        .collection(shareCardsCollection)
        .doc(cardId)
        .set(shareCard.toMap());

    return cardId;
  }

  /// Get user's share cards
  Future<List<ShareCard>> getUserShareCards(
    String uid, {
    int limit = 20,
  }) async {
    final snapshot = await _firestore
        .collection(shareCardsCollection)
        .where('uid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs
        .map((doc) => ShareCard.fromMap(doc.data()))
        .toList();
  }

  /// Record analytics event
  Future<void> recordEvent(
    String uid,
    String eventName, {
    Map<String, dynamic>? parameters,
  }) async {
    // Firebase Analytics handles this through FirebaseAnalytics
    // This is a placeholder for structured events
  }
}
