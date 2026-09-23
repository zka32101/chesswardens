import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/index.dart';
import '../../viewmodels/index.dart';

/// Card shown on the home screen for the daily login bonus and today's
/// missions. EXP rewards are granted to the player's first owned Warden.
class DailyBonusWidget extends ConsumerWidget {
  const DailyBonusWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bonusState = ref.watch(dailyBonusProvider);
    final missionsState = ref.watch(dailyMissionsProvider);
    final userWardens = ref.watch(userWardensProvider).valueOrNull ?? [];

    if (userWardens.isEmpty) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'デイリーログインボーナス',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            bonusState.when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('エラー: $e'),
              data: (bonus) => _BonusRow(
                bonus: bonus,
                canClaim: ref.watch(dailyBonusProvider.notifier).canClaimToday,
                onClaim: () => _claimBonus(context, ref, userWardens),
              ),
            ),
            const Divider(height: 24),
            Text(
              'デイリーミッション',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            missionsState.when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('エラー: $e'),
              data: (missions) => Column(
                children: missions
                    .map((m) => _MissionRow(
                          mission: m,
                          onClaim: () =>
                              _claimMission(context, ref, m.type, userWardens),
                        ))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _claimBonus(
    BuildContext context,
    WidgetRef ref,
    List<UserWarden> userWardens,
  ) async {
    final expReward = await ref.read(dailyBonusProvider.notifier).claim();
    if (expReward <= 0) return;
    await _grantExp(ref, userWardens, expReward);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ログインボーナス +$expReward EXP！')),
      );
    }
  }

  Future<void> _claimMission(
    BuildContext context,
    WidgetRef ref,
    DailyMissionType type,
    List<UserWarden> userWardens,
  ) async {
    final expReward =
        await ref.read(dailyMissionsProvider.notifier).claimReward(type);
    if (expReward <= 0) return;
    await _grantExp(ref, userWardens, expReward);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ミッション達成！ +$expReward EXP')),
      );
    }
  }

  Future<void> _grantExp(
    WidgetRef ref,
    List<UserWarden> userWardens,
    int amount,
  ) async {
    final uid = ref.read(userIdProvider);
    if (uid == null || userWardens.isEmpty) return;
    await ref
        .read(userWardenNotifierProvider(uid).notifier)
        .addExp(userWardens.first.wardenId, amount);
  }
}

class _BonusRow extends StatelessWidget {
  final DailyBonusState bonus;
  final bool canClaim;
  final VoidCallback onClaim;

  const _BonusRow({
    required this.bonus,
    required this.canClaim,
    required this.onClaim,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text('連続ログイン ${bonus.consecutiveDays} 日目'),
        ),
        ElevatedButton(
          onPressed: canClaim ? onClaim : null,
          child: Text(canClaim ? '受け取る' : '受取済み'),
        ),
      ],
    );
  }
}

class _MissionRow extends StatelessWidget {
  final DailyMissionProgress mission;
  final VoidCallback onClaim;

  const _MissionRow({required this.mission, required this.onClaim});

  @override
  Widget build(BuildContext context) {
    final canClaim = mission.isComplete && !mission.rewardClaimed;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            mission.rewardClaimed
                ? Icons.check_circle
                : mission.isComplete
                    ? Icons.check_circle_outline
                    : Icons.radio_button_unchecked,
            color: mission.isComplete ? Colors.green : Colors.grey,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${mission.type.title} (${mission.currentCount}/${mission.type.targetCount})',
            ),
          ),
          if (mission.rewardClaimed)
            const Text('受取済み', style: TextStyle(color: Colors.grey))
          else
            TextButton(
              onPressed: canClaim ? onClaim : null,
              child: const Text('受け取る'),
            ),
        ],
      ),
    );
  }
}
