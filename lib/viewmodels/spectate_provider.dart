import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/index.dart';
import '../services/index.dart';

/// Publishes a match's replay data as a public spectate share.
class SpectateShareNotifier {
  final FirestoreService _service = FirestoreService();

  Future<String> share(MatchLog matchLog) {
    return _service.createSpectateShare(matchLog);
  }
}

final spectateShareNotifierProvider = Provider<SpectateShareNotifier>((ref) {
  return SpectateShareNotifier();
});

/// Looks up a shared match by its spectate code, for the "watch a shared
/// battle" screen. Null if the code doesn't match any share.
final spectateMatchByCodeProvider =
    FutureProvider.family<MatchLog?, String>((ref, code) async {
  final service = FirestoreService();
  return service.getSpectateShareByCode(code);
});
