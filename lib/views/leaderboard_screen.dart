import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../viewmodels/index.dart';

/// Global leaderboard, ranked by total wins.
class LeaderboardScreen extends ConsumerWidget {
  const LeaderboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leaderboard = ref.watch(leaderboardProvider);
    final myUid = ref.watch(userIdProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('ランキング')),
      body: leaderboard.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (entries) {
          if (entries.isEmpty) {
            return const Center(child: Text('まだランキングデータがありません'));
          }

          return ListView.separated(
            itemCount: entries.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final entry = entries[index];
              final rank = index + 1;
              final isMe = entry.uid == myUid;

              return ListTile(
                tileColor: isMe ? Colors.amber.shade50 : null,
                leading: _RankBadge(rank: rank),
                title: Text(
                  isMe ? 'あなた' : entry.uid.substring(0, 8),
                  style: TextStyle(
                    fontWeight: isMe ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                subtitle: Text(
                  '${entry.totalWins}勝 / ${entry.totalMatches}戦'
                  ' ・ 勝率${(entry.winRate * 100).toStringAsFixed(0)}%'
                  ' ・ 最高連勝${entry.bestWinStreak}',
                ),
                trailing: Text(
                  '${entry.totalWins}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _RankBadge extends StatelessWidget {
  final int rank;

  const _RankBadge({required this.rank});

  @override
  Widget build(BuildContext context) {
    final color = switch (rank) {
      1 => Colors.amber,
      2 => Colors.grey,
      3 => Colors.brown.shade300,
      _ => Colors.grey.shade200,
    };

    return CircleAvatar(
      backgroundColor: color,
      child: Text(
        '$rank',
        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
      ),
    );
  }
}
