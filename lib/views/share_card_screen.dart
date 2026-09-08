import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/index.dart';
import '../viewmodels/index.dart';

/// Share card screen - Display and share battle results
class ShareCardScreen extends ConsumerStatefulWidget {
  final MatchResult result;
  final int playerScore;
  final int aiScore;
  final int skillTriggeredCount;
  final List<String> playerWardenIds;
  final AIDifficulty aiDifficulty;

  const ShareCardScreen({
    Key? key,
    required this.result,
    required this.playerScore,
    required this.aiScore,
    required this.skillTriggeredCount,
    required this.playerWardenIds,
    required this.aiDifficulty,
  }) : super(key: key);

  @override
  ConsumerState<ShareCardScreen> createState() => _ShareCardScreenState();
}

class _ShareCardScreenState extends ConsumerState<ShareCardScreen> {
  late GlobalKey _shareCardKey;
  bool _isSharing = false;

  @override
  void initState() {
    super.initState();
    _shareCardKey = GlobalKey();
  }

  Future<void> _copyToClipboard() async {
    final text = _generateShareText();
    await Clipboard.setData(ClipboardData(text: text));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('シェアテキストをコピーしました！'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _shareToTwitter() async {
    final text = _generateShareText();
    final encodedText = Uri.encodeComponent(text);
    final twitterUrl = 'https://twitter.com/intent/tweet?text=$encodedText&hashtags=ChessWardens';

    try {
      // In a real app, you would use url_launcher package
      // For now, just show a message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Twitter シェアを開いています...'),
          action: SnackBarAction(
            label: 'コピー',
            onPressed: _copyToClipboard,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('エラー: $e')),
      );
    }
  }

  Future<void> _shareToLine() async {
    final text = _generateShareText();
    final encodedText = Uri.encodeComponent(text);
    final lineUrl = 'https://line.me/R/msg/text/$encodedText';

    try {
      // In a real app, you would use url_launcher package
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('LINE シェアを開いています...'),
          action: SnackBarAction(
            label: 'コピー',
            onPressed: _copyToClipboard,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('エラー: $e')),
      );
    }
  }

  String _generateShareText() {
    final resultEmoji = widget.result == MatchResult.win ? '🎉' : '😢';
    final resultText = widget.result == MatchResult.win ? '勝利' : '敗北';
    final difficulty = widget.aiDifficulty.label;

    return '''
$resultEmoji $resultText！ チェスウォーデン バトルレポート

難易度: $difficulty
あなたのスコア: ${widget.playerScore}
AIのスコア: ${widget.aiScore}
スキル発動: ${widget.skillTriggeredCount}回

#ChessWardens #チェスウォーデン
''';
  }

  @override
  Widget build(BuildContext context) {
    final allWardens = ref.watch(mvpWardensProvider);
    final isWin = widget.result == MatchResult.win;

    return Scaffold(
      appBar: AppBar(
        title: const Text('バトル結果をシェア'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 24),

            // Share card preview
            _buildShareCard(context, allWardens, isWin),
            const SizedBox(height: 32),

            // Share options
            _buildShareOptions(context),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildShareCard(
    BuildContext context,
    List<Warden> allWardens,
    bool isWin,
  ) {
    final primaryWarden = allWardens.firstWhere(
      (w) => w.id == widget.playerWardenIds.first,
      orElse: () => allWardens.first,
    );

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      key: _shareCardKey,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isWin
              ? [Colors.green.shade100, Colors.blue.shade100]
              : [Colors.red.shade100, Colors.orange.shade100],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isWin ? Colors.green.shade400 : Colors.red.shade400,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: (isWin ? Colors.green : Colors.red).withOpacity(0.2),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Result header
          Text(
            isWin ? '🎉 勝利！' : '😢 敗北',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: isWin ? Colors.green.shade700 : Colors.red.shade700,
            ),
          ),
          const SizedBox(height: 16),

          // Title
          Text(
            'チェスウォーデン バトルレポート',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // Warden info
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _getWardenEmoji(primaryWarden.id),
                  style: const TextStyle(fontSize: 40),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      primaryWarden.japaneseeName,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      primaryWarden.name,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Stats grid
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: [
                _StatCard(
                  label: '難易度',
                  value: widget.aiDifficulty.label,
                  icon: '⚙️',
                ),
                _StatCard(
                  label: 'あなたのスコア',
                  value: widget.playerScore.toString(),
                  icon: '♔',
                ),
                _StatCard(
                  label: 'AIのスコア',
                  value: widget.aiScore.toString(),
                  icon: '♚',
                ),
                _StatCard(
                  label: 'スキル発動',
                  value: '${widget.skillTriggeredCount}回',
                  icon: '✨',
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Footer
          Text(
            'チェスウォーデン - 和風妖怪チェスバトル',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildShareOptions(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'シェア方法を選択',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.9,
            children: [
              _ShareButton(
                icon: '𝕏',
                label: 'Twitter',
                onPressed: _shareToTwitter,
                color: Colors.black,
              ),
              _ShareButton(
                icon: '💚',
                label: 'LINE',
                onPressed: _shareToLine,
                color: Colors.green,
              ),
              _ShareButton(
                icon: '📋',
                label: 'コピー',
                onPressed: _copyToClipboard,
                color: Colors.blue,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Info box
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '💡 シェア機能について',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '現在はテキストベースのシェアに対応しています。今後、スクリーンショット自動生成やバトル動画の共有機能を追加予定です。',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Back button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('戻る'),
            ),
          ),
        ],
      ),
    );
  }

  String _getWardenEmoji(String wardenId) {
    switch (wardenId) {
      case 'oni_king':
        return '👹';
      case 'kitsune':
        return '🦊';
      case 'orochi':
        return '🐍';
      case 'tengu':
        return '🌪️';
      default:
        return '✨';
    }
  }
}

/// Share button widget
class _ShareButton extends StatelessWidget {
  final String icon;
  final String label;
  final VoidCallback onPressed;
  final Color color;

  const _ShareButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          border: Border.all(color: color.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              icon,
              style: const TextStyle(fontSize: 32),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Stat card widget
class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String icon;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(icon, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
