import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/index.dart';
import '../../viewmodels/index.dart';

/// Card shown on the home screen for this week's challenges — a
/// longer-horizon complement to [DailyBonusWidget]'s daily missions,
/// reset every ISO week instead of every day.
class WeeklyChallengeWidget extends ConsumerWidget {
  const WeeklyChallengeWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final challengesState = ref.watch(weeklyChallengesProvider);
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
              '週替わりチャレンジ',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            challengesState.when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('エラー: $e'),
              data: (challenges) => Column(
                children: challenges
                    .map((c) => _ChallengeRow(
                          challenge: c,
                          onClaim: () =>
                              _claimChallenge(context, ref, c.type, userWardens),
                        ))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _claimChallenge(
    BuildContext context,
    WidgetRef ref,
    WeeklyChallengeType type,
    List<UserWarden> userWardens,
  ) async {
    final expReward =
        await ref.read(weeklyChallengesProvider.notifier).claimReward(type);
    if (expReward <= 0) return;

    final uid = ref.read(userIdProvider);
    if (uid != null && userWardens.isNotEmpty) {
      await ref
          .read(userWardenNotifierProvider(uid).notifier)
          .addExp(userWardens.first.wardenId, expReward);
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('チャレンジ達成！ +$expReward EXP')),
      );
    }
  }
}

class _ChallengeRow extends StatelessWidget {
  final WeeklyChallengeProgress challenge;
  final VoidCallback onClaim;

  const _ChallengeRow({required this.challenge, required this.onClaim});

  @override
  Widget build(BuildContext context) {
    final canClaim = challenge.isComplete && !challenge.rewardClaimed;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                challenge.rewardClaimed
                    ? Icons.check_circle
                    : challenge.isComplete
                        ? Icons.check_circle_outline
                        : Icons.radio_button_unchecked,
                color: challenge.isComplete ? Colors.green : Colors.grey,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${challenge.type.title} (${challenge.currentCount}/${challenge.type.targetCount})',
                ),
              ),
              if (challenge.rewardClaimed)
                const Text('受取済み', style: TextStyle(color: Colors.grey))
              else
                TextButton(
                  onPressed: canClaim ? onClaim : null,
                  child: const Text('受け取る'),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 28, bottom: 4),
            child: LinearProgressIndicator(
              value: (challenge.currentCount / challenge.type.targetCount)
                  .clamp(0, 1),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }
}
