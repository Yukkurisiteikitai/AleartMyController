# AMC 共有ログ基盤 引き継ぎ資料

作成日: 2026-05-28

## 概要

このリポジトリでは、AMC 共有ログ基盤の Android 側の土台を追加した。

現時点の実装は「Android クライアント側のローカル下書き・再送キュー・ミラー補助・添付キューの再試行状態と構造化ログの土台」までで、Supabase / R2 / 共有 API / RLS などのサーバー側実装は未着手。

## 確定した設計前提

- AMC は YourselfLM の機能として統合する
- 正本は Supabase
- 添付メディアは private R2 bucket `amc-yourselflm`
- 共有は DB + API 認可で管理し、R2 は ACL を持たない
- Google Calendar は全文ミラーを維持するが、長文時は要約 + 本文参照 URL に退避する
- オフラインは本文 + 添付キューまで許容し、Room は下書き・キャッシュ・再送キューとして扱う
- `limited public` は `c=... + YourselfLM 認証` 必須
- `share_links` は入口トークン、`share_grants` は恒久 ACL
- `amc_records.current_revision` を現在版として持ち、`amc_record_revisions` は履歴のみ保持する
- `revisions insert` と `current_revision / current_body / updated_at` 更新は同一トランザクションで行う
- `Google subject` と `auth.users.id` は 1対1 厳密を原則とする
- RLS は保険、API が主導
- `GET /api/amc/records/:id/access` は閲覧時メタデータのみ返す
- エラーコードは `401 / 403 / 404 / 409 / 422` を固定運用する

## Android 側で実装した内容

### 1. AMC 共通モデル

追加ファイル:

- [app/src/main/java/com/example/aleartmycontroller/data/amc/AmcModels.kt](/Users/yuuto/learn_lab/AleartMyController/app/src/main/java/com/example/aleartmycontroller/data/amc/AmcModels.kt)
- [app/src/main/java/com/example/aleartmycontroller/data/amc/AmcContentPolicy.kt](/Users/yuuto/learn_lab/AleartMyController/app/src/main/java/com/example/aleartmycontroller/data/amc/AmcContentPolicy.kt)
- [app/src/main/java/com/example/aleartmycontroller/data/amc/AmcIdempotency.kt](/Users/yuuto/learn_lab/AleartMyController/app/src/main/java/com/example/aleartmycontroller/data/amc/AmcIdempotency.kt)

内容:

- 添付種別、添付状態、同期状態、ソース、outbox job 種別の enum を追加
- 添付状態に `NEEDS_RETRY` / `EXPIRED`、client complete 用に `AmcAttachmentClientResult` を追加
- プレーンテキストの保存前正規化を追加
- Google Calendar ミラー本文を生成する helper を追加
- idempotency key 生成 helper を追加

### 2. AMC 用 Room エンティティ

追加ファイル:

- [app/src/main/java/com/example/aleartmycontroller/data/local/entity/amc/AmcDraftRecordEntity.kt](/Users/yuuto/learn_lab/AleartMyController/app/src/main/java/com/example/aleartmycontroller/data/local/entity/amc/AmcDraftRecordEntity.kt)
- [app/src/main/java/com/example/aleartmycontroller/data/local/entity/amc/AmcRecordRevisionEntity.kt](/Users/yuuto/learn_lab/AleartMyController/app/src/main/java/com/example/aleartmycontroller/data/local/entity/amc/AmcRecordRevisionEntity.kt)
- [app/src/main/java/com/example/aleartmycontroller/data/local/entity/amc/AmcAttachmentQueueEntity.kt](/Users/yuuto/learn_lab/AleartMyController/app/src/main/java/com/example/aleartmycontroller/data/local/entity/amc/AmcAttachmentQueueEntity.kt)
- [app/src/main/java/com/example/aleartmycontroller/data/local/entity/amc/AmcOutboxEntity.kt](/Users/yuuto/learn_lab/AleartMyController/app/src/main/java/com/example/aleartmycontroller/data/local/entity/amc/AmcOutboxEntity.kt)
- [app/src/main/java/com/example/aleartmycontroller/data/local/entity/amc/AmcTypeConverters.kt](/Users/yuuto/learn_lab/AleartMyController/app/src/main/java/com/example/aleartmycontroller/data/local/entity/amc/AmcTypeConverters.kt)

役割:

- `amc_draft_records`
  - ローカル下書き、サーバー同期待ち、削除済みトレースを保持
- `amc_record_revisions`
  - 全文履歴の append-only 保持
- `amc_attachment_queue`
  - 画像・音声のローカル一時保存と R2 upload キュー
  - 現在は `uploadSessionId` / `attemptNumber` / `lastErrorCode` / `expiresAtMillis` を持ち、再試行制御の文脈を保持
- `amc_outbox_jobs`
  - サーバー同期・ミラー更新などの再送キュー

