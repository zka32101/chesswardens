import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../viewmodels/index.dart';

/// Manage friends: view your own friend code, add someone by their code,
/// and see/remove your current friend list.
class FriendsScreen extends ConsumerStatefulWidget {
  const FriendsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends ConsumerState<FriendsScreen> {
  final _codeController = TextEditingController();
  bool _isAdding = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _addFriend() async {
    final uid = ref.read(userIdProvider);
    final code = _codeController.text.trim().toUpperCase();
    if (uid == null || code.isEmpty) return;

    setState(() => _isAdding = true);
    final addedUid =
        await ref.read(friendNotifierProvider).addByCode(uid, code);
    setState(() => _isAdding = false);

    if (!mounted) return;
    if (addedUid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('そのコードのユーザーが見つかりませんでした')),
      );
      return;
    }

    _codeController.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('フレンドを追加しました')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final myCode = ref.watch(friendCodeProvider);
    final friends = ref.watch(friendsProvider);
    final myUid = ref.watch(userIdProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('フレンド')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'あなたのフレンドコード',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  myCode.when(
                    loading: () => const LinearProgressIndicator(),
                    error: (e, _) => Text('エラー: $e'),
                    data: (code) => SelectableText(
                      code ?? '-',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'このコードを友達に伝えて追加してもらいましょう',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'フレンドを追加',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _codeController,
                          textCapitalization: TextCapitalization.characters,
                          decoration: const InputDecoration(
                            hintText: 'フレンドコードを入力',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _isAdding ? null : _addFriend,
                        child: const Text('追加'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'フレンド一覧',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          friends.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('エラー: $e'),
            data: (list) {
              if (list.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text('まだフレンドがいません'),
                );
              }
              return Column(
                children: list
                    .map((f) => ListTile(
                          leading: const Icon(Icons.person),
                          title: Text(f.uid.substring(0, 8)),
                          trailing: IconButton(
                            icon: const Icon(Icons.person_remove),
                            onPressed: myUid == null
                                ? null
                                : () => ref
                                    .read(friendNotifierProvider)
                                    .remove(myUid, f.uid),
                          ),
                        ))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
