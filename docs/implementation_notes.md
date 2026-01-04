# 実装メモ（Flutter + SQLite / MVP）

最終更新: 2025-12-21

本ドキュメントは、[docs/requirements.md](requirements.md) を実装へ落とし込むためのメモです。

## 1. 画面構成（ナビゲーション）

- ルート: BottomNavigationBar（3タブ）
  - Todo一覧
  - 継続目標一覧
  - 設定

- Todo一覧タブ
  - 内側タブ: 未完了 / 完了済み
  - FAB: 作成
  - 行タップ: 詳細/編集

- 継続目標一覧タブ
  - 内側タブ: 未完了 / 完了済み
  - FAB: 作成
  - 行タップ: 詳細/編集（分子+1/-1操作を含む）

- 設定タブ
  - データ注意文（確定文言をそのまま表示）
  - 問い合わせ（メールのみ）

## 2. 広告（AdMobバナー）配置

要件の通り、一覧画面のみ（詳細/作成/編集は表示しない）。

- Todo一覧: 画面下部にバナー
  - 未完了/完了済みのどちらの内側タブでも表示
- 継続目標一覧: 画面下部にバナー
  - 未完了/完了済みのどちらの内側タブでも表示

挙動（MVP）
- 画面遷移/タブ切替での軽微なチラつきは許容
- オフライン/ロード失敗時はバナー領域を表示しない（空白を残さない）

運用
- 広告ユニットIDは iOS / Android で分ける
- 開発中はテスト広告を使用する

## 3. ローカルDB（SQLite）

### 3-1. テーブル案

#### todos

- id: INTEGER PRIMARY KEY AUTOINCREMENT
- title: TEXT NOT NULL
- memo: TEXT NOT NULL DEFAULT ''
- is_completed: INTEGER NOT NULL (0/1)
- created_at: INTEGER NOT NULL（epoch millis 推奨）
- updated_at: INTEGER NOT NULL（epoch millis 推奨）

#### habits（継続目標）

- id: INTEGER PRIMARY KEY AUTOINCREMENT
- name: TEXT NOT NULL
- denominator: INTEGER NOT NULL（>= 1）
- numerator: INTEGER NOT NULL（0〜denominator）
- is_completed: INTEGER NOT NULL (0/1) ※派生でもよいが、一覧検索を簡単にするなら保持も可
- created_at: INTEGER NOT NULL（epoch millis 推奨）
- updated_at: INTEGER NOT NULL（epoch millis 推奨）

### 3-2. 更新日時ルール

- 作成時: created_at と updated_at は同値
- 変更時: ユーザー操作で内容/状態が変わるたび updated_at を更新
  - Todo: タイトル/メモ更新、完了/未完了切替
  - 継続目標: 目標名/分母更新、分子+1/-1

### 3-3. 一覧のソート

- 主キー: updated_at
- 同一 updated_at の場合: created_at
- それでも同値: 安定ソート（DBの返却順をそのまま）

SQL例（新しい順）:
- ORDER BY updated_at DESC, created_at DESC

## 4. 主要ロジックの注意点

### 4-1. Todo

- 完了にした瞬間
  - 一覧から移動（未完了→完了済み）
  - 達成ダイアログ（閉じる/取り消し）
  - 取り消しは「直前の完了操作のみ」

- 完了済みの編集制限
  - タイトルは編集不可
  - メモのみ編集可能

### 4-2. 継続目標

- +1
  - numerator < denominator の時のみ有効
  - numerator == denominator になった瞬間に完了扱い、達成ダイアログ表示
  - 取り消しは「直前の +1 のみ」

- -1
  - 0未満にしない
  - denominator 未満になれば未完了に戻る

- 分母変更
  - denominator は >= 1
  - 変更により完了状態が変化（完了↔未完了）する場合は警告
  - 警告文言（確定）: 「目標回数を変更すると、達成状態が変わります。保存しますか？」
  - ボタン（案）: キャンセル / 保存

## 5. 実装時のパッケージ候補（参考）

- SQLite: sqflite（または drift 等）
- 状態管理: Riverpod / Bloc / Provider（プロジェクト方針に合わせて選択）
- 広告: google_mobile_ads

※実際の採用は、プロジェクト初期化時に確定する。
