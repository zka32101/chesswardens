# Lottie Animations for Chess Wardens

This document describes the skill effect animation system powered by Lottie.

## Overview

Chess Wardens uses Lottie animations to visualize skill effects during gameplay. Each of the 4 MVP wardens has a unique skill with a corresponding animation effect.

## Animation Files

All animation files are stored in `assets/animations/` and referenced in `pubspec.yaml`.

### Skill Animations

| Skill | File | Duration | Warden | Effect |
|-------|------|----------|--------|--------|
| Immortality | `skill_immortality.json` | 1.5s | Oni King (鬼王) | Purple/white revive effect with expanding circles |
| Spread Damage | `skill_spread_damage.json` | 1.0s | Kitsune (キツネ) | Orange-red damage waves radiating outward |
| Shield Turns | `skill_shield_turns.json` | 1.2s | Orochi (大蛇) | Blue shield formation with protective glow |
| Jump Move | `skill_jump_move.json` | 1.0s | Tengu (天狗) | Swift purple-blue jump arc with landing impact |

## Implementation Architecture

### Service Layer

**`lib/services/skill_animation_service.dart`**

Centralized service for animation configuration:
- Maps `SkillEffectType` to animation asset paths
- Defines animation durations for each skill
- Provides helper methods for animation management
- Includes animation descriptions for debugging

```dart
// Get animation asset
String asset = SkillAnimationService.getAnimationAsset(SkillEffectType.immortality);

// Get animation duration
Duration duration = SkillAnimationService.getAnimationDuration(SkillEffectType.immortality);
```

### Widget Layer

**`lib/views/widgets/skill_animation_overlay.dart`**

Two main widgets for animation display:

#### 1. `SkillAnimationOverlay`
- Core Lottie animation player
- Takes `SkillEffectType` and optional completion callback
- Handles animation lifecycle and controller management
- Includes error fallback UI if animation file not found

#### 2. `SkillAnimationDisplay`
- Full-featured animation display with UI context
- Shows warden name and skill name labels
- Semi-transparent background overlay
- Fade in/out effects for smooth transitions
- Triggers callbacks on completion

### Integration

**`lib/views/match_screen.dart`**

The match screen integrates animations during gameplay:

1. **State Tracking**: Maintains animation state variables
   - `displayingSkillAnimation`: Current skill effect type
   - `displayingWardenName`: Warden that triggered the skill
   - `displayingSkillName`: Skill name for display

2. **Animation Trigger**: Skills animate when:
   - Player makes a capture move (high probability Aha Moment)
   - A random skill from the MVP skills list is selected
   - Animation plays while AI calculates its move

3. **UI Integration**: Animation overlays the game board using a Stack widget

## Usage Examples

### Triggering an Animation Programmatically

```dart
// In any ConsumerWidget/ConsumerStatefulWidget:
setState(() {
  displayingSkillAnimation = SkillEffectType.spreadDamage;
  displayingWardenName = 'Kitsune';
  displayingSkillName = 'Spread Damage';
});

// Animation automatically completes and resets state
```

### Creating Custom Animation Widgets

```dart
// Simple animation overlay
SkillAnimationOverlay(
  effectType: SkillEffectType.shieldTurns,
  onAnimationComplete: () => print('Shield animation done'),
)

// Full display with labels
SkillAnimationDisplay(
  effectType: SkillEffectType.immortality,
  wardenName: 'Oni King',
  skillName: 'Immortality',
  onAnimationComplete: () => setState(() { /* reset */ }),
  displayDuration: Duration(milliseconds: 1800),
)
```

## Customizing Animations

### Replacing Animation Files

1. Create a new Lottie JSON file in `assets/animations/`
2. Name it following the pattern: `skill_<effect_name>.json`
3. Update `SkillAnimationService` to reference the new file
4. Adjust duration if needed in `skillAnimationDurations` map

### Animation Design Guidelines

