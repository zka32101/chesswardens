/// Equipment slots a warden can fill. Only one item per slot at a time.
enum EquipmentSlot { weapon, armor, accessory }

/// A piece of equipment that boosts a warden's stats once unlocked and
/// equipped. Unlocking is level-gated (no currency system exists in this
/// app yet), so every player eventually has access to the same gear —
/// equipping is purely a build choice.
class Equipment {
  final String id;
  final String name;
  final String description;
  final EquipmentSlot slot;
  final int requiredLevel;
  final int hpBonus;
  final int attackBonus;
  final int defenseBonus;

  const Equipment({
    required this.id,
    required this.name,
    required this.description,
    required this.slot,
    required this.requiredLevel,
    this.hpBonus = 0,
    this.attackBonus = 0,
    this.defenseBonus = 0,
  });

  static List<Equipment> allEquipment() {
    return const [
      Equipment(
        id: 'weapon_iron',
        name: '鉄の武具',
        description: '基本的な武具。攻撃力が上がる。',
        slot: EquipmentSlot.weapon,
        requiredLevel: 1,
        attackBonus: 5,
      ),
      Equipment(
        id: 'weapon_flame',
        name: '炎の武具',
        description: '炎を纏った強力な武具。攻撃力が大きく上がる。',
        slot: EquipmentSlot.weapon,
        requiredLevel: 5,
        attackBonus: 12,
      ),
      Equipment(
        id: 'armor_leather',
        name: '革の防具',
        description: '軽量な防具。防御力が上がる。',
        slot: EquipmentSlot.armor,
        requiredLevel: 1,
        defenseBonus: 5,
      ),
      Equipment(
        id: 'armor_steel',
        name: '鋼の防具',
        description: '頑丈な防具。防御力が大きく上がる。',
        slot: EquipmentSlot.armor,
        requiredLevel: 5,
        defenseBonus: 12,
      ),
      Equipment(
        id: 'accessory_charm',
        name: '御守り',
        description: '小さな御守り。HPが上がる。',
        slot: EquipmentSlot.accessory,
        requiredLevel: 1,
        hpBonus: 10,
      ),
      Equipment(
        id: 'accessory_amulet',
        name: '護符',
        description: '強力な護符。HPが大きく上がる。',
        slot: EquipmentSlot.accessory,
        requiredLevel: 5,
        hpBonus: 25,
      ),
    ];
  }

  static Equipment? byId(String id) {
    final matches = allEquipment().where((e) => e.id == id);
    return matches.isEmpty ? null : matches.first;
  }
}

/// Equipment unlocked for a warden at [level] (independent of slot).
List<Equipment> unlockedEquipmentForLevel(int level) {
  return Equipment.allEquipment().where((e) => e.requiredLevel <= level).toList();
}

/// A warden's evolution stage, based purely on level. Stages give a flat
/// percentage boost to base stats, on top of the existing per-level
/// growth and any equipped gear.
int evolutionStageForLevel(int level) {
  if (level >= 10) return 3;
  if (level >= 5) return 2;
  return 1;
}

String evolutionStageLabel(int stage) {
  switch (stage) {
    case 3:
      return '最終形態';
    case 2:
      return '進化形態';
    default:
      return '初期形態';
  }
}

double evolutionStatMultiplier(int stage) {
  return 1.0 + (stage - 1) * 0.15;
}

/// Effective HP/attack/defense for a warden at [level], with [equipped]
/// items' bonuses applied on top of the per-level growth and evolution
/// multiplier. Pure function, independent of [UserWarden]/[Warden] so it
/// can be unit tested directly against plain numbers.
(int, int, int) effectiveStats({
  required int baseHp,
  required int baseAttack,
  required int baseDefense,
  required int level,
  List<Equipment> equipped = const [],
}) {
  final stage = evolutionStageForLevel(level);
  final multiplier = evolutionStatMultiplier(stage);

  final growthHp = baseHp + (level - 1) * 5;
  final growthAttack = baseAttack + (level - 1) * 2;
  final growthDefense = baseDefense + (level - 1) * 2;

  final hpBonus = equipped.fold(0, (sum, e) => sum + e.hpBonus);
  final attackBonus = equipped.fold(0, (sum, e) => sum + e.attackBonus);
  final defenseBonus = equipped.fold(0, (sum, e) => sum + e.defenseBonus);

  return (
    (growthHp * multiplier).round() + hpBonus,
    (growthAttack * multiplier).round() + attackBonus,
    (growthDefense * multiplier).round() + defenseBonus,
  );
}
