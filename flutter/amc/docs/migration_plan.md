# AleartMyController — Flutter 移管計画

Android (Kotlin/Jetpack Compose) 実装を Flutter プロジェクト `flutter/amc` へ移管するための設計整理。
iOS / Web 展開も視野に入れた構成にする。

> **更新日: 2026-06-02** — Android 側で Supabase（Auth / Storage / DB 同期 / ローカル専用モード / ダウンロード）が
> コア機能になったため、本計画を「クラウド同期を含む」前提に全面改訂した。
> 参照: `docs/amc_handoff.md`（2026-06-02 版）。
>
> 旧版との主な差分:
> - **Supabase クラウド同期を「除外」→「中核として含む」に変更。** Auth・Storage アップロード・DB テキスト同期・
>   ローカル専用モード・ダウンロードを移管対象に追加。
> - drift に AMC ローカルキュー系テーブル（draft / revision / attachment_queue）を再追加。
> - 2 ワーカー構成（アップロード → DB 同期）とローカルファイル削除順序を移植対象に明記。
> - Toggl は引き続き除外。

## 0. スコープ

| 機能 | 移管 | 備考 |
|---|---|---|
| ローカル記録（写真・テキスト・音声メモ）と Room 相当の DB | ✅ 含む | 中核機能 |
| イベント一覧 / 詳細 / 履歴 / 分析 / 設定 / 記録ダッシュボード | ✅ 含む | 全画面 |
| リマインダー通知（進行中イベント判定） | ✅ 含む | モバイルのみ |
| Google カレンダー連携（取得 + 作成 + メモ追記） | ✅ 含む | OAuth2 書き込み含む |
| **Supabase Auth（Google OAuth → Supabase サインイン）** | ✅ 含む | `supabase_flutter` + `google_sign_in` |
| **Supabase Storage アップロード（写真証拠）** | ✅ 含む | `amc-media` private bucket、直接 `upload()` |
| **Supabase DB テキスト同期（records / revisions / attachments）** | ✅ 含む | Postgrest 直接書き込み、idempotency_key 冪等 |
| **ローカル専用モード（クラウド同期 ON/OFF トグル）** | ✅ 含む | 設定の `cloud_sync_enabled` |
| **クラウドファイルのダウンロード（Storage → 端末）** | ✅ 含む | リポジトリ層先行、UI は添付表示と同時 |
| Toggl Track 連携 | ❌ 除外 | 後フェーズ。分析画面の Toggl 集計も除外 |
| 共有・認可 UI（private / specific / friends / public / limited public） | ⏸ 後フェーズ | Android 側も優先度低のため計画にのみ記載 |
| R2 presigned PUT 方式 | ❌ 不採用 | Android で `supabase-kt` の直接 upload を採用したため不要 |

除外に伴い、DB から `toggl_*` テーブル群は移植しない。
残すローカル UI 用テーブルは `events / observation_events / records / photos / memos` の 5 つ。
これに加えて、クラウド同期パイプライン用に `amc_draft_records / amc_record_revisions / amc_attachment_queue` を持つ
（Android と同じく「UI 用ローカルモデル」と「クラウド同期キュー」を並走させる）。

---

## 1. 技術スタック対応表

