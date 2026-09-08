# Chess Wardens

チェスの駒に和風妖怪・神獣（鬼王/九尾/大蛇/天狗）の魂を宿し、固有スキルで戦う育成×AI対戦チェス。

**Vision**: 正統チェスの学習コストを崩さず、妖怪育成×バトルで「もう一戦」したくなる体験をつくる。

**White field**: チェス×駒育成×和風妖怪IPの交点（海外先行事例はダークファンタジー系、和風は未開拓）

---

## 🏗️ Architecture

```
lib/
  ├── models/           # 駒・スキル・マッチログ定義
  ├── services/         # ChessEngine・スキル評価・Firestore
  ├── viewmodels/       # Riverpod Providers（認証・ゲーム状態管理）
  ├── views/            # UI層（Login・Home・Match画面）
  └── main.dart         # エントリーポイント
```

### Tech Stack
- **Framework**: Flutter/Dart 3.x
- **State Management**: Flutter Riverpod
- **Database**: Firebase (Firestore/Auth/Analytics/Crashlytics)
- **Monetization**: RevenueCat
- **Animation**: Lottie
- **AI Engine**: Custom Minimax + α-β Pruning (depth 2-3)

---

## ✅ Implementation Status

### Phase 1: MVP Foundation ✅ COMPLETE
- [x] データモデル層（Warden, SkillDefinition, MatchLog, ShareCard）
- [x] ChessEngineService
  - [x] 盤面表現（Board, Square, Piece with HP/Skill）
  - [x] 駒の移動ロジック（全6駒種類の合法手生成）
  - [x] ミニマックス + α-β 刈り込みアルゴリズム
  - [x] 盤面評価関数（駒のHP、スキル発動状態を含む）
- [x] SkillEvaluationService
  - [x] スキル発動確率計算
  - [x] スキル効果値評価
  - [x] 盤面評価への統合
- [x] FirestoreService
  - [x] ユーザー初期化
  - [x] Warden管理（取得・更新）
  - [x] MatchLog記録
  - [x] ShareCard機能
- [x] Riverpod ViewModels
  - [x] auth_provider（Firebase認証）
  - [x] warden_provider（駒管理）
  - [x] game_state_provider（対局状態）
  - [x] match_history_provider（履歴・統計）
  - [x] share_card_provider（共有機能）
- [x] UI Views
  - [x] LoginScreen（認証UI）
  - [x] HomeScreen（駒選択・AI難易度選択）
  - [x] MatchScreen（8×8盤面・対局）
- [x] ユニットテスト
  - [x] ChessEngineService（合法手、評価値）
  - [x] モデル層（Warden, UserWarden）

### Phase 2: Polish & Animation ✅ COMPLETE
- [x] Lottie スキル発動演出
  - [x] 鬼王の不死復活エフェクト（金の輪郭+金棒一閃、1.5秒）
  - [x] 九尾の炎ダメージ拡散（尻尾分裂+狐火、1.0秒）
  - [x] 大蛇の鉄壁（とぐろ+鱗シールド、1.2秒）
  - [x] 天狗の追加ジャンプ（羽扇+残像、1.0秒）
- [x] オンボーディング画面（3枚・ルール説明）
- [x] WardenGrowth画面（育成・レベルアップUI）
- [x] MatchResult画面（勝敗結果表示・経験値獲得）
- [x] ShareCard UI（対局結果共有・Twitter/LINE/Clipboard）

### Phase 3: Infrastructure ✅ COMPLETE
- [x] CI/CD（GitHub Actions）
  - [x] flutter analyze - 静的解析
  - [x] flutter test - ユニットテスト
  - [x] codecov - カバレッジ報告
  - [x] APK ビルド（PR/Manual時）
- [x] Firebase設定
  - [x] Firestore セキュリティルール（リソースベース制御）
  - [x] Remote Config（AI難易度、育成曲線、ゲームバランス）
  - [x] Analytics イベント設定（5 KPI イベント）
  - [x] Firebase Crashlytics（自動エラー報告）
- [x] Documentation
  - [x] SETUP_GUIDE.md（ローカルセットアップ手順）
  - [x] FIREBASE_SETUP.md（Firebase設定ガイド）
  - [x] ANIMATIONS.md（Lottieアニメーション仕様）
  - [x] analytics_events.md（アナリティクスイベント定義）

### Phase 4: LiveOps ❌ FUTURE
- [ ] 季節限定Warden追加
  - [ ] 雪女（Bishop、冬限定）
  - [ ] 河童（Bishop、夏限定）
  - [ ] 座敷童（Pawn、初心者救済）
  - など
