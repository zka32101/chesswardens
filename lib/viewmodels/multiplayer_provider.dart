import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/multiplayer_match.dart';
import '../services/multiplayer_service.dart';

final multiplayerServiceProvider = Provider<MultiplayerService>((ref) {
  return MultiplayerService();
});

/// Streams a single multiplayer match by id.
final multiplayerMatchStreamProvider =
    StreamProvider.family<MultiplayerMatch, String>((ref, matchId) {
  return ref.watch(multiplayerServiceProvider).streamMatch(matchId);
});
