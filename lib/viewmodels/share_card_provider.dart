import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/index.dart';
import '../services/index.dart';
import 'auth_provider.dart';

/// Share cards provider (Firestore)
final shareCardsProvider = FutureProvider<List<ShareCard>>((ref) async {
  final uid = ref.watch(userIdProvider);
  if (uid == null) return [];

  final firestoreService = FirestoreService();
  return firestoreService.getUserShareCards(uid, limit: 20);
});

/// Share card creation notifier
class ShareCardNotifier extends StateNotifier<List<ShareCard>> {
  final FirestoreService _firestoreService = FirestoreService();
  final String uid;

  ShareCardNotifier(this.uid, this.state);

  /// Create and share a match result
  Future<String> createShareCard(
    String matchLogId,
    String imageUrl, {
    String? caption,
  }) async {
    final cardId = await _firestoreService.createShareCard(
      uid,
      matchLogId,
      imageUrl,
      caption: caption,
    );

    // Add to local state
    final shareCard = ShareCard(
      id: cardId,
      uid: uid,
      matchLogId: matchLogId,
      imageUrl: imageUrl,
      createdAt: DateTime.now(),
      caption: caption,
    );

    state = [shareCard, ...state];

    return cardId;
  }
}

/// Get share card notifier
final shareCardNotifierProvider =
    StateNotifierProvider.family<ShareCardNotifier, List<ShareCard>, String?>(
  (ref, uid) {
    final cards = ref.watch(shareCardsProvider);
    return ShareCardNotifier(uid ?? '', cards.valueOrNull ?? []);
  },
);

/// Share statistics
final shareStatsProvider = Provider<(int totalShares, int todayShares)>((ref) {
  final cards = ref.watch(shareCardsProvider).valueOrNull ?? [];
  final today = DateTime.now();

  final totalShares = cards.length;
  final todayShares = cards
      .where((c) =>
          c.createdAt.year == today.year &&
          c.createdAt.month == today.month &&
          c.createdAt.day == today.day)
      .length;

  return (totalShares, todayShares);
});
