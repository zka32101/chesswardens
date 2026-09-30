import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../viewmodels/index.dart';
import 'replay_screen.dart';

/// Enter a spectate code shared from someone else's match history to
/// watch their replay.
class SpectateScreen extends ConsumerStatefulWidget {
  const SpectateScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SpectateScreen> createState() => _SpectateScreenState();
}

class _SpectateScreenState extends ConsumerState<SpectateScreen> {
  final _codeController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _watch() async {
    final code = _codeController.text.trim().toUpperCase();
    if (code.isEmpty) return;

    setState(() => _isLoading = true);
    final match = await ref.read(spectateMatchByCodeProvider(code).future);
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (match == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('そのコードの対局が見つかりませんでした')),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ReplayScreen(matchLog: match)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('観戦')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '友達から教えてもらった観戦コードを入力してください',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _codeController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      hintText: '観戦コードを入力',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isLoading ? null : _watch,
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('観戦する'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
