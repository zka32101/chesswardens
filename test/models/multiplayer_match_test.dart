import 'package:flutter_test/flutter_test.dart';
import 'package:chesswardens/models/index.dart';
import 'package:chesswardens/services/chess_engine_service.dart';
import 'package:chesswardens/services/multiplayer_service.dart';

void main() {
  group('generateInviteCode', () {
    test('produces a 6-character code from the expected alphabet', () {
      final code = generateInviteCode();
      expect(code.length, 6);
      expect(RegExp(r'^[ABCDEFGHJKLMNPQRSTUVWXYZ23456789]{6}$').hasMatch(code),
          isTrue);
    });
  });

  group('MultiplayerMatch', () {
    MultiplayerMatch buildMatch({
      String? guestUid,
      List<Move> moves = const [],
      MultiplayerMatchStatus status = MultiplayerMatchStatus.waiting,
      String? winnerUid,
    }) {
      return MultiplayerMatch(
        id: 'match1',
        inviteCode: 'ABC123',
        hostUid: 'host',
        guestUid: guestUid,
        hostWardenIds: const ['warden_oni_king'],
        guestWardenIds: guestUid == null ? const [] : const ['warden_kitsune'],
        moves: moves,
        status: status,
        winnerUid: winnerUid,
        createdAt: DateTime(2026, 1, 1),
      );
    }

    test('isFull reflects whether a guest has joined', () {
      expect(buildMatch().isFull, isFalse);
      expect(buildMatch(guestUid: 'guest').isFull, isTrue);
    });

    test('isHostTurn alternates by move count parity', () {
      final match = buildMatch(
        guestUid: 'guest',
        status: MultiplayerMatchStatus.active,
        moves: [Move(from: 8, to: 16)],
      );
      expect(match.isHostTurn, isFalse); // 1 move played -> guest just moved... host's turn is even count
    });

    test('currentTurnUid is null until active and null once finished', () {
      final waiting = buildMatch();
      expect(waiting.currentTurnUid, isNull);

      final finished = buildMatch(
        guestUid: 'guest',
        status: MultiplayerMatchStatus.finished,
        winnerUid: 'host',
      );
      expect(finished.currentTurnUid, isNull);

      final active = buildMatch(
        guestUid: 'guest',
        status: MultiplayerMatchStatus.active,
      );
      expect(active.currentTurnUid, 'host');
    });

    test('isParticipant identifies host and guest only', () {
      final match = buildMatch(guestUid: 'guest');
      expect(match.isParticipant('host'), isTrue);
      expect(match.isParticipant('guest'), isTrue);
      expect(match.isParticipant('stranger'), isFalse);
    });

    test('round-trips through toMap/fromMap including moves', () {
      final match = buildMatch(
        guestUid: 'guest',
        status: MultiplayerMatchStatus.active,
        moves: [Move(from: 8, to: 16), Move(from: 48, to: 32)],
      );

      final restored = MultiplayerMatch.fromMap(match.toMap());
      expect(restored.moves.length, 2);
      expect(restored.status, MultiplayerMatchStatus.active);
      expect(restored.guestUid, 'guest');
    });
  });
}