| Android (現行) | Flutter (移管後) | 理由 |
|---|---|---|
| Kotlin | Dart | — |
| Jetpack Compose | Flutter Widgets (Material 3) | `useMaterial3` で M3 対応 |
| Navigation Compose | **go_router** | 宣言的ルーティング、ディープリンク（通知タップ）対応 |
| ViewModel + StateFlow | **Riverpod** (`Notifier` / `AsyncNotifier`) | 後述 |
| Hilt (DI) | Riverpod の provider グラフ | DI と状態を一元化 |
| Room (Entity/DAO/Migration) | **drift** | 型安全な SQL、マイグレーション、Stream（Flow 相当）。iOS/Web 対応 |
| Retrofit + OkHttp + Gson | **dio** + `googleapis`（Calendar） | Calendar は公式 `googleapis` パッケージを使う |
| DataStore | **shared_preferences** | 設定の Key-Value 永続化 |
| WorkManager + HiltWorker | **workmanager** + **flutter_local_notifications** | リマインダー + アップロード/同期ワーカー。Web 非対応 |
| Google Sign-In + GoogleAuthUtil | **google_sign_in** + **extension_google_sign_in_as_googleapis_auth** | OAuth2 トークン取得 → googleapis に渡す |
| **supabase-kt（Auth / Postgrest / Storage, bom:3.1.4）** | **supabase_flutter (^2.8.0)** | 公式 Flutter SDK。Auth / Postgrest / Storage を一括提供 |
| **GoogleIdToken → `auth.signInWithIdToken`** | **`supabase.auth.signInWithIdToken(OAuthProvider.google, idToken, accessToken)`** | google_sign_in の idToken を Supabase に渡す |
| **`storage.from("amc-media").upload()`** | **`Supabase.instance.client.storage.from('amc-media').uploadBinary()`** | 直接バイナリアップロード |
| **Postgrest upsert / insert** | **`client.from('amc_records').upsert/insert()`** | DB 同期。`idempotency_key` で冪等 |
| **MediaStore (Downloads 保存)** | **`gal` / `path_provider` + 共有保存プラグイン** | DL ファイルの端末保存。プラットフォーム分岐 |
| Coroutines / Flow | `Future` / `Stream` / `async*` | drift の `watch*` が Stream を返す |
| FileProvider + camera intent | **image_picker**（撮影/選択） | パス取得まで隠蔽 |
| Bitmap 圧縮（2048px / JPEG 85%） | **`flutter_image_compress`** | `CameraUtils.compressToJpeg()` 相当 |
| Speech-to-Text (Android) | **speech_to_text** | 音声メモ。Web は別途検討 |
| NotificationCompat | **flutter_local_notifications** | チャンネル作成・通知発行 |
| `getExternalFilesDir` / `filesDir/photos` | **path_provider** (`getApplicationDocumentsDirectory`) | 写真の保存先（圧縮後の永続パス） |

### 状態管理に Riverpod を推す理由（iOS/Web 前提）
- プラットフォーム非依存。`ViewModel`(Android lifecycle 依存) を持ち込まず、純粋 Dart で書ける。
- Hilt の「Singleton Repository を注入」と「ViewModel をスコープ管理」の両方を `Provider` / `NotifierProvider` に対応付けられる。
- `StateFlow` → `Notifier`、`Flow` の購読 → `StreamProvider` / `ref.watch` が 1:1 に近い。
- Bloc でも可能だが、本アプリはタイマー・通知・カレンダー・クラウド同期など副作用が多く、Notifier の素直な命令的記述の方が移植コストが低い。

### Supabase 初期化の方針
- `main()` で `await Supabase.initialize(url, anonKey)` を実行してから `runApp`。
- `supabase_flutter` はセッションを自動で永続化・復元する（Android の `autoLoadFromStorage = true` 相当）。
  Android で起きた「Worker が `loadFromStorage()` 完了前に走り `retry` ループする」事故は、
  Flutter では初期化を `await` で待ってから `runApp` するため構造的に回避できる。
- `supabaseClientProvider` を Riverpod で公開し、各 Repository / Worker から参照する。

---

## 2. ディレクトリ構成案（`flutter/amc/lib/`）

Android のパッケージ構成（`data / di / ui / worker`）を踏襲する。