- [ ] RevenueCat 統合（コスメ課金）

---

## 📊 KPI Targets (Midcore Benchmark)

| 指標 | Target | Benchmark |
|------|--------|-----------|
| Day1 Retention | 25%+ | 15-25% |
| Day7 Retention | 18%+ | 15-25% |
| Day30 Retention | 9%+ | 8-12% |
| 有料転換率 | 4%+ | 3-6% |
| Aha到達率 | 70%+ | - |

**Aha Moment**: 初回対戦でスキル発動を体験（タップ順序 3回以内）

---

## 🎨 UI Features & Screens

### AuthScreen（認証）
- Email/Password ベースのサインアップ・ログイン
- Firebase Authentication 統合
- エラーハンドリング（重複アカウント、パスワード不一致）

### OnboardingScreen（オンボーディング）
- 3ページ PageView ナビゲーション
  - Page 1: ようこそ & 基本ルール説明
  - Page 2: ワーデン育成システム詳細
  - Page 3: 対戦の遊び方 & リワード説明
- 初回起動時のみ表示、SharedPreferences で永続化

### HomeScreen（ホーム）
- 4体のMVP ワーデン一覧表示
- ワーデンごとの詳細ボタンで WardenGrowth 画面へ遷移
- 対戦開始ボタン（AI難易度 Easy/Normal/Hard/Very Hard 選択）

### MatchScreen（対戦）
- 8×8 チェスボード ビジュアル
- ドラッグ&ドロップ対応（または盤面タップ＋駒選択）
- スキル発動時 Lottie アニメーション表示（SkillAnimationDisplay）
- 対戦中統計表示（移動数、スキル発動回数）
- ゲームオーバー判定（合法手ゼロ）時、自動的に MatchResultScreen へ遷移

### MatchResultScreen（対戦結果）
- 勝敗ヘッダー（絵文字 + テキスト）
- バトル統計セクション
  - プレイヤー/AI スコア、移動数、スキル発動回数、試合時間
- 獲得経験値表示（アニメーション付き）
  - 基本経験値 100（勝利）/ 50（敗北）
  - スキルボーナス ×10 /回
- ワーデンごとの EXP 分配表示
- シェアボタン → ShareCardScreen 遷移
- ホーム復帰ボタン

### WardenGrowthScreen（ワーデン育成）
- ワーデン詳細ビジュアル（絵文字 + 名前）
- ステータス表示（レベル、経験値、HP、攻撃力、防御力）
- 次レベルまでの経験値プログレスバー
- ユニークスキル詳細
  - スキル名、説明、発動率、スキル値、発動条件
- 詳細情報（ID、タイプ、アンロック日時）
- レベルアップボタン（条件達成時のみ有効）

### ShareCardScreen（対戦結果共有）
- 美しい勾配背景付きの対戦結果カード
  - 勝利: 緑/青系、敗北: 赤/オレンジ系
- ワーデンの絵文字 + 対戦スコア統計（2×2 グリッド）
- 3つのシェア方法
  - Twitter: URL スキーム経由
  - LINE: URL スキーム経由
  - コピー: Clipboard.setData で テキストコピー
- シェアテキスト例: 「🎉 勝利！難易度 Normal で AI を撃破」

---

## 🔐 Firebase & Security Rules

### Firestore Structure
```
users/{uid}
  ├── email (string)
  ├── displayName (string)
  ├── createdAt (timestamp)
  ├── wardens/{wardenId}
  │   ├── level (int)
  │   ├── exp (int)
  │   ├── unlockedAt (timestamp)
  │   ├── stats (object)
  │   └── ...
  └── matchLogs/{matchLogId}
      ├── result (string: 'win'/'loss')
      ├── playerScore (int)
      ├── aiScore (int)
      ├── skillTriggeredCount (int)
      ├── wardenUsed (array)
      ├── aiDifficulty (string)
      ├── duration (int)
      └── createdAt (timestamp)

shareCards/{cardId}
  ├── playerUid (string)
  ├── result (string)
  ├── playerScore (int)
  ├── aiScore (int)
  └── ...
```

### Security Rules
- **認証ユーザーのみ**: ユーザー作成・ワーデン取得
- **オーナー保護**: ユーザーデータ・マッチログは作成者のみアクセス
- **公開シェアカード**: 誰でも読取可（スコアボード・シェア機能用）
- **書込保護**: クライアント側で作成時刻・ユーザーID検証

詳細: [firestore.rules](/firestore.rules)

