import 'dart:math';
import '../models/index.dart';

/// Manages skill triggering and effect application
class SkillEvaluationService {
  final Random _random = Random();

  /// Check if skill should trigger based on condition and level
  bool shouldTriggerSkill(
    SkillDefinition skill,
    int wardenLevel,
  ) {
    final triggerRate = skill.getTriggerRate(wardenLevel);
    return _random.nextDouble() < triggerRate;
  }

  /// Get skill effect value for warden level
  int getSkillValue(
    SkillDefinition skill,
    int wardenLevel,
  ) {
    return skill.getValue(wardenLevel);
  }

  /// Evaluate skill contribution to board evaluation (for chess engine)
  int evaluateSkillContribution(
    SkillDefinition skill,
    bool isActive,
    int wardenLevel,
  ) {
    if (!isActive) return 0;

    final baseValue = getSkillValue(skill, wardenLevel);

    switch (skill.effectType) {
      case SkillEffectType.immortality:
        // Immortality is extremely valuable (second life)
        return baseValue * 150;

      case SkillEffectType.spreadDamage:
        // Spread damage bonus for area control
        return baseValue * 30;

      case SkillEffectType.shieldTurns:
        // Shield (skill negation) provides strong defense
        return baseValue * 100;

      case SkillEffectType.jumpMove:
        // Extra mobility bonus (tactical advantage)
        return baseValue * 40;
    }
  }

  /// Apply skill effect to board state (simplified)
  void applySkillEffect(
    SkillDefinition skill,
    int value,
  ) {
    // In a full implementation, this would modify board state
    // Based on skill effect type
    // For now, this is a placeholder for the evaluation function
  }

  /// Calculate skill cooldown for next activation
  int getSkillCooldown(SkillDefinition skill, int activations) {
    // More activations = longer cooldown
    return max(1, 3 - (activations ~/ 2));
  }

  /// Evaluate skill combo potential (future LiveOps)
  double evaluateSkillSynergy(
    List<SkillDefinition> activeSkills,
  ) {
    // Placeholder for skill combination evaluation
    // Could be extended for LiveOps phase with new wardens
    double synergy = 1.0;

    // Example: Immortality + Shield synergy
    final hasImmortality = activeSkills.any(
      (s) => s.effectType == SkillEffectType.immortality,
    );
    final hasShield =
        activeSkills.any((s) => s.effectType == SkillEffectType.shieldTurns);

    if (hasImmortality && hasShield) {
      synergy *= 1.2; // 20% bonus for synergy
    }

    return synergy;
  }
}