```text
lib/
  main.dart                 # Supabase.initialize + runApp + ProviderScope + 通知/DB 初期化
  app.dart                  # MaterialApp.router, テーマ, go_router
  core/
    theme/                  # Color / Theme / Type (ui/theme 相当)
    time_formatters.dart    # ui/util/TimeFormatters 相当
    content_policy.dart     # 本文 NFC 正規化 + Calendar ミラー本文生成（AmcContentPolicy 相当）
    amc_idempotency.dart    # idempotency_key 生成（AmcIdempotency 相当）
  data/
    local/
      database.dart         # drift AppDatabase（UI 用 5 表 + AMC キュー 3 表）
      tables.dart           # Events / ObservationEvents / Records / Photos / Memos
      amc_tables.dart       # AmcDraftRecords / AmcRecordRevisions / AmcAttachmentQueue
      daos/                 # event_dao.dart / record_dao.dart / amc_draft_dao.dart ...
    remote/
      google_calendar_api.dart   # googleapis ラッパ
      supabase/
        supabase_client.dart     # 初期化ヘルパ（DI で公開）
        amc_dto.dart             # records / revisions / attachments の JSON マッピング
    preferences/
      app_preferences.dart       # shared_preferences ラッパ（cloud_sync_enabled 含む）
    repository/
      event_repository.dart
      observation_event_repository.dart
      record_repository.dart
      auth_repository.dart        # google_sign_in → supabase.auth.signInWithIdToken
      amc_draft_repository.dart   # ローカル下書き/リビジョン/添付キュー + 同期トリガ
      amc_storage_repository.dart # Storage upload / downloadToLocal
  providers/                # Riverpod provider 定義（DI = di/ 相当）
    database_providers.dart
    repository_providers.dart
    supabase_providers.dart     # supabaseClientProvider / authStateProvider
  features/                 # 画面 + 状態（ui/screen + ui/viewmodel 相当）
    setup/        { setup_screen.dart, setup_notifier.dart }
    event_list/   { event_list_screen.dart, event_list_notifier.dart }
    event_detail/ { ... }
    add_record/   { ... }
    dashboard/    { record_dashboard_screen.dart, record_dashboard_notifier.dart }
    record_detail/{ ... }
    history/      { ... }
    analytics/    { ... }
    settings/     { settings_screen.dart, settings_notifier.dart }  # クラウド同期トグル含む
  widgets/                  # ui/components 相当
    empty_state_placeholder.dart
    new_draft_event_dialog.dart
    timeline_record_item.dart
    sync_status_badge.dart      # PENDING/UPLOADING/READY/FAILED バッジ（優先度中）
  services/
    notification_service.dart   # flutter_local_notifications
    reminder_worker.dart        # workmanager: リマインダー
    amc_attachment_upload_worker.dart  # workmanager: Storage アップロード
    amc_record_sync_worker.dart        # workmanager: DB 同期
    camera_service.dart         # image_picker + flutter_image_compress
    speech_service.dart         # speech_to_text
  models/                   # ui/model 相当 (DomainRecord, EventWithCounts)
  routing/
    app_router.dart         # go_router (Screen.kt 相当)
```

---

## 3. データ層（drift）

### 3.1 UI 用テーブル（Room Entity → drift Table）

Room の FK / index / ソフト参照設計をそのまま再現する（README の「カレンダーキャッシュとユーザー記録の分離」を維持）。

```dart
// events — Google Calendar キャッシュ（自由に削除可）
class Events extends Table {
  IntColumn get eventId => integer().autoIncrement()();
  TextColumn get googleEventId => text()();          // UNIQUE
  TextColumn get title => text()();
  IntColumn get startTime => integer()();            // epoch millis
  IntColumn get endTime => integer()();
  @override List<Set<Column>> get uniqueKeys => [{googleEventId}];
}

// observation_events — 永続スナップショット。events への FK は張らない（ソフト参照）
class ObservationEvents extends Table {
  IntColumn get obsEventId => integer().autoIncrement()();
  TextColumn get googleEventId => text().nullable()(); // UNIQUE, soft ref
  TextColumn get title => text()();
  IntColumn get startTime => integer()();
  IntColumn get endTime => integer()();
  @override List<Set<Column>> get uniqueKeys => [{googleEventId}];
}

// records — observation_events に CASCADE
class Records extends Table {
  IntColumn get recordId => integer().autoIncrement()();
  IntColumn get obsEventId =>
      integer().references(ObservationEvents, #obsEventId, onDelete: KeyAction.cascade)();
  IntColumn get recordTime => integer()();
  TextColumn get recordType => textEnum<RecordType>()(); // PHOTO / MEMO
}

// photos / memos — records に CASCADE
class Photos extends Table {
  IntColumn get photoId => integer().autoIncrement()();
  IntColumn get recordId =>
      integer().references(Records, #recordId, onDelete: KeyAction.cascade)();
  TextColumn get filePath => text()();
}
class Memos extends Table {
  IntColumn get memoId => integer().autoIncrement()();
  IntColumn get recordId =>
      integer().references(Records, #recordId, onDelete: KeyAction.cascade)();
  TextColumn get memoText => text()();
  BoolColumn get isVoiceMemo => boolean().withDefault(const Constant(false))();
}

enum RecordType { photo, memo }
```

> 注意: drift は外部キー制約をデフォルトでは強制しないため、`beforeOpen` で
> `await customStatement('PRAGMA foreign_keys = ON');` を実行して CASCADE を効かせる。
> 定数 `localDraftGoogleIdPrefix = 'local-draft:'` と `isLocalDraft()` 拡張も移植する。

### 3.2 AMC クラウド同期キュー用テーブル