### 3. Room DAO

追加ファイル:

- [app/src/main/java/com/example/aleartmycontroller/data/local/dao/AmcDraftRecordDao.kt](/Users/yuuto/learn_lab/AleartMyController/app/src/main/java/com/example/aleartmycontroller/data/local/dao/AmcDraftRecordDao.kt)
- [app/src/main/java/com/example/aleartmycontroller/data/local/dao/AmcRecordRevisionDao.kt](/Users/yuuto/learn_lab/AleartMyController/app/src/main/java/com/example/aleartmycontroller/data/local/dao/AmcRecordRevisionDao.kt)
- [app/src/main/java/com/example/aleartmycontroller/data/local/dao/AmcAttachmentQueueDao.kt](/Users/yuuto/learn_lab/AleartMyController/app/src/main/java/com/example/aleartmycontroller/data/local/dao/AmcAttachmentQueueDao.kt)
- [app/src/main/java/com/example/aleartmycontroller/data/local/dao/AmcOutboxDao.kt](/Users/yuuto/learn_lab/AleartMyController/app/src/main/java/com/example/aleartmycontroller/data/local/dao/AmcOutboxDao.kt)

内容:

- 下書き一覧・未同期数・未送信添付・未処理 outbox の監視
- draft 作成、revision 追記、削除 mark、添付 queue 登録、outbox job 登録
- 添付 queue の pending 対象は `PENDING` と `NEEDS_RETRY`
- idempotency key による重複防止

### 4. ローカル AMC リポジトリ

追加ファイル:

- [app/src/main/java/com/example/aleartmycontroller/data/repository/AmcDraftRepository.kt](/Users/yuuto/learn_lab/AleartMyController/app/src/main/java/com/example/aleartmycontroller/data/repository/AmcDraftRepository.kt)

内容:

- draft record の作成
- revision 追記
- 論理削除トレース
- 添付キュー登録
- 添付キューの状態遷移時に構造化 Logcat を出力
- outbox job 登録
- Google Calendar ミラー本文の生成

補足:

- revision insert と current revision 更新は `Room.withTransaction` でまとめている
- 保存前に body を NFC 正規化している
- 添付 MIME は whitelist 制にしている
- `markAttachmentUploading` は attempt 番号を進め、`markAttachmentNeedsRetry` と `markAttachmentFailed` を分離した

### 5. 添付キュー構造化ログ

追加ファイル:

- [app/src/main/java/com/example/aleartmycontroller/data/amc/AmcAttachmentQueueLogger.kt](/Users/yuuto/learn_lab/AleartMyController/app/src/main/java/com/example/aleartmycontroller/data/amc/AmcAttachmentQueueLogger.kt)

内容:

- `AMC.AttachmentQueue` タグで key=value 形式の構造化ログを出す
- `queue_enqueued / queue_uploading / queue_ready / queue_needs_retry / queue_failed` を記録
- 将来の API 実装用に `api_init_response` / `api_complete_response` 用 logger を先に用意
- `localUri` はファイル名だけ、`uploadUrl` などは `[redacted]`、`checksum` は短縮して出す

注意:

- 現時点では `AmcApi` を実際に呼ぶ実装はまだ無いので、`api_init_response` / `api_complete_response` は logger の受け口だけ追加済み
- 「厳密ログ」は今回は永続監査ではなく Logcat 優先のデバッグログ強化として実装している

### 6. Remote API スタブ

追加ファイル:

- [app/src/main/java/com/example/aleartmycontroller/data/remote/amc/AmcApi.kt](/Users/yuuto/learn_lab/AleartMyController/app/src/main/java/com/example/aleartmycontroller/data/remote/amc/AmcApi.kt)
- [app/src/main/java/com/example/aleartmycontroller/data/remote/amc/AmcModels.kt](/Users/yuuto/learn_lab/AleartMyController/app/src/main/java/com/example/aleartmycontroller/data/remote/amc/AmcModels.kt)

内容:

- `POST /api/amc/records/init`
- `POST /api/amc/records/:id`
- `POST /api/amc/records/:id/revisions`
- `POST /api/amc/records/:id/attachments/init`
- `POST /api/amc/records/:id/attachments/complete`
- `GET /connect/app/amc/share?c=...`
- `POST /api/amc/share-links/:id/revoke`
- `GET /api/amc/records/:id/access`

これは Android 側の DTO/インターフェース定義のみで、実際の backend は未実装。

添付 DTO 変更:

- `attachments/init` response は `attachment`, `uploadSessionId`, `attemptNumber`, `uploadUrl`, `expiresAtMillis`, `retryable`
- `attachments/complete` request は `attachmentId`, `uploadSessionId`, `attemptNumber`, `clientResult`, `clientErrorCode`, `checksum`
- `attachments/complete` response は `attachment`, `attempt`, `verified`, `retryable`, `reason`