### Remote Config Parameters
- `ai_difficulty_depth_*`: AI 難易度別 Minimax 深さ（1-3）
- `exp_per_win`, `exp_per_loss`: 基本経験値
- `exp_per_skill_trigger`: スキルボーナス EXP
- `base_level_cap`: ワーデンレベル上限
- `maintenance_mode`: メンテナンスフラグ
- `min_supported_version`: 最小サポートバージョン

### Analytics Events
- `app_open`: 起動
- `match_completed`: 対戦完了（勝敗・スコア記録）
- `skill_triggered`: スキル発動 ⭐ **Aha Moment**
- `warden_leveled_up`: ワーデンレベルアップ
- `share_created`: シェアカード作成

詳細: [analytics_events.md](/analytics_events.md)

---

## 🎮 MVP Warden仕様

| 駒 | Warden名 | モチーフ | スキル | トリガー |
|----|---------|--------|--------|---------|
| King | 鬼王（Oni King） | 鬼 | 被弾時に一度だけ生存（不死） | HP0到達時 |
| Queen | 九尾（Kitsune） | 狐 | 隣接マスに炎ダメージ拡散 | 攻撃成功時 |
| Rook | 大蛇（Orochi） | 蛇 | 一定ターン被スキル無効（鉄壁） | ターン開始時 |
| Knight | 天狗（Tengu） | 天狗 | 移動後1マス追加ジャンプ | 移動確定後 |

---

## ⚙️ Technical Validation

### ChessEngineService
- [x] Move generation: 全駒種の合法手生成
- [x] Board state: HP/スキル属性を保持
- [x] Evaluation: 駒のHP・スキル発動状態を評価値に反映
- [x] Minimax: 深さ2-3でブランチング削減、計算時間 <500ms/move

**Note**: Stockfish等の標準チェスエンジンはスキル込み局面を正しく評価できないため不採用。

---

## 🎬 Skill Animations

MVP Wardens のユニークスキル演出は Lottie (.json) アニメーションで実装：

| Warden | スキル | ファイル | 効果 |
|--------|--------|--------|------|
| 鬼王 | 不死 | `skill_immortality.json` | 紫⊙金の輪郭、1500ms |
| 九尾 | 炎ダメージ拡散 | `skill_spread_damage.json` | 橙⊙赤の波紋、1000ms |
| 大蛇 | 鉄壁 | `skill_shield_turns.json` | 青盾+回転枠、1200ms |
| 天狗 | 追加ジャンプ | `skill_jump_move.json` | 紫青軌跡+着地、1000ms |

**実装**: 
- `lib/services/skill_animation_service.dart` - 一元管理（アセット路、再生時間）
- `lib/views/widgets/skill_animation_overlay.dart` - Lottie 再生ウィジェット
- `lib/views/match_screen.dart` - 対戦中の自動再生

詳細: [ANIMATIONS.md](/ANIMATIONS.md)

---

## 🎨 Design System

### Material 3
- Color scheme: Dynamic color support（ライト/ダークモード）
- Typography: 日本語対応フォント（源ノ角ゴシック推奨）
- Spacing: 8dp ベースのグリッドシステム

### Theme
- **Primary**: Purple（妖怪テーマ）
- **Secondary**: Orange（スキル・EXP表現）
- **Tertiary**: Blue（UI アクセント）
- **Background**: Off-white（ライト）/ Dark gray（ダーク）

### Responsive Design
- Mobile-first approach（6 inch 以上対応）
- Tablet: 横向きサポート（将来）

---

## 🧪 Testing & CI/CD

### Unit Tests
```bash
flutter test
```
- `test/services/chess_engine_service_test.dart`: 盤面・合法手・評価値
- `test/models/`: データモデル（Warden、UserWarden）

### CI/CD Pipeline
```yaml
flutter_ci.yml:
  - flutter analyze     # 静的解析
  - flutter test        # ユニットテスト
  - codecov             # カバレッジ報告
  - flutter build apk   # APK ビルド（PR/Manual時）

build-release.yml:      # Tag push 時
  - flutter build appbundle --release   # Android AAB
  - flutter build ios --release         # iOS IPA (unsigned)
```