Android の `amc_draft_records / amc_record_revisions / amc_attachment_queue` を drift に再現する。
これらは UI 用テーブルとは別系統で、「サーバー同期の状態機械」を持つ。

```dart
// amc_draft_records — ローカル下書き + サーバー同期状態 + remote UUID
class AmcDraftRecords extends Table {
  IntColumn get draftRecordId => integer().autoIncrement()();
  IntColumn get obsEventId => integer().nullable()();    // どのイベントの記録か（ソフト参照）
  TextColumn get currentBody => text().withDefault(const Constant(''))();
  TextColumn get visibility => text().withDefault(const Constant('private'))();
  TextColumn get syncState => textEnum<AmcSyncState>()(); // DRAFT / QUEUED / SYNCED / FAILED
  TextColumn get remoteRecordId => text().nullable()();   // Supabase amc_records.id (UUID)
  TextColumn get currentRevisionId => text().nullable()();
  IntColumn get updatedAtMillis => integer()();
  BoolColumn get deleted => boolean().withDefault(const Constant(false))();
}

// amc_record_revisions — 全文履歴 append-only。idempotency_key で冪等
class AmcRecordRevisions extends Table {
  IntColumn get revisionLocalId => integer().autoIncrement()();
  IntColumn get draftRecordId =>
      integer().references(AmcDraftRecords, #draftRecordId, onDelete: KeyAction.cascade)();
  TextColumn get body => text()();
  TextColumn get idempotencyKey => text()();              // UNIQUE
  TextColumn get remoteRevisionId => text().nullable()(); // Supabase amc_record_revisions.id
  IntColumn get createdAtMillis => integer()();
  @override List<Set<Column>> get uniqueKeys => [{idempotencyKey}];
}

// amc_attachment_queue — 画像/音声のローカル一時保存 + Storage upload キュー
class AmcAttachmentQueue extends Table {
  IntColumn get attachmentId => integer().autoIncrement()();
  IntColumn get draftRecordId =>
      integer().references(AmcDraftRecords, #draftRecordId, onDelete: KeyAction.cascade)();
  TextColumn get localUri => text()();                    // file:// 圧縮済みファイル
  TextColumn get mimeType => text()();                    // whitelist: image/jpeg, audio/m4a
  TextColumn get state => textEnum<AmcAttachmentState>()();// PENDING/UPLOADING/READY/NEEDS_RETRY/FAILED/EXPIRED
  TextColumn get storagePath => text().nullable()();      // {userId}/{draftRecordId}/{attachmentId}.jpg
  TextColumn get remoteAttachmentId => text().nullable()();
  IntColumn get attemptNumber => integer().withDefault(const Constant(0))();
  TextColumn get lastErrorCode => text().nullable()();
  IntColumn get expiresAtMillis => integer().nullable()();
  TextColumn get checksum => text().nullable()();
}

enum AmcSyncState { draft, queued, synced, failed }
enum AmcAttachmentState { pending, uploading, ready, needsRetry, failed, expired }
```

主要クエリ（Android DAO 相当）:
- `getPendingAttachmentsOnce()` — `PENDING` と `NEEDS_RETRY` を対象に取得（アップロード worker 用）。
- `getReadyByDraftId(draftRecordId)` — `READY` かつ `storagePath` 確定済み（DB 同期 worker 用）。
- `getPendingSyncOnce()` — `syncState = QUEUED` の下書き一括取得（DB 同期 worker 用）。
- `findLatestRevisionForDraft(draftRecordId)` — 最新リビジョン。
- 状態遷移 helper: `markAttachmentUploading`（attempt++） / `markAttachmentReady(storagePath)` /
  `markAttachmentNeedsRetry` / `markAttachmentFailed` / `markRecordSynced`。

### 3.3 マイグレーション方針
- **新規 DB として schemaVersion = 1 から開始する。** UI 用 5 表 + AMC キュー 3 表をまとめて v1 で作成する。
  Android の Room v1→v8 マイグレーション履歴は移植しない。
- 既存ユーザーの Android DB データを Flutter へ引き継ぐ要件は今回無し（別アプリ扱い）。
- Supabase 側スキーマ（`amc_records / amc_record_revisions / amc_attachments / amc_media_objects /
  profiles / share_links / share_grants`）は **Android と同一の Supabase プロジェクト/マイグレーションを共有**する。
  Flutter からは Postgrest で同じテーブルへ書く（`supabase/migrations/0001_*.sql`, `0002_storage_rls.sql`）。

