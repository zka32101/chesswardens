import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/index.dart';
import '../viewmodels/index.dart';

/// Warden collection screen ("図鑑") - shows every Warden defined in the
/// game, marking which ones the player has unlocked so far.
class WardenCollectionScreen extends ConsumerWidget {
  const WardenCollectionScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allWardens = Warden.allWardens();
    final userWardens = ref.watch(userWardensProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('ワーデン図鑑')),
      body: userWardens.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (owned) {
          final ownedIds = owned.map((w) => w.wardenId).toSet();
          final unlockedCount = allWardens
              .where((w) => ownedIds.contains(w.id))
              .length;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  '解放済み: $unlockedCount / ${allWardens.length}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.9,
                  ),
                  itemCount: allWardens.length,
                  itemBuilder: (context, index) {
                    final warden = allWardens[index];
                    final isUnlocked = ownedIds.contains(warden.id);
                    return _WardenDexCard(
                      warden: warden,
                      isUnlocked: isUnlocked,
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],
          );
        },
      ),
    );
  }
}

class _WardenDexCard extends StatelessWidget {
  final Warden warden;
  final bool isUnlocked;

  const _WardenDexCard({
    required this.warden,
    required this.isUnlocked,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: isUnlocked ? 1.0 : 0.5,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                isUnlocked ? '⚔️' : '❓',
                style: const TextStyle(fontSize: 40),
              ),
              const SizedBox(height: 8),
              Text(
                isUnlocked ? warden.japaneseeName : '？？？',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                warden.baseType.englishName,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (warden.isSeasonal) ...[
                const SizedBox(height: 4),
                Chip(
                  label: Text(
                    warden.season!.label,
                    style: const TextStyle(fontSize: 10),
                  ),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ],
              if (isUnlocked) ...[
                const SizedBox(height: 8),
                Text(
                  warden.description,
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
