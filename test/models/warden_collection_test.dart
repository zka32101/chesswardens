import 'package:flutter_test/flutter_test.dart';
import 'package:chesswardens/models/index.dart';

void main() {
  group('Warden collection (図鑑)', () {
    test('allWardens contains every MVP and seasonal warden with unique ids', () {
      final all = Warden.allWardens();
      final ids = all.map((w) => w.id).toSet();
      expect(ids.length, all.length, reason: 'Warden idに重複がある');
      expect(all.length, 7);
    });

    test('unlocked count matches the intersection of owned ids', () {
      final all = Warden.allWardens();
      final ownedIds = {Warden.oniKing().id, Warden.yukionna().id};
      final unlockedCount =
          all.where((w) => ownedIds.contains(w.id)).length;
      expect(unlockedCount, 2);
    });
  });
}