### 3.4 DAO（drift `DriftAccessor`）— 移植する主要クエリ
Room の JOIN ロジック（`events → observation_events → records`）をそのまま SQL で再現する。

- `RecordDao`
  - `watchByEventWithAttachments(eventId)` — 3 テーブル JOIN（README 記載のクエリ）
  - `watchAllWithAttachments()` — 全履歴
  - `countByEvents(eventIds)` — 一覧バッジ用集計（LEFT JOIN）
- `EventDao`
  - `watchUpcoming(fromMillis)` / `getUpcoming` / `watchAll`
  - `findOngoing(now)` / `watchOngoing(now)`
  - `deleteStaleEvents(activeGoogleIds)` — `local-draft:` を除外して同期削除
  - `upsert`（`InsertMode.replace`）
- `ObservationEventDao`
  - `insertOrIgnore` → 戻りで既存なら `findByGoogleEventId`（`findOrCreate` 相当）
  - `updateGoogleId(...)` — 下書き確定時に local-draft の googleEventId を実 ID へ
- `AmcDraftDao` / `AmcAttachmentDao`（3.2 のクエリ群）
- `AnalyticsDao`
  - `getSummary` / `getDailyRecordCounts` / `getRecordTypeBreakdown` / `getTopEvents`
  - ※ Toggl 集計（`getTogglDailyDurations`）は除外

---

## 4. クラウド同期（Supabase）

Android の 2 ワーカー構成をそのまま移植する。**アップロード（Storage）→ DB 同期（Postgrest）→ ローカル削除**の
順序が不変条件であり、これを崩さない（添付の孤児化と FK 違反を防ぐため）。

### 4.1 認証（AuthRepository）
- `google_sign_in` で Google サインイン → `idToken` / `accessToken` を取得。
- `supabase.auth.signInWithIdToken(provider: OAuthProvider.google, idToken, accessToken)` で Supabase にサインイン。
- `isSupabaseAuthenticated()` = `client.auth.currentSession != null`、
  `currentSupabaseUserId()` = `client.auth.currentUser?.id`。
- セットアップ完了時（`SetupNotifier`）と設定画面の再試行導線（`SettingsNotifier`）の両方から呼べるようにする。
- `Google subject` と `auth.users.id` は 1対1 厳密（Android の設計前提を維持）。

### 4.2 写真アップロードの流れ（AmcAttachmentUploadWorker 相当）

```
ユーザーが写真を撮影 (image_picker)
  ↓
CameraService.compressToJpeg()  →  documentsDir/photos/img_XXX.jpg（2048px / JPEG 85%）
  ↓
AmcDraftRepository.queueAttachment()  →  amc_attachment_queue に PENDING 登録
  ↓
workmanager.registerOneOffTask("amc_attachment_upload", existingWorkPolicy: keep)
  ↓
[amc_attachment_upload_worker]
  ├─ cloud_sync_enabled = false → 即 success（スキップ）
  ├─ isSupabaseAuthenticated() = false → retry
  ├─ getPendingAttachmentsOnce()（PENDING / NEEDS_RETRY）
  ├─ resolveLocalFile(localUri)
  └─ storage.from('amc-media').uploadBinary(storagePath, bytes)
       storagePath = {userId}/{draftRecordId}/{attachmentId}.jpg
       成功 → markAttachmentReady(storagePath)   ※ ローカルファイルはここでは削除しない
       失敗 → markAttachmentNeedsRetry() / markAttachmentFailed()
```

- Web は workmanager 非対応のため、フォアグラウンドで直接アップロード（`kIsWeb` 分岐）。
- workmanager のコールバックは別 isolate のため、isolate 内で Supabase / drift / Repository を再初期化する。

### 4.3 テキスト + 添付メタの DB 同期（AmcRecordSyncWorker 相当）

```
addMemo() → getOrCreateDraftForEvent() + appendRevision()
  → amc_draft_records.syncState = QUEUED → enqueueSyncWorker()
  ↓
[amc_record_sync_worker]
  ├─ cloud_sync_enabled = false → success（スキップ）
  ├─ isSupabaseAuthenticated() = false → retry
  ├─ getPendingSyncOnce()（QUEUED ドラフト）
  └─ 各ドラフトに対して:
       1. amc_records に upsert → remoteRecordId (UUID) 確定（PATCH で current_body/visibility 更新）
       2. amc_record_revisions に insert（idempotency_key で冪等）→ PATCH amc_records.current_revision
       3. READY な添付を amc_attachments に insert（record_id = remoteRecordId）
       4. insert 成功後にローカルファイルを削除（cloud_sync_enabled = true のときのみ）
       5. markRecordSynced() → syncState = SYNCED
```