- **Frame Rate**: 30 FPS (standard for mobile)
- **Resolution**: 300x300px (mobile-optimized)
- **Durations**: 0.8-1.5 seconds (avoid long animations interrupting gameplay)
- **Colors**: Use skill theme colors:
  - Immortality: Purple (#CC66FF) + White
  - Spread Damage: Orange (#FF9933) + Red (#FF4444)
  - Shield Turns: Blue (#4488FF) + Cyan (#44DDFF)
  - Jump Move: Purple (#AA66FF) + Blue (#4488FF)

### Professional Animation Tools

Recommended tools for creating Lottie animations:
- [Adobe Animate](https://www.adobe.com/products/animate.html)
- [LottieFiles](https://lottiefiles.com/) - Free community animations
- [Figma with LottieFiles plugin](https://lottiefiles.com/figma)
- [Blender + Lottie exporter](https://github.com/jmhobbs/lottie-blender)

## Performance Considerations

### Optimization Tips

1. **Asset Caching**: Lottie automatically caches decoded animations in memory
2. **Preloading**: Consider preloading animations during app startup for instant playback
3. **Single Overlay**: Only one skill animation displays at a time
4. **Async Operations**: Animation doesn't block game AI calculations

### Mobile Performance

- Animation files are lightweight (~5-15KB each in JSON format)
- No impact on frame rate during gameplay
- Completes before AI move, preventing animation skipping

## Testing

### Manual Testing

```bash
# Run the app and observe animations
flutter run

# Trigger animations:
# 1. Navigate to a match
# 2. Make a capture move
# 3. Watch for Lottie animation overlay
```

### Unit Testing Animations

```dart
// Test animation service configuration
test('Immortality animation asset path', () {
  expect(
    SkillAnimationService.getAnimationAsset(SkillEffectType.immortality),
    'assets/animations/skill_immortality.json',
  );
});

// Test animation durations
test('Animation durations are valid', () {
  for (final duration in SkillAnimationService.skillAnimationDurations.values) {
    expect(duration.inMilliseconds, greaterThan(500));
    expect(duration.inMilliseconds, lessThan(2000));
  }
});
```

## Future Enhancements

### Phase 2+ Animation Features

- [ ] **Combo Animations**: When multiple skills trigger in sequence
- [ ] **Board Impact Zones**: Highlight affected squares during animation
- [ ] **Sound Effects**: Pair animations with skill sound effects
- [ ] **Particle Effects**: Add particle system overlays to Lottie
- [ ] **Physics-Based Animation**: Real-time skill effect simulation
- [ ] **Character Animations**: Animated warden sprites alongside skill effects
- [ ] **Story/Cinematic Animations**: Special animations for important match moments

## Troubleshooting

### Animation Not Playing

1. **Check Asset Path**: Verify animation file exists in `assets/animations/`
2. **Verify Lottie Dependency**: Run `flutter pub get`
3. **Check Device Logs**: Look for Lottie error messages

```dart
// Example error handling
LottieBuilder.asset(
  'assets/animations/skill_immortality.json',
  errorBuilder: (context, error, stackTrace) {
    print('Animation error: $error');
    return fallbackWidget();
  },
)
```

### Animation Lags or Stutters

1. **Reduce Animation Complexity**: Simplify vector paths
2. **Optimize JSON**: Minify animation JSON files
3. **Preload Animations**: Load before gameplay starts
4. **Check Device Performance**: May be slow on older devices

### Animation Duration Mismatch

Verify duration calculation:
```dart
// Animation duration should match JSON composition duration
// Lottie automatically adjusts controller to match JSON
// If mismatch occurs, explicitly set:
controller.duration = composition.duration;
```

## References

- [Lottie Documentation](https://airbnb.io/lottie/)
- [Flutter Lottie Package](https://pub.dev/packages/lottie)
- [LottieFiles Community](https://lottiefiles.com/)
- [Chess Wardens Animation Design](./docs/ANIMATION_DESIGNS.md) (future reference)

---

**Last Updated**: 2026-09-08  
**Maintainer**: Chess Wardens Team
