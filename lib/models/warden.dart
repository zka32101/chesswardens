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

  /// 季節限定Wardenの場合の解放シーズン（MVP4体はnull=通年）
  final Season? season;

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
    this.season,
  });

  bool get isSeasonal => season != null;

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

  /// 雪女。冬季限定。攻撃成功時に敵を凍結し行動を封じる。
  factory Warden.yukionna() {
    return const Warden(
      id: 'warden_yukionna',
      name: 'Yuki-onna',
      japaneseeName: '雪女',
      description: '雪山に住まう妖。攻撃成功時に敵駒を凍結し次ターンの行動を封じる。',
      baseType: PieceType.bishop,
      skillId: 'skill_freeze',
      baseHp: 75,
      baseAttack: 65,
      baseDefense: 65,
      season: Season.winter,
    );
  }

  /// 河童。夏季限定。攻撃成功時に与ダメージの一部を自身のHPに変換する。
  factory Warden.kappa() {
    return const Warden(
      id: 'warden_kappa',
      name: 'Kappa',
      japaneseeName: '河童',
      description: '川辺に住まう妖怪。攻撃成功時に相手の生命力を吸収し自らを回復する。',
      baseType: PieceType.pawn,
      skillId: 'skill_drain',
      baseHp: 65,
      baseAttack: 55,
      baseDefense: 55,
      season: Season.summer,
    );
  }

  /// 座敷童。通年入手可能な幸運の神獣。ターン開始時に攻撃力上昇。
  factory Warden.zashikiWarashi() {
    return const Warden(
      id: 'warden_zashiki_warashi',
      name: 'Zashiki-warashi',
      japaneseeName: '座敷童',
      description: '家に福をもたらす童。ターン開始時に幸運が宿り攻撃力が一時的に上昇する。',
      baseType: PieceType.pawn,
      skillId: 'skill_luck',
      baseHp: 60,
      baseAttack: 50,
      baseDefense: 50,
      season: Season.yearRound,
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

  /// Get all seasonal (Phase 4 LiveOps) wardens
  static List<Warden> seasonalWardens() {
    return [
      Warden.yukionna(),
      Warden.kappa(),
      Warden.zashikiWarashi(),
    ];
  }

  /// Get every warden defined in the game (MVP + seasonal)
  static List<Warden> allWardens() {
    return [...mvpWardens(), ...seasonalWardens()];
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
