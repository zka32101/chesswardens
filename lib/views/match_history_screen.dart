import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/index.dart';
import '../viewmodels/index.dart';
import 'replay_screen.dart';

/// Lists past matches and lets the player jump into a replay ("観戦モード").
class MatchHistoryScreen extends ConsumerWidget {
  const MatchHistoryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(matchHistoryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('対局履歴')),
      body: history.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (matches) {
          if (matches.isEmpty) {
            return const Center(child: Text('対局履歴がありません'));
          }

          return ListView.separated(
            itemCount: matches.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final match = matches[index];
              return ListTile(
                leading: Icon(
                  match.result == MatchResult.win
                      ? Icons.emoji_events
                      : match.result == MatchResult.loss
                          ? Icons.close
                          : Icons.remove,
                  color: match.result == MatchResult.win
                      ? Colors.amber
                      : match.result == MatchResult.loss
                          ? Colors.red
                          : Colors.grey,
                ),
                title: Text(
                  '${match.result.label} — ${match.aiDifficulty.label}',
                ),
                subtitle: Text(
                  '${DateFormat('yyyy/MM/dd HH:mm').format(match.playedAt)}'
                  ' ・ ${match.movesPlayed}手 ・ スキル${match.skillTriggeredCount}回',
                ),
                trailing: match.hasReplay
                    ? const Icon(Icons.play_circle_outline)
                    : null,
                onTap: match.hasReplay
                    ? () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ReplayScreen(matchLog: match),
                          ),
                        );
                      }
                    : null,
              );
            },
          );
        },
      ),
    );
  }
}