> **不変条件（リグレッション注意）**: `amc_attachments.record_id` は `amc_records.id`(UUID) の FK。
> `remoteRecordId` 確定後でないと添付メタを INSERT できない。
> ローカルファイル削除は「DB に添付メタが入った後」に限定する（孤児ファイル防止）。

### 4.4 Storage パス設計 / RLS（Supabase 側、Android と共通）

```
amc-media/{owner_user_id}/{draft_record_id}/{attachment_id}.jpg
amc-media/{owner_user_id}/{draft_record_id}/{attachment_id}.m4a
```

- bucket `amc-media`: private, 10 MB 上限, JPEG / M4A のみ。
- `storage_upload_own`: `foldername(name)[1] == auth.uid()` のみ INSERT 可。
- `storage_select_own`: 自分のファイルのみ SELECT 可。
- （後フェーズ）`share_grants` を参照する「共有相手は SELECT 可」ポリシーを追加。

### 4.5 ダウンロード（AmcStorageRepository.downloadToLocal 相当）
- `storage.from('amc-media').download(storagePath)` で `Uint8List` 取得。
- 端末保存はプラットフォーム分岐:
  - モバイル: `gal`（端末ギャラリー/Downloads）または `path_provider` + 共有保存。
  - Web: Blob ダウンロード。
- リポジトリ層を先に実装し、UI のダウンロードボタンは添付表示 UI（優先度中）と同時に設置する。

### 4.6 ローカル専用モード
- `app_preferences.dart` に `cloudSyncEnabled`（既定 true）を追加。設定画面に Switch を置く。
- 両ワーカーは冒頭で `cloud_sync_enabled` を確認し、false なら何もせず成功扱いで抜ける。
- OFF の間に作られた下書き/添付は `PENDING` / `QUEUED` のまま残り、ON 復帰時に同期される。

---

## 5. 外部連携（Google カレンダー / 通知 / カメラ）

### 5.1 Google カレンダー（取得 + 書き込み）
- 認証: `google_sign_in`（scope: `calendar.events` + Supabase 用に `openid email profile`）→
  `extension_google_sign_in_as_googleapis_auth` で `AuthClient` を生成。
  - **同じ Google サインインから Calendar 用 AuthClient と Supabase 用 idToken の両方を取り出す。**
- API: `googleapis` の `CalendarApi`。
  - `events.list(timeMin, timeMax, singleEvents: true, orderBy: 'startTime')`
  - `events.insert` / `events.patch` / `events.get`
- 終日イベントの `date` → `dateTime` フォールバックを移植。
- Google Calendar 全文ミラー（`content_policy.buildCalendarMirrorBody` 経由）を維持。長文退避は後フェーズ。

> Web は `google_sign_in_web`（GIS）で別実装。書き込みスコープは OAuth 同意が必要。

### 5.2 通知 / バックグラウンド（モバイルのみ）
- `flutter_local_notifications` でチャンネル `observation_reminders` を作成。
- `workmanager` で 15 分周期タスク → 進行中イベント判定 → 通知発行（`ObservationReminderWorker` 相当）。
  - workmanager の最小周期は 15 分。コールバックは別 isolate のため DB/Supabase を再初期化。
- 通知タップ → ペイロードに `eventId` → go_router で `AddRecord` へディープリンク。
- 権限: Android 13+ `POST_NOTIFICATIONS`、カメラ、マイクを `permission_handler` で要求。

### 5.3 カメラ / 音声
- 写真: `image_picker`（camera / gallery）→ `flutter_image_compress` で 2048px・JPEG 85% に圧縮 →
  `path_provider` の documents ディレクトリへ保存 → 絶対パスを添付キューと `PhotoEntity.filePath` に渡す。
- 音声メモ: `speech_to_text` で STT → `addMemoRecord(isVoice: true)`。

---

## 6. UI / ナビゲーション

