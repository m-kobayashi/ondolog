# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## プロジェクト概要

**サービス名**: オンドログ（OndoLog）
**概要**: HACCP対応の温度記録管理アプリ
**詳細仕様**: SPEC.md を参照

## 技術スタック

### フロントエンド (app/)
- Flutter 3.x (Dart)
- 状態管理: flutter_riverpod
- ローカルDB: hive
- HTTPクライアント: dio
- ルーティング: go_router

### バックエンド (api/)
- Cloudflare Workers (TypeScript)
- Cloudflare D1 (SQLite)
- Cloudflare KV (キャッシュ)
- APIフレームワーク: hono

### 認証
- Firebase Authentication

## 開発コマンド

### Flutter (app/)
```bash
cd app
flutter pub get          # 依存関係インストール
flutter run              # 開発実行
flutter test             # テスト実行
flutter analyze          # 静的解析
flutter build appbundle  # Android リリースビルド
flutter build ios        # iOS リリースビルド
```

### Cloudflare Workers (api/)
```bash
cd api
npm install              # 依存関係インストール
npm run dev              # ローカル開発サーバー
npm test                 # テスト実行
npm run lint             # Lint実行
npx wrangler deploy      # デプロイ
npx wrangler tail        # ログ確認
```

### D1 データベース
```bash
cd api
npx wrangler d1 execute ondolog-db --local --file=./schema.sql  # ローカル
npx wrangler d1 execute ondolog-db --file=./schema.sql          # 本番
```

## ディレクトリ構成

```
ondolog/
├── app/                    # Flutter アプリ
│   ├── lib/
│   │   ├── main.dart
│   │   ├── config/         # 設定・定数
│   │   ├── models/         # データモデル
│   │   ├── providers/      # Riverpod プロバイダ
│   │   ├── services/       # API・認証サービス
│   │   ├── screens/        # 画面
│   │   ├── widgets/        # 共通ウィジェット
│   │   └── utils/          # ユーティリティ
│   └── pubspec.yaml
│
├── api/                    # Cloudflare Workers
│   ├── src/
│   │   ├── index.ts        # エントリポイント
│   │   ├── routes/         # APIルート
│   │   ├── middleware/     # 認証・CORS
│   │   ├── services/       # Firebase連携
│   │   └── utils/          # ユーティリティ
│   ├── wrangler.toml
│   └── package.json
│
├── .github/workflows/      # GitHub Actions
├── CLAUDE.md               # このファイル
├── SPEC.md                 # 詳細仕様
└── README.md
```

## 開発ルール

### オフラインファースト
- 必ずHiveでローカル保存を実装
- API失敗時はローカルデータで継続
- オンライン復帰時に同期

### 温度基準判定
- 記録ポイントごとに基準温度を設定
- 基準外の場合は異常フラグを立てる
- 異常時は対応内容を必須入力

### HACCP対応
- 記録日時は自動付与（改ざん防止）
- 過去の記録は編集不可（追記のみ）
