import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/friend.dart';
import '../services/friend_service.dart';
import 'auth_provider.dart';

final friendServiceProvider = Provider<FriendService>((ref) {
  return FriendService();
});

/// The current user's own friend code, generating one on first access.
final friendCodeProvider = FutureProvider<String?>((ref) async {
  final uid = ref.watch(userIdProvider);
  if (uid == null) return null;
  return ref.watch(friendServiceProvider).ensureFriendCode(uid);
});

/// The current user's friend list.
final friendsProvider = StreamProvider<List<Friend>>((ref) {
  final uid = ref.watch(userIdProvider);
  if (uid == null) return const Stream.empty();
  return ref.watch(friendServiceProvider).streamFriends(uid);
});

/// The current user's uid plus all of their friends' uids — the set used
/// to filter the leaderboard down to "friends only".
final friendAndSelfUidsProvider = Provider<Set<String>>((ref) {
  final myUid = ref.watch(userIdProvider);
  final friends = ref.watch(friendsProvider).valueOrNull ?? [];
  return {
    ?myUid,
    ...friends.map((f) => f.uid),
  };
});

class FriendNotifier {
  final FriendService _service;

  FriendNotifier(this._service);

  /// Adds a friend by their code. Returns the added friend's uid, or
  /// null if the code was invalid or belonged to the caller.
  Future<String?> addByCode(String myUid, String code) {
    return _service.addFriendByCode(myUid, code);
  }

  Future<void> remove(String myUid, String friendUid) {
    return _service.removeFriend(myUid, friendUid);
  }
}

final friendNotifierProvider = Provider<FriendNotifier>((ref) {
  return FriendNotifier(ref.watch(friendServiceProvider));
});
