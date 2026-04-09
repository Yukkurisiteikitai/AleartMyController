# 観察記録アラームアプリ 仕様書 v1

## 1. 目的

Google Calendar の予定に対して実際の行動との差異を観察・記録する Android アプリケーション。

予定

* Google Calendar

作業ログ

* Toggl Track

本アプリでは以下を記録する。

* 写真（証拠）
* メモ
* 音声入力メモ

初期バージョンではバックエンドは使用せず、すべてスマートフォン内に保存する。

---

## 2. 基本コンセプト

予定 → 実行 → 記録 → 振り返り

Google Calendar のイベントを基準に観察ログを積み上げる。

イベント
↓
観察記録

---

## 3. 外部サービス連携

### 3.1 Google Calendar

取得情報

* eventId
* title
* startTime
* endTime

イベントIDで記録を紐づける。

### 3.2 Toggl Track

作業時間ログの参照。

---

## 4. データ保存

すべてローカル保存。

画像

* 端末ストレージ

データベース

* SQLite / Room

保存データ

* eventId
* timestamp
* image_path
* memo_text
* voice_memo_text

---

## 5. 記録ルール

### 1時間未満

終了時のみ写真撮影

### 1時間以上

1時間ごとに写真撮影

終了時にも撮影

---

## 6. 撮影インターバル設定

プリセット

* 1分
* 3分
* 5分
* 10分
* 25分
* 30分
* 1時間
* カスタム

カスタムはダイヤルUIで設定。

プリセット順序はユーザー設定で変更可能。

---

## 7. メモ機能

入力方法

* テキスト入力
* 音声入力

音声入力は Speech-to-Text を使用。

---

## 8. UIデザイン

### 8.1 デザイン方針

Material Design 3 を採用。

Android 標準 UI に準拠。

記録操作を最短導線に配置。

---

### 8.2 画面構成

主要画面

* イベント一覧
* イベント詳細
* 記録追加
* 履歴
* 設定

---

### 8.3 イベント一覧

Google Calendar のイベントを表示。

表示内容

* イベント名
* 開始時間
* 終了時間
* 記録数

例

09:00 数学勉強
📷2 📝1

---

### 8.4 イベント詳細

イベントに紐づく観察ログを表示。

タイムライン形式。

例

09:10 写真
09:30 メモ
10:00 写真

---

### 8.5 記録追加

イベント詳細から記録を追加。

記録タイプ

* 写真
* 音声メモ
* テキストメモ

---

### 8.6 履歴

過去のイベント記録を一覧表示。

---

### 8.7 設定

設定内容

* 撮影インターバル
* プリセット順序
* 通知設定

---

## 9. データモデル

### events

* event_id
* google_event_id
* title
* start_time
* end_time

### records

* record_id
* event_id
* record_time
* record_type

record_type

* photo
* memo

### photos

* photo_id
* record_id
* file_path

### memos

* memo_id
* record_id
* memo_text

---

## 10. 今後の拡張

将来的に以下を追加予定。

* クラウド同期
* Web UI
* Discord Bot バックアップ
