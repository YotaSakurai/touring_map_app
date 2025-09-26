# ツーリングマップアプリ

ツーリング専用マップアプリ - ルート作成・共有・ヤエー記録

## 🚀 スプリント1: コア機能開発中

### 実装済み機能

#### ✅ プロジェクト基盤
- **Flutter プロジェクトセットアップ**: Material Design 3対応
- **依存関係管理**: Riverpod、Dio、Geolocator、Mapbox等
- **コード生成**: JSONシリアライゼーション対応

#### ✅ データモデル
- **User**: ユーザー情報（プライバシーレベル対応）
- **Route**: ルート情報（GeoJSON MultiLineString）
- **Waypoint**: ウェイポイント（順序保証）
- **Spot**: スポット情報（タグ検索対応）
- **YaeEvent**: ヤエーイベント（近接マッチング）
- **Share**: 共有トークン（期限付き）

#### ✅ サービス層
- **ApiService**: REST API クライアント（Dio使用）
- **LocationService**: 位置情報取得・処理
- **FileService**: GPX/KML ファイル処理

#### ✅ データベース設計
- **PostgreSQL + PostGIS**: 地理データ対応
- **スキーマ設計**: 全テーブル・インデックス・制約定義
- **サンプルデータ**: テスト用データ挿入

#### ✅ API設計
- **OpenAPI 3.0**: 完全なAPI仕様書
- **認証**: JWT Bearer認証
- **エラーハンドリング**: 適切なHTTPステータスコード

### 🔄 実装予定機能

#### スプリント1残り
- **ルートCRUD画面**: 地図上でのルート作成・編集
- **GPX/KMLエクスポート**: ファイル出力機能
- **インポート機能**: GPX/KMLファイル読み込み

#### スプリント2以降
- **ヤエー記録**: GPS近接マッチング
- **スポットDB**: ユーザー投稿・検索
- **共有機能**: URL/QRコード生成
- **認証システム**: ユーザー登録・ログイン

## 🛠 技術スタック

### フロントエンド
- **Flutter**: クロスプラットフォーム開発
- **Riverpod**: 状態管理
- **Material Design 3**: UIデザイン

### バックエンド（設計済み）
- **PostgreSQL + PostGIS**: 地理データベース
- **NestJS/FastAPI**: APIサーバー
- **Redis**: キャッシュ・セッション管理
- **S3**: ファイルストレージ

### 地図・位置情報
- **Mapbox GL**: 地図表示
- **Geolocator**: 位置情報取得
- **GeoJSON**: 地理データ形式

## 📁 プロジェクト構造

```
touring_map_app/
├── lib/
│   ├── models/          # データモデル
│   ├── services/        # サービス層
│   ├── providers/       # Riverpodプロバイダー
│   ├── screens/         # UI画面
│   ├── widgets/         # 再利用可能ウィジェット
│   └── utils/           # ユーティリティ
├── backend/
│   ├── api/            # OpenAPI仕様書
│   ├── database/        # データベーススキーマ
│   └── migrations/      # マイグレーション
└── test/               # テストファイル
```

## 🚀 セットアップ・実行

### 前提条件
- Flutter SDK 3.5.4以上
- Dart SDK 3.5.4以上

### インストール
```bash
# 依存関係のインストール
flutter pub get

# コード生成の実行
flutter packages pub run build_runner build

# テストの実行
flutter test

# アプリの実行
flutter run
```

## 📋 開発状況

### スプリント1進捗
- [x] プロジェクトセットアップ
- [x] データモデル設計
- [x] サービス層実装
- [x] データベース設計
- [x] API設計
- [ ] ルートCRUD画面
- [ ] GPX/KMLエクスポート
- [ ] インポート機能

### 次のステップ
1. **ルート作成画面**: 地図上でのポイント打ち・線補完
2. **エクスポート機能**: GPX/KMLファイル生成
3. **インポート機能**: ファイル読み込み・解析
4. **バックエンド実装**: NestJS/FastAPIサーバー

## 📄 ライセンス

このプロジェクトはMITライセンスの下で公開されています。

## 👥 開発チーム

プロのFlutterデベロッパーが開発した高品質なアプリです。