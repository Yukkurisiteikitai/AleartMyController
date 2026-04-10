# 現在のDBスキーマ

このアプリのローカルDBは Room で管理されており、DB名は `aleart_my_controller.db`、現行バージョンは `2` です。

## 全体構成

テーブルは 4 つあります。

- `events`: Google Calendar のイベントをキャッシュする親テーブル
- `records`: イベントに紐づく観察ログの本体テーブル
- `photos`: 写真記録の添付情報テーブル
- `memos`: メモ記録の添付情報テーブル

関係は次の通りです。

- `events` 1件に対して `records` が複数件ぶら下がる
- `records` 1件に対して `photos` または `memos` がぶら下がる
- `photos` と `memos` はそれぞれ `records.recordId` を外部キーに持つ
- `records` は `events.eventId` を外部キーに持つ

## events

Google Calendar の予定を保持します。

- 主キー: `eventId` (自動採番)
- カラム:
	- `googleEventId`: Google 側イベントID。ユニーク制約あり
	- `title`: イベント名
	- `startTime`: 開始時刻の epoch millis
	- `endTime`: 終了時刻の epoch millis

補足:

- `googleEventId` にはユニークインデックスが張られています
- これは同期時の重複排除と検索高速化に使われます

## records

イベントに対する観察ログの本体です。

- 主キー: `recordId` (自動採番)
- 外部キー: `eventId` -> `events.eventId`
- カラム:
	- `eventId`: 紐づくイベントID
	- `recordTime`: 記録時刻の epoch millis
	- `recordType`: `PHOTO` か `MEMO`

補足:

- `recordType` は enum `RecordType` を Room の TypeConverter で文字列保存しています
- `records` は記録の共通本体で、写真かメモかの種別を持ちます

## photos

写真記録の添付データです。

- 主キー: `photoId` (自動採番)
- 外部キー: `recordId` -> `records.recordId`
- カラム:
	- `recordId`: 対応する記録ID
	- `filePath`: 端末内ストレージ上のファイルパス

補足:

- `records` が削除されると、関連する `photos` も CASCADE で削除されます
- 1つの記録に対して複数写真を持てる設計です

## memos

メモ記録の添付データです。

- 主キー: `memoId` (自動採番)
- 外部キー: `recordId` -> `records.recordId`
- カラム:
	- `recordId`: 対応する記録ID
	- `memoText`: メモ本文
	- `isVoiceMemo`: 音声入力由来かどうか

補足:

- `records` が削除されると、関連する `memos` も CASCADE で削除されます
- テキスト入力と音声入力を同じテーブルで扱います

## 集計・参照の使われ方

DAO では次のような使い方をしています。

- `EventDao`: 予定の取得、現在進行中イベントの取得、古いキャッシュ削除
- `RecordDao`: イベント別の記録取得、添付込み取得、種別別件数の集計
- `PhotoDao` / `MemoDao`: 記録単位の添付取得
- `AnalyticsDao`: 日別件数、種別別件数、イベント別件数の集計

特に `records` は集計の中心テーブルで、画面表示や分析のほとんどがここを起点にしています。

## マイグレーション

現行のマイグレーションは `1 -> 2` のみです。

- `events.googleEventId` にユニークインデックスを追加
- 既存DBでは `index_events_googleEventId` を作成します

## 実装上のポイント

- `events` は Google Calendar 同期のローカルキャッシュ
- `records` はイベントに対する観察ログの共通親テーブル
- `photos` と `memos` は `records` の添付テーブル
- `RecordWithAttachments` を使うことで、記録本体と添付をまとめて取得できます
