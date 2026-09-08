# Firebase Analytics Events Configuration

## Overview
Structured analytics events for Chess Wardens to track user behavior, Aha Moment metrics, and funnel analysis.

---

## Core Events (KPI 5個以内)

### 1. `app_open`
**Trigger**: Every time app launches  
**Parameters**:
- `version` (string): App version (e.g., "1.0.0")
- `platform` (string): "iOS" | "Android"

**Use Case**: DAU/MAU tracking, retention analysis

---

### 2. `match_completed`
**Trigger**: After a match ends  
**Parameters**:
- `ai_difficulty` (string): "easy" | "normal" | "hard" | "very_hard"
- `result` (string): "win" | "loss" | "draw"
- `skill_triggered_count` (int): Number of skills triggered (0-N)
- `moves_played` (int): Total moves in match
- `duration_seconds` (int): Match duration

**Use Case**: Engagement tracking, difficulty balance, win rate analysis

---

### 3. `skill_triggered` ⭐ **AHA MOMENT METRIC**
**Trigger**: When a warden skill is activated  
**Parameters**:
- `skill_id` (string): e.g., "skill_immortality", "skill_spread_damage"
- `skill_name` (string): e.g., "Immortality", "Spread Damage"
- `warden_name` (string): e.g., "Oni King", "Kitsune"
- `trigger_condition` (string): "on_damage" | "on_attack_success" | "on_turn_start" | "on_move"
- `match_turn` (int): Turn number when triggered

**KPI Target**: 70%+ users trigger a skill in first match  
**Use Case**: Aha Moment detection, most popular skills

---

### 4. `warden_leveled_up`
**Trigger**: When a warden reaches a new level  
**Parameters**:
- `warden_id` (string): Warden identifier
- `warden_name` (string): Warden Japanese name
- `new_level` (int): New level achieved
- `total_exp` (int): Total experience accumulated

**Use Case**: Progression tracking, engagement retention

---

### 5. `share_created`
**Trigger**: When user creates a share card  
**Parameters**:
- `match_result` (string): "win" | "loss"
- `ai_difficulty` (string): Difficulty level
- `skill_triggered_count` (int): Skills in the shared match
- `platform_shared_to` (string): "twitter" | "line" | "clipboard" (if tracked)

**Use Case**: Virality metrics, social sharing engagement

---

## Secondary Events (Optional, for deeper analysis)

### `screen_view`
**Trigger**: When user navigates to a screen  
**Parameters**:
- `screen_name` (string): "login" | "home" | "match" | "warden_growth" | "settings"
- `user_segment` (string): "new" | "active" | "churned" (if available)

**Use Case**: User journey funnel analysis

---

### `onboarding_completed`
**Trigger**: When user finishes onboarding  
**Parameters**:
- `duration_seconds` (int): Time to complete onboarding
- `skipped` (boolean): True if user skipped

**Use Case**: Onboarding effectiveness, conversion

---

### `purchase_attempted`
**Trigger**: User initiates a purchase (cosmetic skin, premium)  
**Parameters**:
- `item_id` (string): "skin_oni_king_dark" | "premium_monthly"
- `item_name` (string): Friendly name
- `currency` (string): "USD"
- `value` (float): Price

**Use Case**: Monetization funnel, IAP effectiveness

---

### `purchase_completed`
**Trigger**: Purchase successfully completes  
**Parameters**:
- `item_id` (string)
- `item_name` (string)
- `currency` (string)
- `value` (float)
- `transaction_id` (string): For deduplication

**KPI Target**: 4%+ conversion rate  
**Use Case**: ARPU, LTV calculation

---

## Funnel Events

### Aha Moment Funnel
```
app_open → match_completed → skill_triggered
Target: 70%+ reach "skill_triggered" in first session
```

### Monetization Funnel
```
app_open → shop_viewed → purchase_attempted → purchase_completed
Target: Optimize drop-off points
```

---

## Event Configuration in Firebase Console

### Steps to Add Events:
1. Go to Firebase Console → Analytics → Events
2. Create custom event with exact names above
3. Add parameters with correct types (string/int/float)
4. Set up custom audiences based on events
5. Create custom dashboards for KPI tracking

---

## Integration in Code

### Example: Log skill trigger event
```dart
import 'package:firebase_analytics/firebase_analytics.dart';

final analytics = FirebaseAnalytics.instance;

await analytics.logEvent(
  name: 'skill_triggered',
  parameters: {
    'skill_id': 'skill_immortality',
    'skill_name': 'Immortality',
    'warden_name': 'Oni King',
    'trigger_condition': 'on_damage',
    'match_turn': 5,
  },
);
```

### Example: Log match completion
```dart
await analytics.logEvent(
  name: 'match_completed',
  parameters: {
    'ai_difficulty': 'normal',
    'result': 'win',
    'skill_triggered_count': 2,
    'moves_played': 35,
    'duration_seconds': 180,
  },
);
```

---

## Retention & Cohort Analysis

### Key Cohorts
1. **Aha Reacher Cohort**: Triggered a skill in first match
   - Expected: 70%+ of new users
   - Day7 Retention: 18%+ (Target)
   - Day30 Retention: 9%+ (Target)

2. **Power User Cohort**: Plays 5+ matches in first day
   - Expected: 25-30% of new users
   - Day7 Retention: 40%+ (Premium engagement)

3. **Whale Cohort**: Makes a purchase
   - Expected: 4%+ conversion
   - LTV target: $10+ (during MVP phase)

---

## Remote Config Integration

Remote Config can control:
- `analytics_enabled`: Toggle Analytics on/off
- `analytics_event_sampling`: Reduce event volume in production (e.g., log 1 in 10)

```dart
final remoteConfig = FirebaseRemoteConfig.instance;
final analyticsEnabled = remoteConfig.getBool('analytics_enabled');

if (analyticsEnabled) {
  await analytics.logEvent(...);
}
```

---

## Data Privacy (GDPR/CCPA)

- All user IDs are anonymized (Firebase handles this)
- Event parameters do not contain PII
- Users can opt-out of Analytics in app settings
- No event data is persisted after 90 days by default

---

**Last Updated**: 2026-09-08  
**Owner**: Chess Wardens Product Analytics
