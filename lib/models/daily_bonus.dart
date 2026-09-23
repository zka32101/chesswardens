/// Tracks the player's daily login streak and today's claim status.
///
/// Persisted locally (SharedPreferences) - see DailyBonusService.
class DailyBonusState {
  /// Number of consecutive days the player has claimed the bonus (0-7).
  final int consecutiveDays;

  /// Date (yyyy-MM-dd, local) the bonus was last claimed, or null if never.
  final String? lastClaimedDate;

  const DailyBonusState({
    required this.consecutiveDays,
    this.lastClaimedDate,
  });

  factory DailyBonusState.initial() => const DailyBonusState(
        consecutiveDays: 0,
        lastClaimedDate: null,
      );

  bool hasClaimedOn(String todayKey) => lastClaimedDate == todayKey;

  /// EXP reward for a given day of the streak (1-indexed).
  /// Escalates day-by-day, with a bonus jump on the 7th day.
  static int expRewardForDay(int day) {
    if (day >= 7) return 300;
    return 50 * day;
  }

  DailyBonusState copyWith({
    int? consecutiveDays,
    String? lastClaimedDate,
  }) {
    return DailyBonusState(
      consecutiveDays: consecutiveDays ?? this.consecutiveDays,
      lastClaimedDate: lastClaimedDate ?? this.lastClaimedDate,
    );
  }

  Map<String, dynamic> toMap() => {
        'consecutiveDays': consecutiveDays,
        'lastClaimedDate': lastClaimedDate,
      };

  factory DailyBonusState.fromMap(Map<String, dynamic> map) {
    return DailyBonusState(
      consecutiveDays: map['consecutiveDays'] as int? ?? 0,
      lastClaimedDate: map['lastClaimedDate'] as String?,
    );
  }
}

/// A single daily mission definition (evaluated client-side against the
/// current match session's stats).
enum DailyMissionType {
  playMatches('対局する', '対局を1回プレイする', 1),
  winMatch('勝利する', '対局に1回勝利する', 1),
  triggerSkill('スキルを発動する', 'スキルを1回発動する', 1);

  const DailyMissionType(this.title, this.description, this.targetCount);

  final String title;
  final String description;
  final int targetCount;
}

/// Progress towards a single daily mission, reset every day.
class DailyMissionProgress {
  final DailyMissionType type;
  final int currentCount;
  final bool rewardClaimed;

  const DailyMissionProgress({
    required this.type,
    required this.currentCount,
    this.rewardClaimed = false,
  });

  bool get isComplete => currentCount >= type.targetCount;

  DailyMissionProgress copyWith({
    int? currentCount,
    bool? rewardClaimed,
  }) {
    return DailyMissionProgress(
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

  factory DailyMissionProgress.fromMap(Map<String, dynamic> map) {
    return DailyMissionProgress(
      type: DailyMissionType.values.firstWhere(
        (t) => t.name == map['type'],
        orElse: () => DailyMissionType.playMatches,
      ),
      currentCount: map['currentCount'] as int? ?? 0,
      rewardClaimed: map['rewardClaimed'] as bool? ?? false,
    );
  }

  static const int expReward = 30;
}