### 7. 既存機能への軽い接続

変更ファイル:

- [app/src/main/java/com/example/aleartmycontroller/data/local/AppDatabase.kt](/Users/yuuto/learn_lab/AleartMyController/app/src/main/java/com/example/aleartmycontroller/data/local/AppDatabase.kt)
- [app/src/main/java/com/example/aleartmycontroller/di/DatabaseModule.kt](/Users/yuuto/learn_lab/AleartMyController/app/src/main/java/com/example/aleartmycontroller/di/DatabaseModule.kt)
- [app/src/main/java/com/example/aleartmycontroller/ui/viewmodel/SettingsViewModel.kt](/Users/yuuto/learn_lab/AleartMyController/app/src/main/java/com/example/aleartmycontroller/ui/viewmodel/SettingsViewModel.kt)
- [app/src/main/java/com/example/aleartmycontroller/ui/screen/SettingsScreen.kt](/Users/yuuto/learn_lab/AleartMyController/app/src/main/java/com/example/aleartmycontroller/ui/screen/SettingsScreen.kt)
- [app/src/main/java/com/example/aleartmycontroller/data/repository/EventRepository.kt](/Users/yuuto/learn_lab/AleartMyController/app/src/main/java/com/example/aleartmycontroller/data/repository/EventRepository.kt)
- [app/src/main/java/com/example/aleartmycontroller/data/repository/RecordRepository.kt](/Users/yuuto/learn_lab/AleartMyController/app/src/main/java/com/example/aleartmycontroller/data/repository/RecordRepository.kt)

変更点:

- Room を v7 に更新し、AMC 用テーブルと添付 queue の追加カラム migration を反映
- AMC 用 DAO を DatabaseModule から提供
- Settings 画面に AMC ローカルキュー要約を表示
- RecordRepository の memo 保存を NFC 正規化
- Google Calendar へのメモ追記を、ミラー本文生成 helper 経由に変更

## Migration / Schema

現在の Room バージョン:

- `AppDatabase` version `7`

追加マイグレーション:

- `MIGRATION_5_6`
  - AMC 用の `amc_draft_records`
  - `amc_record_revisions`
  - `amc_attachment_queue`
  - `amc_outbox_jobs`
  - それぞれの index / unique index を作成
- `MIGRATION_6_7`
  - `amc_attachment_queue` に `uploadSessionId`
  - `attemptNumber`
  - `lastErrorCode`
  - `expiresAtMillis`

既存の `events / records / photos / memos / observation_events / Toggl` 系は維持。

Room schema JSON:

- `app/schemas/com.example.aleartmycontroller.data.local.AppDatabase/7.json`

## テスト結果

実行済み:

- `./gradlew test`
- `./gradlew compileDebugAndroidTestKotlin`

結果:

- いずれも成功

追加したテスト:

- [app/src/test/java/com/example/aleartmycontroller/data/amc/AmcContentPolicyTest.kt](/Users/yuuto/learn_lab/AleartMyController/app/src/test/java/com/example/aleartmycontroller/data/amc/AmcContentPolicyTest.kt)
- [app/src/test/java/com/example/aleartmycontroller/data/amc/AmcAttachmentQueueLogFormatterTest.kt](/Users/yuuto/learn_lab/AleartMyController/app/src/test/java/com/example/aleartmycontroller/data/amc/AmcAttachmentQueueLogFormatterTest.kt)
- [app/src/androidTest/java/com/example/aleartmycontroller/migration/Migration5To6Test.kt](/Users/yuuto/learn_lab/AleartMyController/app/src/androidTest/java/com/example/aleartmycontroller/migration/Migration5To6Test.kt)
- [app/src/androidTest/java/com/example/aleartmycontroller/migration/Migration6To7Test.kt](/Users/yuuto/learn_lab/AleartMyController/app/src/androidTest/java/com/example/aleartmycontroller/migration/Migration6To7Test.kt)

補足:

- `./gradlew test` と `./gradlew compileDebugAndroidTestKotlin` は成功
- 2 コマンドを並列実行すると KSP 出力競合で落ちることがあるので、検証は順次実行に寄せた方が安全

## 未着手 / 次にやること（2026-05-28 時点）

### 優先度高

- Supabase クライアント導入
  - Auth / record CRUD / share access / access metadata を実装
- R2 upload 実装
  - presigned PUT 発行、アップロード完了確認、再送
  - `AmcAttachmentQueueLogger.logApiInitResult` / `logApiCompleteResult` を実際の呼び出し点に差し込む
- AMC server sync の実装
  - local draft から server-first への同期
- 共有・認可 UI
  - `private / specific users / friends / public / limited public` の表示と編集

### 優先度中

- 既存 Room データの段階移行
  - `local_migrated` / `native_server` の区別
- Google Calendar の全文ミラー更新フロー整備
  - 長文退避を含む再試行ジョブ
