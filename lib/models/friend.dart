/// A friend relationship, one-directional: stored under the owner's own
/// `users/{uid}/friends/{friendUid}` subcollection. Adding someone as a
/// friend only affects the adder's own friend list and friend-filtered
/// views (e.g. the friend leaderboard) — it isn't a mutual request, which
/// keeps the Firestore write scoped to documents the caller owns.
class Friend {
  final String uid;
  final DateTime addedAt;

  const Friend({required this.uid, required this.addedAt});

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'addedAt': addedAt.toIso8601String(),
      };

  factory Friend.fromMap(Map<String, dynamic> map) {
    return Friend(
      uid: map['uid'],
      addedAt: DateTime.parse(map['addedAt']),
    );
  }
}
