import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/index.dart';
import '../services/index.dart';
import 'auth_provider.dart';

/// Master Warden definitions (static)
final mvpWardensProvider = Provider<List<Warden>>((ref) {
  return Warden.mvpWardens();
});

/// Master Skill definitions (static)
final mvpSkillsProvider = Provider<List<SkillDefinition>>((ref) {
  return SkillDefinition.mvpSkills();
});

/// Get skill definition by ID
final skillByIdProvider = Provider.family<SkillDefinition?, String>((ref, skillId) {
  final skills = ref.watch(mvpSkillsProvider);
  try {
    return skills.firstWhere((s) => s.id == skillId);
  } catch (_) {
    return null;
  }
});

/// User's wardens (Firestore)
final userWardensProvider = FutureProvider<List<UserWarden>>((ref) async {
  final uid = ref.watch(userIdProvider);
  if (uid == null) return [];

  final firestoreService = FirestoreService();
  return firestoreService.getUserWardens(uid);
});

/// Notifier for warden updates
class UserWardenNotifier extends StateNotifier<List<UserWarden>> {
  final FirestoreService _firestoreService = FirestoreService();
  final String uid;

  UserWardenNotifier(this.uid, this.state);

  Future<void> updateWarden(UserWarden userWarden) async {
    await _firestoreService.updateUserWarden(uid, userWarden);

    // Update local state
    state = [
      for (final w in state)
        if (w.wardenId == userWarden.wardenId) userWarden else w,
    ];
  }

  Future<void> addExp(String wardenId, int amount) async {
    final warden = state.firstWhere((w) => w.wardenId == wardenId);
    var updated = warden.addExp(amount);

    // Handle level up if needed
    while (updated.canLevelUp()) {
      updated = updated.levelUp();
    }

    await updateWarden(updated);
  }
}

/// Get user warden notifier
final userWardenNotifierProvider =
    StateNotifierProvider.family<UserWardenNotifier, List<UserWarden>, String?>(
  (ref, uid) {
    final wardens = ref.watch(userWardensProvider);
    return UserWardenNotifier(uid ?? '', wardens.valueOrNull ?? []);
  },
);
