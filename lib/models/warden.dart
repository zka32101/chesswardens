import 'package:uuid/uuid.dart';
import 'enums.dart';

/// 妖怪・神獣マスター定義（レベル依存なし、スキル定義は SkillDefinition で管理）
class Warden {
  final String id;
  final String name;
  final String japaneseeName;
  final String description;
  final PieceType baseType;
  final String skillId;
  final int baseHp;
  final int baseAttack;
  final int baseDefense;

  const Warden({
    required this.id,
    required this.name,
    required this.japaneseeName,
    required this.description,
    required this.baseType,
    required this.skillId,
    required this.baseHp,
    required this.baseAttack,
    required this.baseDefense,
  });

  factory Warden.oniKing() {
    return const Warden(
      id: 'warden_oni_king',
      name: 'Oni King',
      japaneseeName: '鬼王',
      description: '鬼の王。被弾時に一度だけ生存する不死のスキルを持つ。',
      baseType: PieceType.king,
      skillId: 'skill_immortality',
      baseHp: 100,
      baseAttack: 50,
      baseDefense: 80,
    );
  }

  factory Warden.kitsune() {
    return const Warden(
      id: 'warden_kitsune',
      name: 'Kitsune',
      japaneseeName: '九尾',
      description: '九尾の狐。攻撃成功時に隣接マスへ炎ダメージを拡散する。',
      baseType: PieceType.queen,
      skillId: 'skill_spread_damage',
      baseHp: 80,
      baseAttack: 90,
      baseDefense: 60,
    );
  }

  factory Warden.orochi() {
    return const Warden(
      id: 'warden_orochi',
      name: 'Orochi',
      japaneseeName: '大蛇',
      description: '八岐大蛇。ターン開始時に被スキル無効の鉄壁を張る。',
      baseType: PieceType.rook,
      skillId: 'skill_shield_turns',
      baseHp: 90,
      baseAttack: 70,
      baseDefense: 95,
    );
  }

  factory Warden.tengu() {
    return const Warden(
      id: 'warden_tengu',
      name: 'Tengu',
      japaneseeName: '天狗',
      description: '天狗。移動確定後に1マスの追加ジャンプで盤面を翻弄する。',
      baseType: PieceType.knight,
      skillId: 'skill_jump_move',
      baseHp: 70,
      baseAttack: 75,
      baseDefense: 70,
    );
  }

  /// Get all MVP wardens
  static List<Warden> mvpWardens() {
    return [
      Warden.oniKing(),
      Warden.kitsune(),
      Warden.orochi(),
      Warden.tengu(),
    ];
  }
}

/// ユーザーが所有するWarden インスタンス
class UserWarden {
  final String uid;
  final String wardenId;
  final int level;
  final int exp;
  final DateTime unlockedAt;
  final DateTime? lastUpgradedAt;

  const UserWarden({
    required this.uid,
    required this.wardenId,
    required this.level,
    required this.exp,
    required this.unlockedAt,
    this.lastUpgradedAt,
  });

  /// Calculate exp required for next level
  int expRequiredForNextLevel(int currentLevel) {
    return 100 * (currentLevel + 1);
  }

  /// Check if can level up
  bool canLevelUp() {
    return exp >= expRequiredForNextLevel(level);
  }

  UserWarden levelUp() {
    return UserWarden(
      uid: uid,
      wardenId: wardenId,
      level: level + 1,
      exp: exp - expRequiredForNextLevel(level),
      unlockedAt: unlockedAt,
      lastUpgradedAt: DateTime.now(),
    );
  }

  UserWarden addExp(int amount) {
    return UserWarden(
      uid: uid,
      wardenId: wardenId,
      level: level,
      exp: exp + amount,
      unlockedAt: unlockedAt,
      lastUpgradedAt: lastUpgradedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'wardenId': wardenId,
      'level': level,
      'exp': exp,
      'unlockedAt': unlockedAt.toIso8601String(),
      'lastUpgradedAt': lastUpgradedAt?.toIso8601String(),
    };
  }

  factory UserWarden.fromMap(Map<String, dynamic> map) {
    return UserWarden(
      uid: map['uid'],
      wardenId: map['wardenId'],
      level: map['level'] ?? 1,
      exp: map['exp'] ?? 0,
      unlockedAt: DateTime.parse(map['unlockedAt']),
      lastUpgradedAt: map['lastUpgradedAt'] != null
          ? DateTime.parse(map['lastUpgradedAt'])
          : null,
    );
  }
}
