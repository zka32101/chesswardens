import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/index.dart';
import '../viewmodels/index.dart';
import 'multiplayer_match_screen.dart';

/// Lobby for creating or joining an asynchronous friend match via a
/// short invite code.
class MultiplayerLobbyScreen extends ConsumerStatefulWidget {
  const MultiplayerLobbyScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<MultiplayerLobbyScreen> createState() =>
      _MultiplayerLobbyScreenState();
}

class _MultiplayerLobbyScreenState
    extends ConsumerState<MultiplayerLobbyScreen> {
  final _codeController = TextEditingController();
  bool _isBusy = false;
  MultiplayerMatch? _createdMatch;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  List<String> _myWardenIds(List<UserWarden> wardens) =>
      wardens.map((w) => w.wardenId).take(4).toList();

  Future<void> _createMatch(List<UserWarden> wardens) async {
    final uid = ref.read(userIdProvider);
    if (uid == null) return;

    setState(() => _isBusy = true);
    try {
      final match = await ref
          .read(multiplayerServiceProvider)
          .createMatch(uid, _myWardenIds(wardens));
      setState(() => _createdMatch = match);
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _joinMatch(List<UserWarden> wardens) async {
    final uid = ref.read(userIdProvider);
    final code = _codeController.text.trim();
    if (uid == null || code.isEmpty) return;

    setState(() => _isBusy = true);
    try {
      final match = await ref
          .read(multiplayerServiceProvider)
          .joinMatch(code, uid, _myWardenIds(wardens));

      if (!mounted) return;

      if (match == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('招待コードが見つかりませんでした')),
        );
        return;
      }

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => MultiplayerMatchScreen(matchId: match.id),
        ),
      );
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final wardens = ref.watch(userWardensProvider).valueOrNull ?? [];
    final createdMatch = _createdMatch;

    return Scaffold(
      appBar: AppBar(title: const Text('フレンド対戦')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (createdMatch != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Text('この招待コードを相手に伝えてください'),
                      const SizedBox(height: 8),
                      Text(
                        createdMatch.inviteCode,
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 4,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text('相手が参加すると自動的に対局が始まります'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (_) =>
                          MultiplayerMatchScreen(matchId: createdMatch.id),
                    ),
                  );
                },
                child: const Text('待機画面へ'),
              ),
            ] else ...[
              ElevatedButton(
                onPressed: _isBusy || wardens.isEmpty
                    ? null
                    : () => _createMatch(wardens),
                child: const Text('対戦を作成する'),
              ),
              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 16),
              const Text('招待コードで参加'),
              const SizedBox(height: 8),
              TextField(
                controller: _codeController,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: '例: AB12CD',
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed:
                    _isBusy || wardens.isEmpty ? null : () => _joinMatch(wardens),
                child: const Text('参加する'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