- record detail / history への AMC 状態表示

### 優先度低

- サムネイル
- 手動マージ UI
- 削除復元 UI
- 共有アクセス履歴の詳細 UI

## 実装時の注意

- 既存の Google Calendar / Toggl / Room 連携は壊さない方針で追加した
- AMC 実装は local draft から始める設計で、backend 側が入るまでは完全同期にはならない
- `AmcDraftRepository` は現在「ローカル補助層」であり、Supabase へ直接書く処理は未接続
- `AmcApi` は DTO と interface のみで、実装 backend が来たら DI に差し込む必要がある
- 添付 queue の構造化ログは Logcat 中心で、Room に履歴テーブルはまだ作っていない
- 既存コードベースには他の未整理差分がある可能性があるため、変更前に `git status` で確認すること

## 参照しやすい主要ファイル

- [app/src/main/java/com/example/aleartmycontroller/data/local/AppDatabase.kt](/Users/yuuto/learn_lab/AleartMyController/app/src/main/java/com/example/aleartmycontroller/data/local/AppDatabase.kt)
- [app/src/main/java/com/example/aleartmycontroller/data/repository/AmcDraftRepository.kt](/Users/yuuto/learn_lab/AleartMyController/app/src/main/java/com/example/aleartmycontroller/data/repository/AmcDraftRepository.kt)
- [app/src/main/java/com/example/aleartmycontroller/data/amc/AmcAttachmentQueueLogger.kt](/Users/yuuto/learn_lab/AleartMyController/app/src/main/java/com/example/aleartmycontroller/data/amc/AmcAttachmentQueueLogger.kt)
- [app/src/main/java/com/example/aleartmycontroller/ui/viewmodel/SettingsViewModel.kt](/Users/yuuto/learn_lab/AleartMyController/app/src/main/java/com/example/aleartmycontroller/ui/viewmodel/SettingsViewModel.kt)
- [app/src/main/java/com/example/aleartmycontroller/ui/screen/SettingsScreen.kt](/Users/yuuto/learn_lab/AleartMyController/app/src/main/java/com/example/aleartmycontroller/ui/screen/SettingsScreen.kt)

---

# Supabase 認証・ストレージ移行 追記

更新日: 2026-06-02  
ブランチ: `feature/Yukkurisiteikitai/token_safe_save`

## 概要

Supabase Auth（Google OAuth）と Supabase Storage（`amc-media` バケット）を Android クライアントに接続し、写真証拠を Supabase Storage へ自動アップロードする仕組みを構築した。

R2 presigned PUT 方式は採用せず、`supabase-kt` ライブラリの `storage.from().upload()` で直接アップロードする構成を選択した。

## 追加・変更したファイル一覧

### Android

| ファイル | 変更種別 | 内容 |
|---------|---------|------|
| `di/SupabaseModule.kt` | 新規 | Supabase クライアント DI。Auth / Postgrest / Storage をインストール |
| `data/repository/AuthRepository.kt` | 更新 | Google IdToken で Supabase にサインイン。`isSupabaseAuthenticated()` / `currentSupabaseUserId()` を追加 |
| `worker/AmcAttachmentUploadWorker.kt` | 新規 | WorkManager Worker。キュー内の PENDING 添付を Supabase Storage にアップロードし状態を更新 |
| `ui/util/CameraUtils.kt` | 更新 | `compressToJpeg()` を追加。`content://` / `file://` URI を 2048px 上限・JPEG 85% に圧縮して `filesDir/photos/` に保存 |
| `ui/viewmodel/AddRecordViewModel.kt` | 更新 | `addPhoto()` に `compressToJpeg()` → `queueAttachment()` → WorkManager 起動の流れを追加 |
| `ui/viewmodel/SetupViewModel.kt` | 更新 | Google サインイン完了後に `authRepository.signInWithSupabase()` を呼び出す |
| `ui/viewmodel/SettingsViewModel.kt` | 更新 | 設定画面から Supabase サインインを再試行できる導線を追加 |
| `data/local/AppDatabase.kt` | 更新 | Room version `8`。`amc_attachment_queue` に `storagePath` カラムを追加する `MIGRATION_7_8` |
| `app/build.gradle.kts` | 更新 | `supabase-kt` ライブラリ群を追加（`bom:3.1.4`） |

### Supabase（サーバー側）

| ファイル | 内容 |
|---------|------|
| `supabase/migrations/0001_initial_schema.sql` | `profiles` / `amc_records` / `amc_record_revisions` / `amc_media_objects` / `share_links` / `share_grants` テーブルと RLS |
| `supabase/migrations/0002_storage_rls.sql` | `amc-media` バケット作成（private, 10 MB, JPEG/M4A のみ）と storage.objects RLS |

## アーキテクチャ：写真アップロードの流れ

