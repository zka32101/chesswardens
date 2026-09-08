import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/index.dart';
import '../services/skill_animation_service.dart';
import '../viewmodels/index.dart';
import 'share_card_screen.dart';

/// Match result screen - Shows battle results and rewards
class MatchResultScreen extends ConsumerStatefulWidget {
  final MatchResult result;
  final int playerScore;
  final int aiScore;
  final int skillTriggeredCount;
  final int movesPlayed;
  final Duration? matchDuration;
  final AIDifficulty aiDifficulty;
  final List<String> playerWardenIds;

  const MatchResultScreen({
    Key? key,
    required this.result,
    required this.playerScore,
    required this.aiScore,
    required this.skillTriggeredCount,
    required this.movesPlayed,
    this.matchDuration,
    required this.aiDifficulty,
    required this.playerWardenIds,
  }) : super(key: key);

  @override
  ConsumerState<MatchResultScreen> createState() => _MatchResultScreenState();
}

class _MatchResultScreenState extends ConsumerState<MatchResultScreen>
    with TickerProviderStateMixin {
  late AnimationController _confettiController;
  late AnimationController _expController;
  bool _showExpGain = false;

  @override
  void initState() {
    super.initState();
    _confettiController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _expController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Auto-play animations
    if (widget.result == MatchResult.win) {
      _confettiController.forward();
    }

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() => _showExpGain = true);
        _expController.forward();
      }
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _expController.dispose();
    super.dispose();
  }

  int _calculateExpGain() {
    int baseExp = widget.result == MatchResult.win ? 100 : 50;
    int skillBonus = widget.skillTriggeredCount * 10;
    return baseExp + skillBonus;
  }

  @override
  Widget build(BuildContext context) {
    final expGain = _calculateExpGain();
    final isWin = widget.result == MatchResult.win;

    return Scaffold(
      body: Stack(
        children: [
          // Main content
          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 32),

                  // Result header
                  _buildResultHeader(isWin),
                  const SizedBox(height: 32),

                  // Match statistics
                  _buildStatisticsSection(),
                  const SizedBox(height: 32),

                  // Experience gain
                  if (_showExpGain) _buildExpGainSection(expGain),
                  const SizedBox(height: 32),

                  // Warden rewards
                  _buildWardenRewardsSection(),
                  const SizedBox(height: 32),

                  // Action buttons
                  _buildActionButtons(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),

          // Confetti animation (win only)
          if (isWin)
            IgnorePointer(
              child: _ConfettiAnimation(
                controller: _confettiController,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildResultHeader(bool isWin) {
    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: isWin
                ? Colors.green.withOpacity(0.1)
                : Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(50),
          ),
          child: Center(
            child: Text(
              isWin ? '🎉' : '😢',
              style: const TextStyle(fontSize: 60),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          isWin ? '勝利！' : '敗北',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: isWin ? Colors.green : Colors.red,
          ),
        ),
      ],
    );
  }

  Widget _buildStatisticsSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            'バトル統計',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatItem(
                label: 'あなたのスコア',
                value: widget.playerScore.toString(),
                icon: '♔',
              ),
              _StatItem(
                label: 'AI のスコア',
                value: widget.aiScore.toString(),
                icon: '♚',
              ),
            ],
          ),
          const SizedBox(height: 20),
          Divider(color: Colors.grey.shade300),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatItem(
                label: '移動数',
                value: widget.movesPlayed.toString(),
                icon: '♘',
              ),
              _StatItem(
                label: 'スキル発動',
                value: widget.skillTriggeredCount.toString(),
                icon: '✨',
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (widget.matchDuration != null)
            Text(
              '試合時間: ${widget.matchDuration!.inMinutes}:${(widget.matchDuration!.inSeconds % 60).toString().padLeft(2, '0')}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
        ],
      ),
    );
  }

  Widget _buildExpGainSection(int expGain) {
    return ScaleTransition(
      scale: Tween<double>(begin: 0.5, end: 1.0).animate(_expController),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.amber.shade100,
              Colors.orange.shade100,
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.orange.shade300, width: 2),
        ),
        child: Column(
          children: [
            Text(
              '獲得経験値',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '+$expGain EXP',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.orange.shade700,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '基本経験値 100 + スキルボーナス ${widget.skillTriggeredCount * 10}',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWardenRewardsSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              'ワーデンの報酬',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 12),
          ...List.generate(
            widget.playerWardenIds.length,
            (index) => _WardenRewardItem(
              wardenId: widget.playerWardenIds[index],
              expGain: _calculateExpGain() ~/ widget.playerWardenIds.length,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Share button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ShareCardScreen(
                      result: widget.result,
                      playerScore: widget.playerScore,
                      aiScore: widget.aiScore,
                      skillTriggeredCount: widget.skillTriggeredCount,
                      playerWardenIds: widget.playerWardenIds,
                      aiDifficulty: widget.aiDifficulty,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.share),
              label: const Text('結果をシェア'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Back to home button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).popUntil(
                  (route) => route.isFirst,
                );
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('ホームに戻る'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Statistics item widget
class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final String icon;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(icon, style: const TextStyle(fontSize: 28)),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

/// Warden reward item
class _WardenRewardItem extends ConsumerWidget {
  final String wardenId;
  final int expGain;

  const _WardenRewardItem({
    required this.wardenId,
    required this.expGain,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allWardens = ref.watch(mvpWardensProvider);
    final warden = allWardens.firstWhere(
      (w) => w.id == wardenId,
      orElse: () => allWardens.first,
    );

    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  warden.japaneseeName,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  warden.name,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.orange.shade100,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '+$expGain EXP',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.orange.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Confetti animation widget
class _ConfettiAnimation extends StatelessWidget {
  final AnimationController controller;

  const _ConfettiAnimation({
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return Stack(
          children: List.generate(
            20,
            (index) {
              final angle = (index / 20) * 2 * 3.14159;
              final distance = 200.0 * controller.value;
              final dx = distance * math.cos(angle);
              final dy = distance * math.sin(angle) + (200 * controller.value);

              return Positioned(
                left: MediaQuery.of(context).size.width / 2 + dx,
                top: -50 + dy,
                child: Opacity(
                  opacity: (1 - controller.value),
                  child: Text(
                    ['🎉', '🎊', '⭐', '✨'][index % 4],
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

import 'dart:math' as math;
