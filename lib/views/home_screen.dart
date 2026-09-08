import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../viewmodels/index.dart';
import 'match_screen.dart';
import 'onboarding_screen.dart';

/// Home screen - main entry point after login
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _showOnboarding = false;

  @override
  void initState() {
    super.initState();
    _checkOnboarding();
  }

  Future<void> _checkOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    final completed = prefs.getBool('onboarding_completed') ?? false;

    if (!completed && mounted) {
      setState(() => _showOnboarding = true);
      // Show onboarding as a modal
      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => OnboardingScreen(
              onComplete: () {
                setState(() => _showOnboarding = false);
              },
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userWardens = ref.watch(userWardensProvider);
    final selectedDifficulty = ref.watch(selectedAIDifficultyProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chess Wardens'),
        elevation: 0,
      ),
      body: userWardens.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Text('Error: $err'),
        ),
        data: (wardens) {
          if (wardens.isEmpty) {
            return const Center(
              child: Text('Loading wardens...'),
            );
          }

          return Column(
            children: [
              // Warden Team Display
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'My Wardens',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 1,
                        ),
                        itemCount: wardens.length,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemBuilder: (context, index) {
                          final warden = wardens[index];
                          return Card(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  warden.level.toString(),
                                  style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Lv.${warden.level}',
                                  style: const TextStyle(fontSize: 16),
                                ),
                                const SizedBox(height: 8),
                                LinearProgressIndicator(
                                  value: warden.exp /
                                      warden.expRequiredForNextLevel(
                                        warden.level,
                                      ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // Match Start Section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  border: Border(
                    top: BorderSide(
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'AI Difficulty',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      children: AIDifficulty.values.map((difficulty) {
                        final isSelected = selectedDifficulty == difficulty;
                        return ChoiceChip(
                          label: Text(difficulty.label),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              ref
                                  .read(selectedAIDifficultyProvider.notifier)
                                  .state = difficulty;
                            }
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // Battle Start Button
                    ElevatedButton(
                      onPressed: () {
                        _startMatch(context, ref, selectedDifficulty, wardens);
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 48,
                          vertical: 16,
                        ),
                        backgroundColor:
                            Theme.of(context).colorScheme.primary,
                      ),
                      child: const Text(
                        '対戦開始',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _startMatch(
    BuildContext context,
    WidgetRef ref,
    AIDifficulty difficulty,
    List<UserWarden> wardens,
  ) {
    // Simple: use all wardens for both sides (for MVP testing)
    final playerWardenIds =
        wardens.map((w) => w.wardenId).take(4).toList();
    final aiWardenIds = wardens.map((w) => w.wardenId).take(4).toList();

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MatchScreen(
          aiDifficulty: difficulty,
          playerWardenIds: playerWardenIds,
          aiWardenIds: aiWardenIds,
        ),
      ),
    );
  }
}