```
ユーザーが写真を撮影
  ↓
CameraUtils.compressToJpeg()  →  filesDir/photos/img_XXX.jpg
  ↓
AmcDraftRepository.queueAttachment()  →  amc_attachment_queue に PENDING で登録
  ↓
WorkManager.enqueueUniqueWork("amc_attachment_upload", KEEP, ...)
  ↓
AmcAttachmentUploadWorker.doWork()
  ├─ isSupabaseAuthenticated() が false → Result.retry()
  ├─ getPendingOnce() で PENDING / NEEDS_RETRY を取得
  ├─ resolveLocalFile(localUri)  →  file:// URI から File を解決
  └─ supabase.storage.from("amc-media").upload(storagePath, bytes)
       storagePath = {userId}/{draftRecordId}/{attachmentId}.jpg
       成功 → markAttachmentReady(storagePath)
       失敗 → markAttachmentNeedsRetry() or markAttachmentFailed()
```

## Supabase Storage のパス設計

```
amc-media/{owner_user_id}/{draft_record_id}/{attachment_id}.jpg
amc-media/{owner_user_id}/{draft_record_id}/{attachment_id}.m4a
```

- `storage_upload_own` ポリシー: `foldername(name)[1] == auth.uid()` のみ INSERT 可
- `storage_select_own` ポリシー: 自分のファイルのみ SELECT 可（現在は自分専用）

## Room マイグレーション v7 → v8

```sql
ALTER TABLE amc_attachment_queue ADD COLUMN storagePath TEXT;
```

テスト: `app/src/androidTest/java/com/example/aleartmycontroller/migration/Migration7To8Test.kt`

## `autoLoadFromStorage` に関するバグと修正（2026-06-02）

**現象**: 写真追加後、Logcat に `AMC.UploadWorker` のログが一切出ず Supabase へのアップロードが行われない。

**原因**: 前回のセッション（commit `4f0d5f9`）で `SupabaseModule` に `autoLoadFromStorage = false` と `GlobalScope.launch { client.auth.loadFromStorage() }` を設定した。Worker が DI 初期化直後に起動するとまだ `loadFromStorage()` が完了していないため、`isSupabaseAuthenticated()` が false を返し `Result.retry()` になる。Worker のログが出ないのはこのため。

**修正内容**: `autoLoadFromStorage = false` と `GlobalScope.launch` を削除し、`install(Auth)` をデフォルト設定（`autoLoadFromStorage = true`）に戻した。

```kotlin
// 修正後（SupabaseModule.kt）
install(Auth)   // autoLoadFromStorage = true がデフォルト。IOスレッドで非同期ロードされる
```

`autoLoadFromStorage = true` はメインスレッドをブロックしない。supabase-kt が内部の CoroutineScope で `loadFromStorage()` を処理する。

**`localUri` の URI 形式について**（問題なし）:
`CameraUtils.compressToJpeg()` は `filesDir/photos/img_XXX.jpg` に保存し、`Uri.fromFile(file).toString()` で `file:///data/user/0/.../files/photos/img_XXX.jpg` を返す。Worker の `resolveLocalFile()` は `uri.path` でこの絶対パスを取得するため、正しく解決される。

## 現在の未解決・次のタスク（2026-06-02 時点）

### 動作確認待ち

- `autoLoadFromStorage` 修正後に写真追加 → `AMC.UploadWorker: Uploaded: ...` ログが出ることを確認する

### 優先度高（→ 下記セクションで実装済み）

- ~~Supabase `amc_records` への同期~~  → **実装済み（2026-06-02）**
- ~~アップロード後のローカルファイル削除~~  → **実装済み（安全な削除順序で対応）**

### 優先度中

- `amc_attachment_queue` の `storagePath` を使って、既にアップロード済みの画像を表示する
  - ダウンロードボタンの UI もこのタイミングで実装（`AmcStorageRepository.downloadToLocal()` は既に実装済み）
- Storage RLS に「共有相手は SELECT 可」ポリシーを追加する（`share_grants` テーブルを参照）
- アップロード状態を UI に表示（PENDING / UPLOADING / READY / FAILED バッジ）
- Supabase サインインのリトライ UX
  - セッション期限切れ時（`isSupabaseAuthenticated() = false` が長期間続く場合）の通知や再サインイン導線

### 優先度低（前セクションから引き継ぎ）

- 共有・認可 UI
- Google Calendar ミラー更新フロー
- サムネイル
- 手動マージ UI

## 主要ファイル（Supabase 移行分）

