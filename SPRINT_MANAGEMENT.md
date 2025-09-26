# ツーリングマップアプリ - スプリント管理

## 📋 スプリント概要

| スプリント | 期間 | ステータス | 主要機能 |
|-----------|------|-----------|----------|
| Sprint 1 | 基盤構築 | ✅ 完了 | プロジェクトセットアップ、データモデル、API設計 |
| Sprint 2 | ルート作成・管理 | ✅ 完了 | ルート作成、一覧、詳細、エクスポート・インポート |
| Sprint 3 | ヤエー・スポット機能 | 🔄 準備中 | ヤエー記録、スポットDB、共有機能 |
| Sprint 4 | 高度機能 | ⏳ 未開始 | ルート編集、認証、プライバシー機能 |
| Sprint 5 | 最適化・拡張 | ⏳ 未開始 | パフォーマンス最適化、追加機能 |

---

## 🚀 Sprint 1: 基盤構築 (完了)

### ✅ 実装完了項目
- [x] Flutter プロジェクトセットアップ
- [x] Material Design 3対応
- [x] 依存関係管理 (Riverpod, Dio, Geolocator, Mapbox等)
- [x] データモデル設計 (User, Route, Waypoint, Spot, YaeEvent, Share)
- [x] JSONシリアライゼーション対応
- [x] サービス層実装 (ApiService, LocationService, FileService)
- [x] PostgreSQL + PostGIS データベース設計
- [x] OpenAPI 3.0 完全仕様書
- [x] 認証・エラーハンドリング設計

### 📁 作成ファイル
```
lib/
├── models/          # データモデル
│   ├── user.dart
│   ├── route.dart
│   ├── waypoint.dart
│   ├── spot.dart
│   ├── yae_event.dart
│   └── share.dart
├── services/        # サービス層
│   ├── api_service.dart
│   ├── location_service.dart
│   └── file_service.dart
└── providers/       # Riverpodプロバイダー
    ├── route_provider.dart
    └── location_provider.dart

backend/
├── api/            # OpenAPI仕様書
├── database/        # データベーススキーマ
└── migrations/      # マイグレーション
```

---

## 🎯 Sprint 2: ルート作成・管理機能 (完了)

### ✅ 実装完了項目
- [x] ルート作成画面 (地図上ポイント打ち・線補完)
- [x] Mapbox GL地図統合・インタラクション
- [x] ルート一覧画面 (検索・フィルター・ソート)
- [x] ルート詳細画面 (地図表示・統計情報・アクション)
- [x] GPX/KMLエクスポート機能 (複数形式対応)
- [x] ファイルインポート機能 (GPX/KML読み込み・解析)
- [x] プロバイダー層の実装
- [x] エラーハンドリング・UI/UX改善

### 📁 作成ファイル
```
lib/screens/
├── route_creation_screen.dart    # ルート作成画面
├── route_list_screen.dart        # ルート一覧画面
├── route_detail_screen.dart      # ルート詳細画面
├── export_screen.dart            # エクスポート画面
└── import_screen.dart            # インポート画面
```

### 🔧 技術的特徴
- Material Design 3 UI
- Riverpod状態管理
- Mapbox GL地図統合
- 非同期ファイル処理
- レスポンシブデザイン

---

## 🎯 Sprint 3: ヤエー・スポット機能 (準備中)

### 📋 実装予定項目

#### ヤエー記録機能
- [ ] GPS近接マッチングアルゴリズム
- [ ] リアルタイム位置追跡
- [ ] ヤエーイベント検出・記録
- [ ] ヤエー履歴画面
- [ ] ヤエー統計・プロフィール表示
- [ ] プライバシー設定（位置情報マスキング）

#### スポットDB機能
- [ ] スポット投稿画面
- [ ] スポット一覧・検索画面
- [ ] スポット詳細画面
- [ ] タグベース検索・フィルター
- [ ] スポット評価・レビュー機能
- [ ] モデレーション機能

#### 共有機能
- [ ] URL共有トークン生成
- [ ] QRコード生成・表示
- [ ] 深いリンク対応
- [ ] 共有設定（期限・権限）
- [ ] 共有履歴管理

