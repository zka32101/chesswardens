import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/index.dart';
import '../viewmodels/index.dart';
import 'replay_screen.dart';

/// Lists past matches and lets the player jump into a replay ("観戦モード")
/// or share one publicly for others to watch.
class MatchHistoryScreen extends ConsumerWidget {
  const MatchHistoryScreen({Key? key}) : super(key: key);

  Future<void> _shareMatch(BuildContext context, WidgetRef ref, MatchLog match) async {
    final code = await ref.read(spectateShareNotifierProvider).share(match);
    if (!context.mounted) return;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('観戦コードを発行しました'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('このコードを友達に伝えると、誰でもこの対局を観戦できます。'),
            const SizedBox(height: 16),
            SelectableText(
              code,
              style: Theme.of(dialogContext).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: code));
              if (dialogContext.mounted) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(content: Text('コピーしました')),
                );
              }
            },
            child: const Text('コピー'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }

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
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.share),
                            tooltip: '観戦コードを発行',
                            onPressed: () => _shareMatch(context, ref, match),
                          ),
                          const Icon(Icons.play_circle_outline),
                        ],
                      )
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