- [app/src/main/java/com/example/aleartmycontroller/di/SupabaseModule.kt](/Users/yuuto/learn_lab/AleartMyController/app/src/main/java/com/example/aleartmycontroller/di/SupabaseModule.kt)
- [app/src/main/java/com/example/aleartmycontroller/data/repository/AuthRepository.kt](/Users/yuuto/learn_lab/AleartMyController/app/src/main/java/com/example/aleartmycontroller/data/repository/AuthRepository.kt)
- [app/src/main/java/com/example/aleartmycontroller/worker/AmcAttachmentUploadWorker.kt](/Users/yuuto/learn_lab/AleartMyController/app/src/main/java/com/example/aleartmycontroller/worker/AmcAttachmentUploadWorker.kt)
- [app/src/main/java/com/example/aleartmycontroller/ui/util/CameraUtils.kt](/Users/yuuto/learn_lab/AleartMyController/app/src/main/java/com/example/aleartmycontroller/ui/util/CameraUtils.kt)
- [app/src/main/java/com/example/aleartmycontroller/ui/viewmodel/AddRecordViewModel.kt](/Users/yuuto/learn_lab/AleartMyController/app/src/main/java/com/example/aleartmycontroller/ui/viewmodel/AddRecordViewModel.kt)
- [supabase/migrations/0001_initial_schema.sql](/Users/yuuto/learn_lab/AleartMyController/supabase/migrations/0001_initial_schema.sql)
- [supabase/migrations/0002_storage_rls.sql](/Users/yuuto/learn_lab/AleartMyController/supabase/migrations/0002_storage_rls.sql)

---

# Supabase DB テキスト同期・ローカル専用モード・ダウンロード機能 追記

更新日: 2026-06-02  
ブランチ: `feature/Yukkurisiteikitai/token_safe_save`

## 概要

以下の3つの機能を実装した。

1. **テキストデータの Supabase DB 同期** — `addMemo()` が AMC ドラフトを作成し、`AmcRecordSyncWorker` が `amc_records` / `amc_record_revisions` / `amc_attachments` に Postgrest 直接書き込みを行う
2. **グローバル「ローカル専用モード」設定** — Settings 画面のトグルでクラウド同期全体をオフにできる
3. **クラウドファイルのダウンロード機能** — `AmcStorageRepository.downloadToLocal()` で Supabase Storage → デバイス Downloads フォルダへ保存

## 設計上の重要判断：ローカルファイル削除のタイミング

`amc_attachments`（Supabase DB）にメタデータが存在しない状態でローカルファイルを消すと、Storage 上のファイルが孤児になる。また `amc_attachments.record_id` は `amc_records.id`（UUID）の外部キーであり、テキスト同期で `remoteRecordId` が確定した後でないと INSERT できない。

このため削除タイミングを以下の順序に固定した:

```
[AmcAttachmentUploadWorker]
  Storage にアップロード → storagePath を Room に保存（READY）
  ※ ローカルファイルはここでは削除しない

[AmcRecordSyncWorker]
  1. amc_records に upsert → remoteRecordId (UUID) を確定
  2. amc_record_revisions に upsert（idempotency_key で冪等）
  3. READY な添付を amc_attachments に INSERT（record_id = remoteRecordId）
  4. INSERT 成功後にローカルファイルを削除（cloudSyncEnabled = true の場合のみ）
```

## 追加・変更したファイル一覧

| ファイル | 変更種別 | 内容 |
|---------|---------|------|
| `data/preferences/AppPreferences.kt` | 更新 | `cloudSyncEnabled: Flow<Boolean>` / `setCloudSyncEnabled()` を追加（DataStore） |
| `ui/viewmodel/SettingsViewModel.kt` | 更新 | `cloudSyncEnabled` StateFlow / `setCloudSyncEnabled()` を追加 |
| `ui/screen/SettingsScreen.kt` | 更新 | AMC セクションに「クラウドに同期する」Switch を追加 |
| `ui/viewmodel/AddRecordViewModel.kt` | 更新 | `addMemo()` 内で `getOrCreateDraftForEvent()` + `appendRevision()` を呼ぶよう修正。テキストがクラウドへの同期パスに乗るようになった |
| `data/local/dao/AmcDraftRecordDao.kt` | 更新 | `getPendingSyncOnce()` を追加（syncState = QUEUED の一括取得） |
| `data/local/dao/AmcAttachmentQueueDao.kt` | 更新 | `getReadyByDraftId(draftRecordId)` を追加（READY かつ storagePath 確定済み） |
| `data/repository/AmcDraftRepository.kt` | 更新 | `enqueueSyncWorker()` / `markRecordSynced()` を追加。`appendRevision()` 末尾で `enqueueSyncWorker()` を呼ぶ |
| `worker/AmcRecordSyncWorker.kt` | 新規 | テキスト・添付メタデータを Supabase DB に同期する Worker |
| `worker/AmcAttachmentUploadWorker.kt` | 更新 | `cloudSyncEnabled` チェックを追加（OFF なら即 `Result.success()` でスキップ）。ファイル削除は行わない |
| `data/repository/AmcStorageRepository.kt` | 新規 | `downloadToLocal(attachmentId, storagePath, mimeType)` — Supabase Storage → デバイス Downloads（MediaStore） |

