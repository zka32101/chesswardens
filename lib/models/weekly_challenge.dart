/// A single weekly challenge definition (evaluated client-side against
/// cumulative stats for the current ISO week).
enum WeeklyChallengeType {
  winMatches('今週の勝利', '今週中に5回勝利する', 5),
  playMatches('今週の対局', '今週中に10回対局する', 10),
  triggerSkills('今週のスキル発動', '今週中にスキルを合計15回発動する', 15);

  const WeeklyChallengeType(this.title, this.description, this.targetCount);

  final String title;
  final String description;
  final int targetCount;
}

/// Progress towards a single weekly challenge, reset every ISO week.
/// Rewards are larger than daily missions' since the window is longer.
class WeeklyChallengeProgress {
  final WeeklyChallengeType type;
  final int currentCount;
  final bool rewardClaimed;

  const WeeklyChallengeProgress({
    required this.type,
    required this.currentCount,
    this.rewardClaimed = false,
  });

  bool get isComplete => currentCount >= type.targetCount;

  WeeklyChallengeProgress copyWith({
    int? currentCount,
    bool? rewardClaimed,
  }) {
    return WeeklyChallengeProgress(
      type: type,
      currentCount: currentCount ?? this.currentCount,
      rewardClaimed: rewardClaimed ?? this.rewardClaimed,
    );
  }

  Map<String, dynamic> toMap() => {
        'type': type.name,
        'currentCount': currentCount,
        'rewardClaimed': rewardClaimed,
      };

  factory WeeklyChallengeProgress.fromMap(Map<String, dynamic> map) {
    return WeeklyChallengeProgress(
      type: WeeklyChallengeType.values.firstWhere(
        (t) => t.name == map['type'],
        orElse: () => WeeklyChallengeType.playMatches,
      ),
      currentCount: map['currentCount'] as int? ?? 0,
      rewardClaimed: map['rewardClaimed'] as bool? ?? false,
    );
  }

  static const int expReward = 150;
}

/// Computes an ISO 8601 week key (e.g. "2026-W40") for [date], used to
/// detect when weekly challenges should reset. Pure function, easy to
/// unit test independent of persistence.
String computeWeekKey(DateTime date) {
  final d = DateTime.utc(date.year, date.month, date.day);
  // ISO weeks belong to the year containing their Thursday.
  final thursday = d.add(Duration(days: 4 - d.weekday));
  final firstDayOfYear = DateTime.utc(thursday.year, 1, 1);
  final weekNumber =
      ((thursday.difference(firstDayOfYear).inDays) / 7).floor() + 1;
  return '${thursday.year}-W${weekNumber.toString().padLeft(2, '0')}';
}
