import 'package:flutter_test/flutter_test.dart';
import 'package:chesswardens/models/equipment.dart';
import 'package:chesswardens/models/warden.dart';

void main() {
  group('Equipment', () {
    test('allEquipment defines two tiers per slot with unique ids', () {
      final all = Equipment.allEquipment();
      final ids = all.map((e) => e.id).toSet();

      expect(ids.length, all.length);
      for (final slot in EquipmentSlot.values) {
        expect(all.where((e) => e.slot == slot).length, 2);
      }
    });

    test('byId finds a defined item and returns null otherwise', () {
      expect(Equipment.byId('weapon_iron')?.slot, EquipmentSlot.weapon);
      expect(Equipment.byId('nonexistent'), isNull);
    });
  });

  group('unlockedEquipmentForLevel', () {
    test('only level-1 items unlock at level 1', () {
      final unlocked = unlockedEquipmentForLevel(1);
      expect(unlocked.every((e) => e.requiredLevel <= 1), true);
      expect(unlocked.length, 3);
    });

    test('level-5 items unlock once level reaches 5', () {
      final unlocked = unlockedEquipmentForLevel(5);
      expect(unlocked.length, Equipment.allEquipment().length);
    });
  });

  group('evolution', () {
    test('stage thresholds at level 1/5/10', () {
      expect(evolutionStageForLevel(1), 1);
      expect(evolutionStageForLevel(4), 1);
      expect(evolutionStageForLevel(5), 2);
      expect(evolutionStageForLevel(9), 2);
      expect(evolutionStageForLevel(10), 3);
      expect(evolutionStageForLevel(20), 3);
    });

    test('multiplier increases 15% per stage', () {
      expect(evolutionStatMultiplier(1), 1.0);
      expect(evolutionStatMultiplier(2), closeTo(1.15, 0.0001));
      expect(evolutionStatMultiplier(3), closeTo(1.30, 0.0001));
    });
  });

  group('effectiveStats', () {
    test('applies per-level growth with no equipment or evolution bonus', () {
      final (hp, attack, defense) = effectiveStats(
        baseHp: 100,
        baseAttack: 50,
        baseDefense: 80,
        level: 1,
      );

      expect(hp, 100);
      expect(attack, 50);
      expect(defense, 80);
    });

    test('applies evolution multiplier at stage 2', () {
      final (hp, attack, defense) = effectiveStats(
        baseHp: 100,
        baseAttack: 50,
        baseDefense: 80,
        level: 5,
      );

      // growth: hp=100+4*5=120, attack=50+4*2=58, defense=80+4*2=88
      // multiplier at stage 2 = 1.15
      expect(hp, (120 * 1.15).round());
      expect(attack, (58 * 1.15).round());
      expect(defense, (88 * 1.15).round());
    });

    test('adds equipment bonuses on top of growth and evolution', () {
      final weapon = Equipment.byId('weapon_iron')!;
      final armor = Equipment.byId('armor_leather')!;

      final (hp, attack, defense) = effectiveStats(
        baseHp: 100,
        baseAttack: 50,
        baseDefense: 80,
        level: 1,
        equipped: [weapon, armor],
      );

      expect(attack, 50 + weapon.attackBonus);
      expect(defense, 80 + armor.defenseBonus);
      expect(hp, 100);
    });
  });

  group('UserWarden equipment', () {
    final base = UserWarden(
      uid: 'u1',
      wardenId: 'warden_oni_king',
      level: 1,
      exp: 0,
      unlockedAt: DateTime(2026, 1, 1),
    );

    test('equipItem sets the slot and unequipSlot clears it', () {
      final equipped = base.equipItem('weapon', 'weapon_iron');
      expect(equipped.equippedBySlot['weapon'], 'weapon_iron');

      final unequipped = equipped.unequipSlot('weapon');
      expect(unequipped.equippedBySlot.containsKey('weapon'), false);
    });

    test('toMap/fromMap round-trips equippedBySlot', () {
      final equipped = base
          .equipItem('weapon', 'weapon_iron')
          .equipItem('armor', 'armor_leather');
      final restored = UserWarden.fromMap(equipped.toMap());

      expect(restored.equippedBySlot, equipped.equippedBySlot);
    });

    test('levelUp and addExp preserve equipped items', () {
      final equipped = base.equipItem('weapon', 'weapon_iron').addExp(9999);
      final leveled = equipped.levelUp();

      expect(leveled.equippedBySlot['weapon'], 'weapon_iron');
    });
  });
}
