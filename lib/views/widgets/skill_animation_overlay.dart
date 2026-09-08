import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:chesswardens/models/enums.dart';
import 'package:chesswardens/services/skill_animation_service.dart';

/// Displays a Lottie animation overlay when a skill is triggered
/// Used to visualize skill effects during chess matches
class SkillAnimationOverlay extends StatefulWidget {
  final SkillEffectType effectType;
  final VoidCallback? onAnimationComplete;

  const SkillAnimationOverlay({
    Key? key,
    required this.effectType,
    this.onAnimationComplete,
  }) : super(key: key);

  @override
  State<SkillAnimationOverlay> createState() => _SkillAnimationOverlayState();
}

class _SkillAnimationOverlayState extends State<SkillAnimationOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isPlaying = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: SkillAnimationService.getAnimationDuration(widget.effectType),
      vsync: this,
    );

    _controller.forward().then((_) {
      if (mounted) {
        widget.onAnimationComplete?.call();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 300,
        height: 300,
        child: Lottie.asset(
          SkillAnimationService.getAnimationAsset(widget.effectType),
          controller: _controller,
          onLoaded: (composition) {
            // Animation loaded successfully
            _controller.duration = composition.duration;
          },
          errorBuilder: (context, error, stackTrace) {
            // Fallback if Lottie file not found
            return Container(
              decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.3),
                borderRadius: BorderRadius.circular(150),
              ),
              child: Center(
                child: Text(
                  '⚡ Skill Triggered',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Wrapper widget that provides context-aware skill animation display
/// Can be used to show animations centered on board or specific squares
class SkillAnimationDisplay extends StatefulWidget {
  final SkillEffectType effectType;
  final String wardenName;
  final String skillName;
  final VoidCallback? onAnimationComplete;
  final Duration? displayDuration;

  const SkillAnimationDisplay({
    Key? key,
    required this.effectType,
    required this.wardenName,
    required this.skillName,
    this.onAnimationComplete,
    this.displayDuration,
  }) : super(key: key);

  @override
  State<SkillAnimationDisplay> createState() => _SkillAnimationDisplayState();
}

class _SkillAnimationDisplayState extends State<SkillAnimationDisplay>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  final duration = const Duration(milliseconds: 1500);

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(duration: duration, vsync: this);
    _fadeController.forward();

    Future.delayed(widget.displayDuration ?? duration, () {
      if (mounted) {
        _fadeController.reverse().then((_) {
          widget.onAnimationComplete?.call();
        });
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeController,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Semi-transparent background
          Container(
            color: Colors.black.withOpacity(0.2),
          ),
          // Animation
          SkillAnimationOverlay(
            effectType: widget.effectType,
            onAnimationComplete: () {
              // Animation complete callback
            },
          ),
          // Skill name label
          Positioned(
            bottom: 50,
            child: Column(
              children: [
                Text(
                  '${widget.wardenName}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '✨ ${widget.skillName}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