## AmcRecordSyncWorker の動作フロー

```
doWork()
  ├─ cloudSyncEnabled = false → Result.success()（スキップ）
  ├─ isSupabaseAuthenticated() = false → Result.retry()
  ├─ draftDao.getPendingSyncOnce() で QUEUED ドラフト一覧取得
  └─ 各ドラフトに対して:
       syncRecord(draft, userId)
         ├─ remoteRecordId == null → POST amc_records → UUID 取得
         └─ remoteRecordId あり → PATCH amc_records（current_body / visibility 更新）
         └─ revisionDao.findLatestForDraft() → POST amc_record_revisions（idempotency_key で冪等）
              └─ 新規 revision UUID 取得 → PATCH amc_records.current_revision
       syncReadyAttachments(draftRecordId, remoteRecordId, userId)
         └─ READY な添付ごとに POST amc_attachments → ローカルファイル削除
       amcDraftRepository.markRecordSynced() → Room syncState = SYNCED
```

## AmcStorageRepository のダウンロード設計

```kotlin
suspend fun downloadToLocal(attachmentId: Long, storagePath: String, mimeType: String): Uri
```

- `supabase.storage.from("amc-media").downloadAuthenticated(storagePath)` で ByteArray 取得
- MediaStore API（`MediaStore.Downloads`、IS_PENDING パターン）でデバイス Downloads に保存
- 戻り値は保存先の MediaStore URI

**注意**: UI 上のダウンロードボタンは添付表示 UI（優先度中）と合わせて実装すること。リポジトリ層は既に利用可能。

## テスト結果

- `./gradlew test` → 成功（67 tasks）
- `./gradlew compileDebugKotlin` → 成功（エラー 0、既存の deprecated 警告のみ）

## 現在の未解決・次のタスク（2026-06-02 時点）

### 動作確認待ち

- memo 入力後 Logcat に `AMC.RecordSyncWorker: Synced record: local=X remote=<UUID>` が出ることを確認する
- Supabase Dashboard → `amc_records` テーブルに行が追加されることを確認する
- 写真追加 → Storage upload 成功 → `amc_attachments` 行追加 → ローカルファイル削除、の一連流れを確認する
- Settings「クラウドに同期する」OFF 時に Worker がスキップされることを確認する

### 優先度中

- 添付表示 UI の実装（`amc_attachment_queue.storagePath` を使って READY 画像を表示）
  - この画面に合わせてダウンロードボタンを設置（`AmcStorageRepository.downloadToLocal()` を呼ぶ）
- Storage RLS に「共有相手は SELECT 可」ポリシーを追加する（`share_grants` テーブルを参照）
- アップロード・同期状態を UI に表示（PENDING / UPLOADING / READY / FAILED バッジ）
- Supabase サインインのリトライ UX（セッション期限切れ時の通知や再サインイン導線）

### 優先度低（前セクションから引き継ぎ）

- 共有・認可 UI
- Google Calendar ミラー更新フロー
- サムネイル
- 手動マージ UI

## 主要ファイル（DB 同期・ローカル専用モード分）

- [app/src/main/java/com/example/aleartmycontroller/worker/AmcRecordSyncWorker.kt](/Users/yuuto/learn_lab/AleartMyController/app/src/main/java/com/example/aleartmycontroller/worker/AmcRecordSyncWorker.kt)
- [app/src/main/java/com/example/aleartmycontroller/data/repository/AmcDraftRepository.kt](/Users/yuuto/learn_lab/AleartMyController/app/src/main/java/com/example/aleartmycontroller/data/repository/AmcDraftRepository.kt)
- [app/src/main/java/com/example/aleartmycontroller/data/repository/AmcStorageRepository.kt](/Users/yuuto/learn_lab/AleartMyController/app/src/main/java/com/example/aleartmycontroller/data/repository/AmcStorageRepository.kt)
- [app/src/main/java/com/example/aleartmycontroller/data/preferences/AppPreferences.kt](/Users/yuuto/learn_lab/AleartMyController/app/src/main/java/com/example/aleartmycontroller/data/preferences/AppPreferences.kt)
- [app/src/main/java/com/example/aleartmycontroller/ui/viewmodel/AddRecordViewModel.kt](/Users/yuuto/learn_lab/AleartMyController/app/src/main/java/com/example/aleartmycontroller/ui/viewmodel/AddRecordViewModel.kt)

---

# リリースビルドクラッシュ調査・修正 追記

更新日: 2026-06-02

## 概要

GitHub でビルドした APK をインストールすると起動直後にクラッシュする問題を調査・修正した。
原因は1つではなく、**2段階のクラッシュ**が存在した。

---

## 第1のクラッシュ：Supabase 認証情報の欠落

### 原因

`local.properties` は `.gitignore` 登録済みのため GitHub 側のビルド環境に存在しない。
`app/build.gradle.kts` は `local.properties` が無くても例外を出さず、デフォルト値として**空文字**を `BuildConfig` に埋め込む。