### 📁 予定作成ファイル
```
lib/screens/
├── yae_history_screen.dart       # ヤエー履歴画面
├── yae_profile_screen.dart        # ヤエー統計画面
├── spot_list_screen.dart          # スポット一覧画面
├── spot_detail_screen.dart        # スポット詳細画面
├── spot_creation_screen.dart      # スポット投稿画面
├── share_screen.dart              # 共有画面
└── qr_display_screen.dart         # QRコード表示画面

lib/services/
├── yae_service.dart               # ヤエー処理サービス
├── spot_service.dart              # スポット処理サービス
└── share_service.dart              # 共有処理サービス

lib/providers/
├── yae_provider.dart              # ヤエー状態管理
├── spot_provider.dart             # スポット状態管理
└── share_provider.dart            # 共有状態管理
```

### 🔧 技術要件
- バックグラウンド位置追跡
- 近接検出アルゴリズム
- QRコード生成ライブラリ
- 深いリンク処理
- プッシュ通知

---

## 🎯 Sprint 4: 高度機能 (未開始)

### 📋 実装予定項目

#### ルート編集機能
- [ ] ルート編集画面
- [ ] ポイント追加・削除・移動
- [ ] ルート分割・結合
- [ ] ルート最適化（距離・時間）
- [ ] バージョン管理・履歴

#### 認証システム
- [ ] ユーザー登録・ログイン画面
- [ ] ソーシャルログイン対応
- [ ] プロフィール管理
- [ ] アカウント設定
- [ ] パスワードリセット

#### プライバシー機能
- [ ] 位置情報マスキング
- [ ] 公開遅延設定
- [ ] 精度丸め設定
- [ ] データエクスポート・削除
- [ ] プライバシーポリシー

### 📁 予定作成ファイル
```
lib/screens/
├── auth/
│   ├── login_screen.dart
│   ├── register_screen.dart
│   ├── profile_screen.dart
│   └── settings_screen.dart
├── route_edit_screen.dart         # ルート編集画面
└── privacy_screen.dart            # プライバシー設定画面

lib/services/
├── auth_service.dart              # 認証サービス
├── privacy_service.dart           # プライバシーサービス
└── route_edit_service.dart        # ルート編集サービス
```

---

## 🎯 Sprint 5: 最適化・拡張 (未開始)

### 📋 実装予定項目

#### パフォーマンス最適化
- [ ] 地図タイルキャッシュ
- [ ] 画像最適化・圧縮
- [ ] データベースクエリ最適化
- [ ] メモリ使用量最適化
- [ ] バッテリー消費最適化

#### 追加機能
- [ ] オフライン機能
- [ ] ダークモード対応
- [ ] 多言語対応
- [ ] アクセシビリティ対応
- [ ] アナリティクス統合

#### バックエンド実装
- [ ] NestJS/FastAPI サーバー実装
- [ ] データベースマイグレーション
- [ ] API エンドポイント実装
- [ ] 認証・認可システム
- [ ] ファイルストレージ統合

### 📁 予定作成ファイル
```
backend/
├── src/
│   ├── controllers/               # APIコントローラー
│   ├── services/                 # ビジネスロジック
│   ├── repositories/             # データアクセス層
│   ├── middleware/              # ミドルウェア
│   └── utils/                   # ユーティリティ
├── tests/                       # テストファイル
└── docker/                      # Docker設定
```

---

## 🛠 開発環境セットアップ

### 前提条件
- Flutter SDK 3.5.4以上
- Dart SDK 3.5.4以上
- PostgreSQL 14以上 + PostGIS
- Node.js 18以上 (バックエンド用)

### セットアップ手順
```bash
# 1. プロジェクトクローン
git clone <repository-url>
cd touring_map_app

# 2. Flutter依存関係インストール
flutter pub get

# 3. コード生成実行
flutter packages pub run build_runner build

# 4. テスト実行
flutter test

# 5. アプリ実行
flutter run
```

### バックエンドセットアップ (Sprint 5)
```bash
cd backend
npm install
npm run dev
```

---

## 📊 進捗管理

### 完了率
- Sprint 1: 100% ✅
- Sprint 2: 100% ✅
- Sprint 3: 0% ⏳
- Sprint 4: 0% ⏳
- Sprint 5: 0% ⏳

### 全体進捗: 40% (2/5 スプリント完了)

---

## 🎯 次のアクション

1. **Sprint 3開始**: ヤエー記録機能の実装
2. **バックエンド準備**: APIサーバーの設計・実装
3. **テスト環境構築**: 自動テスト・CI/CD設定
4. **ドキュメント整備**: API仕様書・ユーザーガイド

---

## 📝 メモ

- 各スプリントは独立して実装可能
- バックエンドはSprint 5で本格実装予定
- 現在はモックAPIで動作確認
- Mapboxトークンは環境変数で管理予定
