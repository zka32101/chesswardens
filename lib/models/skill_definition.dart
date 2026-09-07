import 'enums.dart';

/// スキルの定義（レベル依存のパラメータを含む）
class SkillDefinition {
  final String id;
  final String name;
  final String japaneseeName;
  final String description;
  final SkillEffectType effectType;
  final SkillTriggerCondition triggerCondition;

  /// スキル発動確率（レベル別）例: [0.5, 0.6, 0.7, 0.8]
  final List<double> triggerRateByLevel;

  /// ダメージ/効果値（レベル別）
  final List<int> valueByLevel;

  /// ターン数（鉄壁など）
  final int? durationTurns;

  /// 効果範囲（マス数）
  final int? rangeSquares;

  const SkillDefinition({
    required this.id,
    required this.name,
    required this.japaneseeName,
    required this.description,
    required this.effectType,
    required this.triggerCondition,
    required this.triggerRateByLevel,
    required this.valueByLevel,
    this.durationTurns,
    this.rangeSquares,
  });

  /// 鬼王の不死スキル（被弾時に一度だけ生存）
  factory SkillDefinition.immortality() {
    return const SkillDefinition(
      id: 'skill_immortality',
      name: 'Immortality',
      japaneseeName: '不死',
      description: 'HP0に到達した時、一度だけHP50で復活する。',
      effectType: SkillEffectType.immortality,
      triggerCondition: SkillTriggerCondition.onDamage,
      triggerRateByLevel: [1.0, 1.0, 1.0, 1.0], // Always triggers (once per game)
      valueByLevel: [50, 60, 70, 80],            // Revive HP
      durationTurns: null,
    );
  }

  /// 九尾の炎ダメージ拡散スキル
  factory SkillDefinition.spreadDamage() {
    return const SkillDefinition(
      id: 'skill_spread_damage',
      name: 'Spread Damage',
      japaneseeName: '炎ダメージ拡散',
      description: '攻撃成功時、隣接する敵駒に追加ダメージを与える。',
      effectType: SkillEffectType.spreadDamage,
      triggerCondition: SkillTriggerCondition.onAttackSuccess,
      triggerRateByLevel: [0.6, 0.7, 0.8, 0.9],
      valueByLevel: [20, 30, 40, 50],            // Extra damage per adjacent enemy
      rangeSquares: 1,                            // Adjacent squares
    );
  }

  /// 大蛇の被スキル無効（鉄壁）
  factory SkillDefinition.shieldTurns() {
    return const SkillDefinition(
      id: 'skill_shield_turns',
      name: 'Shield Turns',
      japaneseeName: '鉄壁',
      description: 'ターン開始時、敵のスキル効果を無効化する鉄壁を張る。',
      effectType: SkillEffectType.shieldTurns,
      triggerCondition: SkillTriggerCondition.onTurnStart,
      triggerRateByLevel: [0.7, 0.75, 0.85, 0.95],
      valueByLevel: [1, 1, 2, 2],                // Duration in turns
      durationTurns: 1,
    );
  }

  /// 天狗の追加ジャンプ
  factory SkillDefinition.jumpMove() {
    return const SkillDefinition(
      id: 'skill_jump_move',
      name: 'Jump Move',
      japaneseeName: '追加ジャンプ',
      description: '移動確定後、1マスの追加移動が可能になる。',
      effectType: SkillEffectType.jumpMove,
      triggerCondition: SkillTriggerCondition.onMove,
      triggerRateByLevel: [0.5, 0.6, 0.7, 0.8],
      valueByLevel: [1, 1, 1, 1],                // Extra squares
      rangeSquares: 1,
    );
  }

  /// Get all MVP skill definitions
  static List<SkillDefinition> mvpSkills() {
    return [
      SkillDefinition.immortality(),
      SkillDefinition.spreadDamage(),
      SkillDefinition.shieldTurns(),
      SkillDefinition.jumpMove(),
    ];
  }

  /// Get trigger rate for level
  double getTriggerRate(int level) {
    if (level < 1 || level > triggerRateByLevel.length) {
      return triggerRateByLevel.last;
    }
    return triggerRateByLevel[level - 1];
  }

  /// Get skill value for level
  int getValue(int level) {
    if (level < 1 || level > valueByLevel.length) {
      return valueByLevel.last;
    }
    return valueByLevel[level - 1];
  }
}
