# Chess Wardens - ローカルセットアップガイド

このガイドは、開発マシンで Chess Wardens を初めてセットアップする手順を記載しています。

## 前提条件

- Flutter 3.9.0 以上
- Dart 3.0 以上
- iOS: Xcode 12+ (macOS)
- Android: Android Studio + SDK API 21+
- Firebase プロジェクト (Google Cloud アカウント)
- Git

## セットアップ手順

### 1. リポジトリをクローン

```bash
git clone https://github.com/zka32101/chesswardens.git
cd chesswardens
```

### 2. Flutter 依存関係をインストール

```bash
flutter pub get
```

### 3. Firebase プロジェクト作成

[Firebase Console](https://console.firebase.google.com/) で新規プロジェクトを作成してください。

**推奨設定:**
- プロジェクト名: `Chess Wardens`
- リージョン: `asia-northeast1` (東京)
- Google Analytics: 有効

### 4. Firebase 設定（flutterfire CLI を使用）

```bash
# FlutterFire CLI をインストール (未インストール時)
flutter pub global activate flutterfire_cli

# Firebase を設定
flutterfire configure \
  --project=your-firebase-project-id \
  --ios-bundle-id=com.chesswardens.app \
  --android-package-name=com.chesswardens.app
```

**プロンプトで以下を有効化:**
- Authentication
- Cloud Firestore
- Firebase Analytics
- Firebase Crashlytics
- Firebase Remote Config

このコマンドで自動的に以下が生成されます:
- `lib/firebase_options.dart` (Firebase 設定)
- `google-services.json` (Android 設定)
- `GoogleService-Info.plist` (iOS 設定)

### 5. Firebase サービスを有効化

#### 5.1 Authentication (Email/Password)

Firebase Console で:
1. Authentication → Sign-in method
2. Email/Password を有効化

#### 5.2 Firestore Database

1. Firestore Database → Create Database
2. Location: `asia-northeast1`
3. Security rules: Start in test mode
4. Create

#### 5.3 Security Rules をデプロイ

```bash
# Firebase CLI をインストール (未インストール時)
npm install -g firebase-tools

# ログイン
firebase login

# プロジェクトを設定
firebase use your-firebase-project-id

# Security Rules をデプロイ
firebase deploy --only firestore:rules
```

#### 5.4 Analytics イベントを設定

Firebase Console → Analytics → Events で、以下を作成:
- `app_open`
- `match_completed`
- `skill_triggered`
- `warden_leveled_up`
- `share_created`

#### 5.5 Remote Config パラメータを設定

Firebase Console → Remote Config で `remote_config_schema.json` の全パラメータを追加してから Publish

### 6. GitHub Actions Secrets を設定 (CI/CD 用)

リポジトリ Settings → Secrets and variables → Actions で以下を追加:

```
FIREBASE_API_KEY=<firebase_options.dart から取得>
FIREBASE_PROJECT_ID=your-firebase-project-id
```

### 7. ローカルテスト

#### 7.1 ユニットテストを実行

```bash
flutter test
```

期待結果:
- `test/services/chess_engine_service_test.dart` が全てパス
- Board 初期化、移動生成、スキル評価が動作

#### 7.2 アプリを実行

```bash
# iOS (macOS only)
flutter run -d ios

# Android
flutter run -d android

# または、デフォルト デバイスで実行
flutter run
```

初回起動時:
1. ログイン画面が表示される
2. Email/Password で新規登録
3. オンボーディング (3ページ) が表示される
4. ホーム画面でワーデン一覧が表示される
5. マッチを開始できる

### 8. 動作確認チェックリスト

実行して以下が動作することを確認してください:

```
[ ] ログイン・新規登録が動作
[ ] オンボーディング画面が表示される
[ ] ホーム画面にワーデンが4体表示される
[ ] ワーデンをタップして詳細画面が表示される
[ ] マッチ画面でチェスボードが表示される
[ ] Lottieアニメーションがキャプチャ時に表示される
[ ] マッチ終了後、結果画面が表示される
[ ] 結果画面でシェアボタンが動作する
[ ] ホーム画面に戻ることができる
[ ] ワーデンレベルアップが動作する
```

### 9. Firebase Console で動作確認

#### 実データを送信したか確認:

**Authentication:**
- Console → Users に登録したメールが表示される

**Firestore:**
- Console → Data に以下が表示される:
  - `users/{uid}` (ユーザー情報)
  - `users/{uid}/wardens/` (4体のワーデン)
  - `users/{uid}/matchLogs/` (バトルログ)

**Analytics:**
- Console → Real-time で以下のイベントが表示される:
  - `app_open`
  - `match_completed`
  - `skill_triggered`

### 10. ビルド準備 (デプロイ前)

#### Android APK/AAB をビルド

```bash
# デバッグ APK
flutter build apk --debug

# リリース AAB (Play Store 用)
flutter build appbundle --release
```

#### iOS IPA をビルド

```bash
# 署名なし (開発用)
flutter build ios --release --no-codesign

# 署名付き (App Store 用) - 要 Apple Developer Certificate
flutter build ios --release
```

## トラブルシューティング

### firebase_options.dart が見つからない

```bash
flutterfire configure --project=your-project-id
```

を再実行してください。

### Authentication でエラー

Firebase Console → Authentication → Settings で以下を確認:
- Email/Password が有効化されているか
- Authorized domains に localhost が含まれているか

### Firestore permission denied

```bash
firebase deploy --only firestore:rules
```

Security Rules が正しくデプロイされているか確認してください。

### Analytics イベントが表示されない

- イベント名が大文字小文字含めて正確か確認
- 24-48 時間待つ必要があります (初回表示遅延)
- Real-time ビューで即座に確認できます

## CI/CD パイプライン

Push または PR 作成時に以下が自動実行されます:

1. **flutter_ci.yml** (Ubuntu)
   - `flutter analyze` - 静的解析
   - `flutter test` - ユニットテスト
   - `codecov` - カバレッジ報告
   - APK ビルド (PR/Manual 時)

2. **build-release.yml** (Tag push 時)
   - AAB ビルド (Android)
   - IPA ビルド (iOS unsigned)
   - GitHub Release を作成

## 本番デプロイ

### App Store (iOS)

1. Apple Developer Account を作成
2. Certificate と Provisioning Profile を取得
3. GitHub Secrets に登録
4. iOS signing をセットアップ
5. `build-release.yml` で自動ビルド
6. App Store Connect にアップロード

### Google Play (Android)

1. Google Play Developer Account を作成
2. Signing Key を生成
3. GitHub Secrets に登録
4. `build-release.yml` で自動ビルド
5. Google Play Console にアップロード

詳細は [Firebase Setup Guide](./FIREBASE_SETUP.md) を参照してください。

## サポート

問題が発生した場合:

1. このガイドの該当セクションを確認
2. [Firebase Docs](https://firebase.flutter.dev/) を確認
3. [Flutter Docs](https://flutter.dev/docs) を確認
4. GitHub Issues で既知の問題を検索

---

**Last Updated**: 2026-09-08  
**Version**: MVP 1.0.0
