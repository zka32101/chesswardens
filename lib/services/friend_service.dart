import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/friend.dart';
import 'multiplayer_service.dart' show generateInviteCode;

/// Manages per-user friend codes and friend lists in Firestore.
///
/// Friend codes reuse the same short, unambiguous alphabet as
/// multiplayer invite codes ([generateInviteCode]) so a player can share
/// theirs the same way. Friendship is one-directional: adding someone by
/// their code only writes to the caller's own `friends` subcollection,
/// so it never needs write access to another user's documents.
class FriendService {
  static const String usersCollection = 'users';
  static const String friendsSubcollection = 'friends';

  final FirebaseFirestore _firestore;

  FriendService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Returns the user's existing friend code, generating and persisting
  /// one if they don't have one yet.
  Future<String> ensureFriendCode(String uid) async {
    final docRef = _firestore.collection(usersCollection).doc(uid);
    final doc = await docRef.get();
    final existing = doc.data()?['friendCode'] as String?;
    if (existing != null) return existing;

    final code = generateInviteCode();
    await docRef.set({'friendCode': code}, SetOptions(merge: true));
    return code;
  }

  Future<String?> _findUidByFriendCode(String code) async {
    final query = await _firestore
        .collection(usersCollection)
        .where('friendCode', isEqualTo: code)
        .limit(1)
        .get();
    if (query.docs.isEmpty) return null;
    return query.docs.first.id;
  }

  /// Adds the owner of [code] as a friend of [myUid]. Returns the added
  /// friend's uid, or null if the code doesn't match any user or belongs
  /// to the caller themself.
  Future<String?> addFriendByCode(String myUid, String code) async {
    final targetUid = await _findUidByFriendCode(code);
    if (targetUid == null || targetUid == myUid) return null;

    await _firestore
        .collection(usersCollection)
        .doc(myUid)
        .collection(friendsSubcollection)
        .doc(targetUid)
        .set(Friend(uid: targetUid, addedAt: DateTime.now()).toMap());

    return targetUid;
  }

  Future<void> removeFriend(String myUid, String friendUid) async {
    await _firestore
        .collection(usersCollection)
        .doc(myUid)
        .collection(friendsSubcollection)
        .doc(friendUid)
        .delete();
  }

  Stream<List<Friend>> streamFriends(String uid) {
    return _firestore
        .collection(usersCollection)
        .doc(uid)
        .collection(friendsSubcollection)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Friend.fromMap(doc.data())).toList());
  }
}
