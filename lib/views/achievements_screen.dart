import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/achievement.dart';
import '../viewmodels/achievement_provider.dart';

/// Lists all achievements with their unlock progress.
class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final achievementState = ref.watch(achievementProvider);
    final wardensUnlockedCount = ref.watch(wardensUnlockedCountProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('実績')),
      body: achievementState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (state) {
          final unlockedCount = AchievementId.values
              .where((id) => state.stats.isUnlocked(
                    id,
                    wardensUnlockedCount: wardensUnlockedCount,
                  ))
              .length;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  '達成: $unlockedCount / ${AchievementId.values.length}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: AchievementId.values.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final id = AchievementId.values[index];
                    final progress = state.stats.progressFor(
                      id,
                      wardensUnlockedCount: wardensUnlockedCount,
                    );
                    final isUnlocked = progress >= id.targetValue;

                    return Card(
                      color: isUnlocked ? Colors.amber.shade50 : null,
                      child: ListTile(
                        leading: Icon(
                          isUnlocked
                              ? Icons.emoji_events
                              : Icons.emoji_events_outlined,
                          color: isUnlocked ? Colors.amber.shade700 : Colors.grey,
                        ),
                        title: Text(
                          id.title,
                          style: TextStyle(
                            fontWeight:
                                isUnlocked ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(id.description),
                            const SizedBox(height: 4),
                            LinearProgressIndicator(
                              value: (progress / id.targetValue).clamp(0, 1),
                              minHeight: 6,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${progress.clamp(0, id.targetValue)} / ${id.targetValue}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                        isThreeLine: true,
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
