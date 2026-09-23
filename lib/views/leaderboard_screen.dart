import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/leaderboard_entry.dart';
import '../viewmodels/index.dart';

/// Leaderboard ranked by total wins, with a toggle between everyone and
/// just the caller's friends (see [friendAndSelfUidsProvider]).
class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen> {
  bool _friendsOnly = false;

  @override
  Widget build(BuildContext context) {
    final leaderboard = ref.watch(leaderboardProvider);
    final myUid = ref.watch(userIdProvider);
    final friendAndSelfUids = ref.watch(friendAndSelfUidsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('ランキング')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: false, label: Text('全体')),
                ButtonSegment(value: true, label: Text('フレンド')),
              ],
              selected: {_friendsOnly},
              onSelectionChanged: (selection) {
                setState(() => _friendsOnly = selection.first);
              },
            ),
          ),
          Expanded(
            child: leaderboard.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error: $err')),
              data: (entries) {
                final visible = _friendsOnly
                    ? filterToUids(entries, friendAndSelfUids)
                    : entries;

                if (visible.isEmpty) {
                  return Center(
                    child: Text(
                      _friendsOnly
                          ? 'フレンドのランキングデータがありません\n（フレンド画面でコードを交換しましょう）'
                          : 'まだランキングデータがありません',
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                return ListView.separated(
                  itemCount: visible.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final entry = visible[index];
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
          ),
        ],
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
