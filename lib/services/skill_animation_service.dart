import 'package:chesswardens/models/enums.dart';

/// Maps skill effects to their corresponding Lottie animation asset paths
class SkillAnimationService {
  static const Map<SkillEffectType, String> skillAnimationAssets = {
    SkillEffectType.immortality: 'assets/animations/skill_immortality.json',
    SkillEffectType.spreadDamage: 'assets/animations/skill_spread_damage.json',
    SkillEffectType.shieldTurns: 'assets/animations/skill_shield_turns.json',
    SkillEffectType.jumpMove: 'assets/animations/skill_jump_move.json',
  };

  /// Duration in milliseconds for each skill animation
  /// Based on Lottie frame count and frame rate (30 FPS)
  static const Map<SkillEffectType, Duration> skillAnimationDurations = {
    SkillEffectType.immortality: Duration(milliseconds: 1500), // 45 frames @ 30fps
    SkillEffectType.spreadDamage: Duration(milliseconds: 1000), // 30 frames @ 30fps
    SkillEffectType.shieldTurns: Duration(milliseconds: 1200), // 36 frames @ 30fps
    SkillEffectType.jumpMove: Duration(milliseconds: 1000), // 30 frames @ 30fps
  };

  /// Get the Lottie animation asset path for a skill effect
  static String getAnimationAsset(SkillEffectType effectType) {
    return skillAnimationAssets[effectType] ?? 'assets/animations/skill_immortality.json';
  }

  /// Get the animation duration for a skill effect
  static Duration getAnimationDuration(SkillEffectType effectType) {
    return skillAnimationDurations[effectType] ?? const Duration(milliseconds: 1500);
  }

  /// Get a user-friendly description of the skill animation
  static String getAnimationDescription(SkillEffectType effectType) {
    switch (effectType) {
      case SkillEffectType.immortality:
        return 'Revive with HP restored in a purple glow';
      case SkillEffectType.spreadDamage:
        return 'Damage spreads in orange-red waves to nearby pieces';
      case SkillEffectType.shieldTurns:
        return 'Blue shield forms to protect from damage';
      case SkillEffectType.jumpMove:
        return 'Swift jump with purple-blue arc trail';
    }
  }
}