詳細: [SETUP_GUIDE.md](/SETUP_GUIDE.md#ci-cd-パイプライン)

---

## 📱 Platform Support

| Platform | Status | Min Version | Notes |
|----------|--------|-------------|-------|
| iOS | ✅ Supported | 12.0+ | App Store & TestFlight 対応 |
| Android | ✅ Supported | API 21+ | Google Play & Firebase App Distribution |
| Web | ❌ Not Planned | - | Flutter Web の安定化待ち |
| macOS | ❌ Not Planned | - | - |

---

## 📚 Documentation

| ドキュメント | 内容 |
|------------|------|
| [SETUP_GUIDE.md](/SETUP_GUIDE.md) | ローカル開発環境セットアップ、Firebase 設定手順 |
| [FIREBASE_SETUP.md](/FIREBASE_SETUP.md) | Firebase Console 詳細設定ガイド、セキュリティルール、バックアップ戦略 |
| [ANIMATIONS.md](/ANIMATIONS.md) | Lottie アニメーション仕様、カスタマイズガイド |
| [analytics_events.md](/analytics_events.md) | Firebase Analytics イベント定義、ファネル分析、KPI 定義 |

---

## 🚀 Getting Started

```bash
# 依存パッケージをインストール
flutter pub get

# テスト実行
flutter test

# ビルド（iOS）
flutter build ios

# ビルド（Android）
flutter build apk
```

### Firebase設定
```bash
# FlutterFire CLIで自動設定
flutterfire configure
```

---

## 🤝 Contributing

Chess Wardens はコミュニティ貢献をお待ちしています！

### Code Style
- Dart: [Official Dart Style Guide](https://dart.dev/guides/language/effective-dart/style)
- Flutter: BLoC/Riverpod パターンに準拠
- 日本語コメント推奨（ドメイン知識共有のため）

### PR フロー
1. `main` ブランチからフィーチャーブランチを作成
2. テストを追加・実行 (`flutter test`)
3. 静的解析を確認 (`flutter analyze`)
4. PR を作成（テンプレートあり）
5. Code Review 後マージ

### Issues
- バグ報告: `[BUG]` プレフィックス
- 機能リクエスト: `[FEATURE]` プレフィックス
- 質問: `[QUESTION]` プレフィックス

---

## 📋 Known Issues & Future TODOs

### Current Limitations
1. **firebase_options.dart**: FlutterFire CLI で再構成が必要です
2. **Web/Desktop**: モバイル専用設計のため、Web/macOS サポートは計画外
3. **AI vs AI**: 現在プレイヤー vs AI のみ対応

### Planned Features
- [ ] Warden スキン（RevenueCat 課金）
- [ ] シーズン限定 Warden 追加
- [ ] マッチメイキング・ランキングシステム
- [ ] ギルド・フレンド機能
- [ ] ライブPvP対戦

---

## 📖 References & Resources

### 技術ドキュメント
- [Flutter Riverpod](https://riverpod.dev/) - State Management
- [Firebase for Flutter](https://firebase.flutter.dev/) - Backend
- [Lottie for Flutter](https://pub.dev/packages/lottie) - Animations

### アルゴリズム
- [Minimax Algorithm](https://en.wikipedia.org/wiki/Minimax)
- [Alpha-Beta Pruning](https://en.wikipedia.org/wiki/Alpha%E2%80%93beta_pruning)
- [Chess Move Generation](https://www.chessprogramming.org/Move-Generation)

### デザイン・ゲームデザイン
- [Material Design 3](https://m3.material.io/)
- [Game Feel](https://www.amazon.com/Game-Feel-Game-Mechanics-Communication/dp/0982928629) - Steve Swink
- [Midcore Game Design](https://www.gamasutra.com/features/) - Gamasutra

---

## 📧 Support & Contact

問題や質問がある場合：

1. **GitHub Issues**: [GitHub Issues](https://github.com/zka32101/chesswardens/issues) を確認・作成
2. **Documentation**: [SETUP_GUIDE.md](/SETUP_GUIDE.md) のトラブルシューティング確認
3. **Community**: Discord/Slack コミュニティ（準備中）

---

## 📄 License

Chess Wardens は **MIT License** の下で公開されています。

```
MIT License

Copyright (c) 2026 Chess Wardens Contributors

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.
```

詳細: [LICENSE](/LICENSE)

---

## 🎮 Game Design Credits

- **Game Design**: 妖怪IP × チェス の融合コンセプト
- **Warden Lore**: 日本伝承（鬼王、九尾、大蛇、天狗）
- **AI Engine**: Minimax + α-β 刈り込みアルゴリズム
- **UI/UX**: Material Design 3 + 和風テーマ

---

**Last Updated**: 2026-09-08  
**Version**: MVP 1.0.0 ✅ Complete  
**Maintenance**: Active Development  
**Repository**: [zka32101/chesswardens](https://github.com/zka32101/chesswardens)