# Firebase Configuration Guide - Chess Wardens

This guide walks you through setting up Firebase for Chess Wardens MVP.

---

## Prerequisites

- Flutter/Dart development environment
- Firebase project (free Spark plan or billable Blaze plan recommended for production)
- `flutterfire` CLI tool installed: `flutter pub global activate flutterfire_cli`
- iOS: Xcode 12+ and CocoaPods
- Android: Android Studio and Android SDK 21+

---

## Step 1: Create Firebase Project

### 1.1 Go to Firebase Console
```bash
# Open https://console.firebase.google.com/
```

### 1.2 Create New Project
- Project name: **Chess Wardens**
- Region: Choose based on your target users
  - Recommended: `asia-northeast1` (Tokyo) for Japan-focused MVP
- Enable Google Analytics (optional but recommended)

### 1.3 Add iOS & Android Apps
- **iOS Bundle ID**: `com.chesswardens.app` (or your identifier)
- **Android Package Name**: `com.chesswardens.app`
- Download configuration files (you'll use them next)

---

## Step 2: Generate firebase_options.dart

### Using FlutterFire CLI (Recommended)

```bash
cd /path/to/chesswardens

# Install flutterfire CLI if not already installed
flutter pub global activate flutterfire_cli

# Configure Flutter for Firebase
flutterfire configure \
  --project=chess-wardens-prod \
  --ios-bundle-id=com.chesswardens.app \
  --android-package-name=com.chesswardens.app

# Select all services when prompted:
# - Firebase Auth
# - Cloud Firestore
# - Firebase Analytics
# - Firebase Crashlytics
# - Firebase Remote Config
```

**Note**: `flutterfire configure` will:
1. Automatically download `google-services.json` (Android)
2. Automatically download `GoogleService-Info.plist` (iOS)
3. **Generate** `lib/firebase_options.dart` with real credentials
4. Update `ios/Podfile` and Android `build.gradle`

### Manual Setup (if CLI doesn't work)

1. Download `google-services.json` from Firebase Console
   - Place in: `android/app/`

2. Download `GoogleService-Info.plist` from Firebase Console
   - Place in: `ios/Runner/`

3. Manually create or update `lib/firebase_options.dart`:
   ```dart
   import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
   import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

   class DefaultFirebaseOptions {
     static FirebaseOptions get currentPlatform {
       // ... copy values from Firebase Console
     }

     static const FirebaseOptions web = FirebaseOptions(
       apiKey: 'YOUR_WEB_API_KEY',
       appId: '1:YOUR_APP_ID:web:YOUR_WEB_APP_ID',
       messagingSenderId: 'YOUR_MESSAGING_SENDER_ID',
       projectId: 'chess-wardens-prod',
     );

     static const FirebaseOptions android = FirebaseOptions(
       apiKey: 'YOUR_ANDROID_API_KEY',
       appId: '1:YOUR_APP_ID:android:YOUR_ANDROID_APP_ID',
       messagingSenderId: 'YOUR_MESSAGING_SENDER_ID',
       projectId: 'chess-wardens-prod',
     );

     static const FirebaseOptions ios = FirebaseOptions(
       apiKey: 'YOUR_IOS_API_KEY',
       appId: '1:YOUR_APP_ID:ios:YOUR_IOS_APP_ID',
       messagingSenderId: 'YOUR_MESSAGING_SENDER_ID',
       projectId: 'chess-wardens-prod',
     );
   }
   ```

---

## Step 3: Enable Firebase Services

### 3.1 Authentication (Email/Password)

In Firebase Console:
1. Go to **Authentication** → **Sign-in method**
2. Enable **Email/Password** provider
3. (Optional) Enable Google Sign-In, Apple Sign-In for future phases

### 3.2 Firestore Database

In Firebase Console:
1. Go to **Firestore Database** → **Create Database**
2. Select region: **asia-northeast1** (or same as project)
3. Choose **Start in test mode** (for MVP development)
4. Click **Create**

### 3.3 Deploy Security Rules

After Firestore is created:

```bash
# Install Firebase CLI if not already
npm install -g firebase-tools

# Login to Firebase
firebase login

# Set project
firebase use chess-wardens-prod

# Deploy Firestore Security Rules
firebase deploy --only firestore:rules
```

**Note**: The file `firestore.rules` in this repo contains the security rules.

### 3.4 Firebase Analytics

In Firebase Console:
1. Go to **Analytics** → **Events**
2. Create custom events matching `analytics_events.md`:
   - `app_open`
   - `match_completed`
   - `skill_triggered` ⭐
   - `warden_leveled_up`
   - `share_created`

3. Configure custom audiences for retention cohorts

### 3.5 Firebase Remote Config

In Firebase Console:
1. Go to **Remote Config** → **Parameters**
2. Add parameters from `remote_config_schema.json`:
   - `ai_depth_easy`, `ai_depth_normal`, `ai_depth_hard`, `ai_depth_very_hard`
   - `exp_per_win`, `exp_per_loss`, `exp_per_skill_trigger`
   - `min_supported_version`, `maintenance_mode`
   - etc.

3. Save and publish

### 3.6 Firebase Crashlytics

In Firebase Console:
1. Go to **Crashlytics**
2. It's automatically enabled once the app reports crashes
3. No manual configuration needed for MVP

---

## Step 4: GitHub Actions Secrets

For CI/CD pipelines to access Firebase, add secrets to GitHub:

```bash
# Go to your repo → Settings → Secrets and variables → Actions

# Add these secrets (get values from firebase_options.dart or Console):
FIREBASE_API_KEY=<value from firebase_options.dart>
FIREBASE_PROJECT_ID=chess-wardens-prod
```

**Note**: For secure practice, never commit actual API keys. Use GitHub Secrets for CI/CD.

---

## Step 5: Local Testing

### 5.1 Verify Installation

```bash
cd /path/to/chesswardens

# Get dependencies
flutter pub get

# Verify firebase_options.dart was generated
cat lib/firebase_options.dart | head -20

# Run app (will initialize Firebase on startup)
flutter run
```

### 5.2 Test Firebase Initialization

The app should:
1. Start without errors
2. Show login screen (Firebase Auth ready)
3. Allow signing up with email/password
4. Save user data to Firestore (after first match)

### 5.3 Monitor in Firebase Console

- **Authentication**: Check "Users" tab to see sign-ups
- **Firestore**: Check "Data" tab to see user/warden documents
- **Analytics**: Check "Real-time" tab to see events
- **Crashlytics**: Check crash reports (if any)

---

## Step 6: Firestore Database Setup (Manual Collections)

If using Firestore Database for the first time, Firebase will auto-create collections when data is written. However, for clarity, you can pre-create these collection structures:

### Via Firebase Console
1. **Firestore Database** → **Start collection**
2. Create collections (no schema needed):
   - `users` (contains user profiles)
   - `shareCards` (public share records)

### Subcollections (auto-created by app):
- `users/{uid}/wardens` (user's wardens)
- `users/{uid}/matchLogs` (user's match history)

---

## Step 7: Emulator Setup (Optional for Local Dev)

For faster local development without hitting the cloud:

```bash
# Install Firebase Emulator Suite
npm install -g firebase-tools

# Start emulator
firebase emulators:start

# In your app (main.dart), connect to emulator:
if (kDebugMode) {
  await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
  FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
}
```

---

## Step 8: Datastore Backup

Before going to production, set up automated backups:

In Firebase Console:
1. Go to **Firestore Database** → **Backups**
2. Create a backup schedule (daily at off-peak hours)
3. Set retention to 90+ days

---

## Troubleshooting

### Common Issues

| Issue | Solution |
|-------|----------|
| `firebase_options.dart not found` | Run `flutterfire configure` |
| `google-services.json not found` (Android build fail) | Download from Firebase Console → Project Settings → Your Android app |
| `GoogleService-Info.plist not found` (iOS build fail) | Download from Firebase Console → Project Settings → Your iOS app |
| `Firestore permission denied` | Check `firestore.rules` and redeploy with `firebase deploy --only firestore:rules` |
| `Auth sign-up fails` | Verify Email/Password is enabled in Firebase Console → Authentication |
| Analytics events not showing | Check event names match exactly (case-sensitive), wait 24-48 hours for some events to appear |

---

## Security Checklist

- [x] Firestore Security Rules: Restrict access to user's own data
- [ ] Environment variables: Never commit `.env` or API keys to repo
- [ ] GitHub Secrets: Add Firebase keys for CI/CD
- [ ] HTTPS: Firebase enforces HTTPS by default ✅
- [ ] Rate limiting: Enable in Firestore (prevent abuse)
- [ ] Email verification: Add email verification on sign-up (future phase)
- [ ] 2FA: Recommend for developer accounts accessing Firebase Console

---

## Performance Optimization

### Firestore Best Practices

1. **Limit read/write operations**: Use batching for multiple updates
   ```dart
   WriteBatch batch = FirebaseFirestore.instance.batch();
   batch.set(docRef1, data1);
   batch.update(docRef2, data2);
   await batch.commit();
   ```

2. **Index creation**: Firestore auto-creates indexes for common queries
   - Monitor "Indexes" tab in Firestore Console

3. **Cache**: Leverage Riverpod caching to avoid redundant reads
   - UserWardens and MatchLogs already use `.watch()` with auto-refresh

### Cost Optimization

- **Spark Plan**: 50,000 read/day, unlimited writes up to quota
- **Blaze Plan**: Pay-as-you-go (recommended for production)
- **Estimate costs** in Firebase Pricing Calculator before launch

---

## Next Steps

1. ✅ Create Firebase Project
2. ✅ Run `flutterfire configure`
3. ✅ Enable Auth, Firestore, Analytics, Remote Config
4. ✅ Deploy Firestore Security Rules
5. ✅ Add GitHub Secrets for CI/CD
6. ✅ Test locally with `flutter run`
7. ⏳ Monitor metrics in Firebase Console (Day 1)
8. ⏳ Set up alerting for crashes/errors (Week 1)
9. ⏳ Review Firebase costs weekly (ongoing)

---

**Last Updated**: 2026-09-08  
**Reference**: [Firebase for Flutter Docs](https://firebase.flutter.dev/)