### 6.1 ルート（go_router, `Screen.kt` 相当）
| ルート | 画面 | 引数 |
|---|---|---|
| `/setup` | SetupScreen | — |
| `/events` | EventListScreen（ホーム, start destination） | — |
| `/events/:eventId` | EventDetailScreen | eventId |
| `/add-record/:eventId` | AddRecordScreen | eventId |
| `/dashboard` | RecordDashboardScreen | `?eventId=&draftTitle=` |
| `/record/:recordId` | RecordDetailScreen | recordId |
| `/history` | HistoryScreen | — |
| `/analytics` | AnalyticsScreen | — |
| `/settings` | SettingsScreen | — |

- ボトムバー（ホーム / 履歴 / 分析）+ 中央 FAB（突発下書き開始）は `StatefulShellRoute` で実装。
- オンボーディング完了フラグ（`first_run_setup_complete`）で `/setup` ↔ `/events` を redirect 制御。

### 6.2 状態（ViewModel → Notifier）対応
| Android ViewModel | Flutter Notifier | 主な状態/ロジック |
|---|---|---|
| `EventListViewModel` | `EventListNotifier` | upcoming events + バッジ集計、同期トリガ |
| `EventDetailViewModel` | `EventDetailNotifier` | イベント + 記録（添付込み）Stream |
| `AddRecordViewModel` | `AddRecordNotifier` | 写真/テキスト/音声の追加 + **下書き作成 → 同期 worker 起動** |
| `RecordDashboardViewModel` | `RecordDashboardNotifier` | 進行中イベント結合、タイマー、長押し/ダブルタップ停止、下書き確定 |
| `RecordDetailViewModel` | `RecordDetailNotifier` | 記録詳細 |
| `HistoryViewModel` | `HistoryNotifier` | 全記録/全イベント |
| `AnalyticsViewModel` | `AnalyticsNotifier` | WEEK/MONTH 集計（Toggl 除く） |
| `SettingsViewModel` | `SettingsNotifier` | インターバル/通知 ON-OFF/**Supabase サインイン再試行/クラウド同期トグル/ローカルキュー要約** |
| `SetupViewModel` / `AppLaunchViewModel` | `SetupNotifier` / `appLaunchProvider` | オンボーディング + **Supabase サインイン** |

- ダッシュボードのタイマー表示は `Stream.periodic(1s)` で更新。
- 停止ボタンの「長押しで終了 / ダブルタップで即終了」は `GestureDetector` で再現。
- スナックバー系イベントは Riverpod の `ref.listen` + `ScaffoldMessenger`。
- **同期状態バッジ（PENDING / UPLOADING / READY / FAILED）**は `amc_attachment_queue` を watch して表示（優先度中）。

### 6.3 設定（DataStore → shared_preferences）
`AppPreferences` のキーをそのまま移植:
- `interval_minutes`（既定 60）/ `preset_order`（"1,3,5,10,25,30,60,0"）/ `notifications_enabled` /
  `custom_interval_minutes` / `first_run_setup_complete` / **`cloud_sync_enabled`（既定 true）**。
- shared_preferences は Stream を持たないので、Notifier 内で値を保持し書き込み時に通知。

---

## 7. 段階的な実装ステップ

1. **基盤**: `pubspec.yaml` 依存追加（drift, riverpod, go_router, dio/googleapis, **supabase_flutter（導入済み）**,
   google_sign_in（導入済み）, extension_google_sign_in_as_googleapis_auth, shared_preferences,
   flutter_local_notifications, workmanager, image_picker, flutter_image_compress, speech_to_text,
   path_provider, gal, permission_handler, synchronized, rxdart, intl）。
   `main()` で `Supabase.initialize` を `await` → `ProviderScope` でラップ。
2. **DB**: drift の UI 用 5 表 + AMC キュー 3 表 + DAO + `foreign_keys=ON`。`build_runner` 生成。
3. **Repository（ローカル完結部分）**: Observation/Record/Event を移植、JOIN とバッジ集計をユニットテスト。
4. **UI スケルトン**: go_router + ボトムシェル + 各画面の空実装。テーマ移植。
5. **記録フロー**: ダッシュボード（タイマー/記録追加/停止）→ 写真（image_picker + 圧縮）→ メモ → 音声。
6. **Google カレンダー**: サインイン → 取得同期 → 下書き確定 / メモ追記。
7. **Supabase 認証**: google_sign_in idToken → `signInWithIdToken`。セットアップ/設定からの導線。
8. **クラウド同期**: 添付アップロード worker → DB 同期 worker → ローカル削除順序 → ローカル専用モードトグル。
9. **ダウンロード**: `AmcStorageRepository.downloadToLocal` + 端末保存（プラットフォーム分岐）。UI は添付表示と同時。
10. **通知 / リマインダー Worker**: 通知サービス + workmanager 15 分周期 + タップ deep link。
11. **分析 / 履歴 / 設定**: 集計画面（Toggl 列を除外）、設定の永続化、同期状態バッジ。
12. **プラットフォーム差分**: iOS の権限 plist、Web のフォールバック（通知/workmanager 無効化、アップロードはフォアグラウンド）。

---

## 8. プラットフォーム別の注意点（iOS/Web 展開）

| 機能 | Android | iOS | Web |
|---|---|---|---|
| drift DB | ✅ | ✅ | ✅（drift_wasm / IndexedDB） |
| 写真ファイルパス保存 | ✅ | ✅ | ⚠️ パス概念が無い → Blob/IndexedDB 保存に要変更 |
| カメラ | ✅ | ✅ | ⚠️ getUserMedia ベース、制約あり |
| 音声 STT | ✅ | ✅ | ⚠️ Web Speech API、ブラウザ依存 |
| ローカル通知 | ✅ | ✅（権限要） | ❌ |
| workmanager 定期実行 | ✅ | ⚠️ BGTask 制約大 | ❌ |
| Google Sign-In | ✅ | ✅（plist 設定要） | ⚠️ GIS、別実装 |
| **Supabase Auth** | ✅ | ✅ | ✅（リダイレクト URL 設定要） |
| **Supabase Storage upload** | ✅ | ✅ | ✅ |
| **Supabase DB 同期** | ✅ | ✅ | ✅ |
| **クラウド同期 worker（バックグラウンド）** | ✅ | ⚠️ BGTask 制約 | ⚠️ フォアグラウンドで実行 |

→ **Web は「閲覧 + 手動記録 + クラウド同期はフォアグラウンド」中心、通知/定期バックグラウンドは無効化**。
`kIsWeb` / `Platform` で分岐。Repository インタフェースは共通化し、実装をプラットフォーム別に差し替える。

---

## 9. 移植時に維持すべき不変条件（リグレッション注意）

### ローカル（既存）
- `events` 削除が `records`/写真/メモを巻き込まない（ソフト参照 + observation_events 経由）。
- `findOrCreate` の insert-or-ignore セマンティクス（重複 googleEventId で既存 obsEventId を返す）。
- 下書き確定時の `observation_events.googleEventId` 付け替え（local-draft → 実 ID）。
- メモ追記の googleEventId 別ロック（並行追記の競合防止、`package:synchronized` の `Lock`）。
- 同期の stale 削除が `local-draft:%` を除外すること。
- 写真/メモ追加は record と添付を 1 トランザクションで（部分挿入を作らない）。
- 本文保存前に NFC 正規化する。

### クラウド（新規）
- **添付削除順序**: Storage upload（READY）→ DB に `amc_attachments` INSERT → ローカルファイル削除。逆順禁止。
- `amc_attachments.record_id` INSERT は `remoteRecordId`(UUID) 確定後のみ。
- revision INSERT と `current_revision` / `current_body` / `updated_at` 更新は同一トランザクション。
- `amc_record_revisions` は `idempotency_key` で冪等（再送で重複行を作らない）。
- 添付 MIME は whitelist（image/jpeg, audio/m4a）。
- ローカル専用モード OFF 時、両 worker は副作用なしでスキップする（PENDING/QUEUED は温存）。
- Supabase 初期化は `runApp` 前に `await` 完了させる（worker が未ロードセッションで走る事故を防ぐ）。

---

## 10. 後フェーズ（計画にのみ記載、今回未着手）
- 共有・認可 UI（private / specific users / friends / public / limited public）と `share_links` / `share_grants`。
- Google Calendar 全文ミラーの長文退避（要約 + 本文参照 URL）と再試行ジョブ。
- サムネイル / 手動マージ UI / 削除復元 UI / 共有アクセス履歴 UI。
- Supabase セッション期限切れ時の再サインイン UX。

## 付録: 除外したものの一覧（再掲）
- Toggl 一式（`data/remote/toggl/*`, `TogglRepository`, `toggl_*` テーブル, 分析の Toggl 集計）。
- R2 presigned PUT 方式（Android で `supabase-kt` 直接 upload を採用したため不採用）。
- `AmcAttachmentQueueLogger` の永続監査ログ（Logcat 中心のデバッグログは必要に応じて Flutter の `logger` で代替）。
