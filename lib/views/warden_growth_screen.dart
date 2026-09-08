import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/index.dart';
import '../viewmodels/index.dart';

/// Warden growth screen - View and manage warden progression
class WardenGrowthScreen extends ConsumerStatefulWidget {
  final UserWarden userWarden;
  final Warden wardenDefinition;

  const WardenGrowthScreen({
    Key? key,
    required this.userWarden,
    required this.wardenDefinition,
  }) : super(key: key);

  @override
  ConsumerState<WardenGrowthScreen> createState() => _WardenGrowthScreenState();
}

class _WardenGrowthScreenState extends ConsumerState<WardenGrowthScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _levelUpController;

  @override
  void initState() {
    super.initState();
    _levelUpController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _levelUpController.dispose();
    super.dispose();
  }

  Future<void> _attemptLevelUp() async {
    if (!widget.userWarden.canLevelUp()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('レベルアップの条件を満たしていません')),
      );
      return;
    }

    // Perform level up
    _levelUpController.forward(from: 0.0);

    final uid = ref.read(userIdProvider);
    if (uid != null) {
      final updatedWarden = widget.userWarden.levelUp();
      await ref
          .read(userWardenNotifierProvider(uid).notifier)
          .updateWarden(updatedWarden);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'レベル ${updatedWarden.level} にアップ！',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final skill = ref.watch(skillByIdProvider(widget.wardenDefinition.skillId));
    final nextLevelExp =
        widget.userWarden.expRequiredForNextLevel(widget.userWarden.level);
    final expProgress = widget.userWarden.exp / nextLevelExp;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.wardenDefinition.japaneseeName),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Warden header with large display
            _buildWardenHeader(),
            const SizedBox(height: 24),

            // Status section
            _buildStatusSection(context, nextLevelExp),
            const SizedBox(height: 24),

            // EXP progress section
            _buildExpProgressSection(context, expProgress, nextLevelExp),
            const SizedBox(height: 24),

            // Skill section
            if (skill != null) _buildSkillSection(context, skill),
            const SizedBox(height: 24),

            // Stats section
            _buildStatsSection(context),
            const SizedBox(height: 24),

            // Level up button
            _buildLevelUpButton(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildWardenHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.purple.shade300,
            Colors.purple.shade100,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        children: [
          // Warden icon/emoji placeholder
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(60),
              border: Border.all(
                color: Colors.white,
                width: 3,
              ),
            ),
            child: Center(
              child: Text(
                _getWardenEmoji(),
                style: const TextStyle(fontSize: 80),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Warden name
          Text(
            widget.wardenDefinition.japaneseeName,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.wardenDefinition.name,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusSection(BuildContext context, int nextLevelExp) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ステータス',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _StatusRow(
            label: 'レベル',
            value: widget.userWarden.level.toString(),
            icon: '📊',
          ),
          const SizedBox(height: 12),
          _StatusRow(
            label: '経験値',
            value: '${widget.userWarden.exp} / $nextLevelExp',
            icon: '⭐',
          ),
          const SizedBox(height: 12),
          _StatusRow(
            label: 'HP',
            value: _calculateHp().toString(),
            icon: '❤️',
          ),
          const SizedBox(height: 12),
          _StatusRow(
            label: '攻撃力',
            value: _calculateAttack().toString(),
            icon: '⚔️',
          ),
          const SizedBox(height: 12),
          _StatusRow(
            label: '防御力',
            value: _calculateDefense().toString(),
            icon: '🛡️',
          ),
        ],
      ),
    );
  }

  Widget _buildExpProgressSection(
    BuildContext context,
    double progress,
    int nextLevelExp,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.amber.shade50, Colors.orange.shade50],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '次のレベルまで',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${(progress * 100).toStringAsFixed(1)}%',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 16,
              backgroundColor: Colors.orange.shade100,
              valueColor: AlwaysStoppedAnimation<Color>(
                Colors.orange.shade400,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '${widget.userWarden.exp} / $nextLevelExp EXP',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildSkillSection(BuildContext context, SkillDefinition skill) {
    final currentLevel = widget.userWarden.level;
    final skillTriggerRate = skill.getTriggerRate(currentLevel);
    final skillValue = skill.getValue(currentLevel);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.purple.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purple.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🔮', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ユニークスキル',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      skill.japaneseeName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.purple,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            skill.description,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          Divider(color: Colors.purple.shade200),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '発動率',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                  Text(
                    '${(skillTriggerRate * 100).toStringAsFixed(0)}%',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'スキル値',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                  Text(
                    skillValue.toString(),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '発動条件',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                  Text(
                    _getTriggerConditionLabel(skill.triggerCondition),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '詳細情報',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _DetailRow(
            label: 'ワーデンID',
            value: widget.wardenDefinition.id,
          ),
          const SizedBox(height: 8),
          _DetailRow(
            label: 'タイプ',
            value: widget.wardenDefinition.baseType,
          ),
          const SizedBox(height: 8),
          _DetailRow(
            label: 'アンロック日時',
            value: widget.userWarden.unlockedAt
                .toString()
                .split('.')
                .first,
          ),
        ],
      ),
    );
  }

  Widget _buildLevelUpButton() {
    final canLevelUp = widget.userWarden.canLevelUp();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ScaleTransition(
        scale: Tween<double>(begin: 1.0, end: 1.05).animate(_levelUpController),
        child: ElevatedButton.icon(
          onPressed: canLevelUp ? _attemptLevelUp : null,
          icon: const Icon(Icons.arrow_upward),
          label: const Text('レベルアップ！'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor:
                canLevelUp ? Colors.green : Colors.grey.shade400,
            foregroundColor: Colors.white,
            disabledForegroundColor: Colors.grey.shade600,
            minimumSize: const Size(double.infinity, 50),
          ),
        ),
      ),
    );
  }

  int _calculateHp() {
    return widget.wardenDefinition.baseHp +
        (widget.userWarden.level - 1) * 5;
  }

  int _calculateAttack() {
    return widget.wardenDefinition.baseAttack +
        (widget.userWarden.level - 1) * 2;
  }

  int _calculateDefense() {
    return widget.wardenDefinition.baseDefense +
        (widget.userWarden.level - 1) * 2;
  }

  String _getWardenEmoji() {
    switch (widget.wardenDefinition.id) {
      case 'oni_king':
        return '👹';
      case 'kitsune':
        return '🦊';
      case 'orochi':
        return '🐍';
      case 'tengu':
        return '🌪️';
      default:
        return '✨';
    }
  }

  String _getTriggerConditionLabel(SkillTriggerCondition condition) {
    switch (condition) {
      case SkillTriggerCondition.onDamage:
        return 'ダメージ時';
      case SkillTriggerCondition.onAttackSuccess:
        return '攻撃成功時';
      case SkillTriggerCondition.onTurnStart:
        return 'ターン開始時';
      case SkillTriggerCondition.onMove:
        return '移動時';
    }
  }
}

/// Status row widget
class _StatusRow extends StatelessWidget {
  final String label;
  final String value;
  final String icon;

  const _StatusRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 12),
            Text(label),
          ],
        ),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}

/// Detail row widget
class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        Text(
          value,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