起動時に Hilt が `SupabaseModule` を初期化し、`createSupabaseClient("", "")` が呼ばれる。
supabase-kt 3.1.4 は url/key が空の場合 `IllegalArgumentException` を投げるため、起動直後にクラッシュする。

`isMinifyEnabled = false` のため ProGuard/R8 によるクラス削除は原因ではない。

### 修正内容（`app/build.gradle.kts`）

1. **env フォールバック** — `resolveProp()` を追加し `local.properties → 環境変数` の順で解決。CI では GitHub Secrets を環境変数として渡す。
2. **fail-fast** — release ビルドで URL/Key が空なら `GradleException` を投げてビルドを停止。気づかずに空の APK が配布されるのを構造的に防ぐ。
3. **`logback-android` を全 variant に** — `debugImplementation` → `implementation`。Supabase/Ktor が使う SLF4J バックエンドを release にも含める。
4. **release signingConfig** — `RELEASE_KEYSTORE_PATH` が設定されている場合のみ release 署名を有効化。未設定時は debug 署名で代用（ローカル動作確認用）。

### CI の設定が必要なもの（GitHub Secrets）

| Secret 名 | 必須 | 用途 |
|-----------|------|------|
| `SUPABASE_URL` | ○ | Supabase プロジェクト URL |
| `SUPABASE_ANON_KEY` | ○ | Supabase anon key |
| `SUPABASE_GOOGLE_WEB_CLIENT_ID` | Google ログインを使う場合 | Google OAuth クライアント ID |
| `RELEASE_KEYSTORE_BASE64` | 署名済み配布時 | keystore を base64 エンコードしたもの |
| `RELEASE_KEYSTORE_PASSWORD` | 同上 | |
| `RELEASE_KEY_ALIAS` | 同上 | |
| `RELEASE_KEY_PASSWORD` | 同上 | |

### 追加した CI ワークフロー（`.github/workflows/android-build.yml`）

- push / PR / 手動実行でビルドが走る
- debug APK を artifact として出力（debug 署名付き、そのまま `adb install` できる）
- keystore Secrets が設定されていれば署名済み release APK も出力

---

## 第2のクラッシュ：EncryptedSharedPreferences の復号失敗

### 原因

クラッシュログ:
```
javax.crypto.AEADBadTagException
  at androidx.security.crypto.EncryptedSharedPreferences.create
  at TogglTokenStore.sharedPreferences_delegate$lambda$0 (TogglTokenStore.kt:19)
```

`TogglTokenStore` が `EncryptedSharedPreferences` で Toggl API トークンを暗号化保存している。
Android Keystore のキーはアプリの署名に紐づくため、**署名の異なる APK に入れ替えると既存の暗号化ファイルが復号できなくなる**。
（例: ローカルの debug 署名 APK → GitHub ビルドの debug 署名 APK への差し替え）

### 修正内容（`TogglTokenStore.kt`）

`openOrRecreate()` を追加。復号時に例外が発生した場合は `context.deleteSharedPreferences()` で暗号化ファイルを削除し、空の状態で作り直す。Toggl トークンは失われるが、クラッシュせず再入力できる状態になる。

```kotlin
private fun openOrRecreate(): SharedPreferences {
    return try {
        EncryptedSharedPreferences.create(...)
    } catch (_: Exception) {
        // AEADBadTagException 等。APK の再インストールや署名変更で発生する。
        context.deleteSharedPreferences(PREFS_NAME)
        EncryptedSharedPreferences.create(...)
    }
}
```

### 端末に既に古い APK が入っている場合の対処

設定 → アプリ → AleartMyController → ストレージ → **「データを消去」** してから起動する。
コード修正後の APK であれば自動で回復するため手動消去は不要。

---

## 変更ファイル一覧（本セクション）

| ファイル | 変更種別 | 内容 |
|---------|---------|------|
| `app/build.gradle.kts` | 更新 | env フォールバック / fail-fast / logback 全 variant 化 / release 署名設定 |
| `data/preferences/TogglTokenStore.kt` | 更新 | `AEADBadTagException` 発生時に prefs を削除して再作成 |
| `.github/workflows/android-build.yml` | 新規 | debug / release APK のビルドと artifact 出力 |

## 主要ファイル（本セクション）

- [app/build.gradle.kts](/Users/yuuto/learn_lab/AleartMyController/app/build.gradle.kts)
- [app/src/main/java/com/example/aleartmycontroller/data/preferences/TogglTokenStore.kt](/Users/yuuto/learn_lab/AleartMyController/app/src/main/java/com/example/aleartmycontroller/data/preferences/TogglTokenStore.kt)
- [.github/workflows/android-build.yml](/Users/yuuto/learn_lab/AleartMyController/.github/workflows/android-build.yml)
