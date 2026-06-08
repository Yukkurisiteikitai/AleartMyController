// ============================================================
// FROZEN_CONTRACT  (flutter/amc) — Wave 2 各機能スレッドに貼る
// これ以外の Repository/DAO の新設・シグネチャ変更は禁止。
// providers/ data/ database.dart app_router.dart pubspec.yaml は読むだけ。
// ============================================================

// ---- import 元 ----
// providers:  package:amc/providers/{database_providers,repository_providers,supabase_providers}.dart
// 型:         package:amc/data/local/database.dart            (row型 + Companion, 生成物)
//             package:amc/data/local/tables.dart              (RecordType, localDraftGoogleIdPrefix)
//             package:amc/data/local/amc_tables.dart          (AmcSyncState, AmcAttachmentState)
//             package:amc/data/local/daos/record_dao.dart     (RecordWithAttachments, RecordCountResult)
//             package:amc/data/local/daos/analytics_dao.dart  (DailyRecordCount, RecordTypeCount, EventRecordCount)
//             package:amc/data/repository/<name>.dart          (各Repository型)

// ---- drift row型 / Companion / enum / 集計POJO ----
// row:  Event, ObservationEvent, Record, Photo, Memo,
//       AmcDraftRecord, AmcRecordRevision, AmcAttachment
// companion: EventsCompanion, ObservationEventsCompanion, RecordsCompanion,
//       PhotosCompanion, MemosCompanion, AmcDraftRecordsCompanion,
//       AmcRecordRevisionsCompanion, AmcAttachmentQueueCompanion
// enum: RecordType{photo,memo}
//       AmcSyncState{draft,queued,synced,failed}
//       AmcAttachmentState{pending,uploading,ready,needsRetry,failed,expired}
// const String localDraftGoogleIdPrefix = 'local-draft:';
// class RecordWithAttachments { Record record; List<Photo> photos; List<Memo> memos; }
// class RecordCountResult     { int eventId; int photoCount; int memoCount; }
// class DailyRecordCount      { int dayKey; int totalCount; int photoCount; int memoCount; }
// class RecordTypeCount       { String recordType; int count; }
// class EventRecordCount      { String eventTitle; int recordCount; }

// ---- Providers (P1) ----
appDatabaseProvider               : Provider<AppDatabase>
eventDaoProvider                  : Provider<EventDao>
observationEventDaoProvider       : Provider<ObservationEventDao>
recordDaoProvider                 : Provider<RecordDao>
photoDaoProvider                  : Provider<PhotoDao>
memoDaoProvider                   : Provider<MemoDao>
analyticsDaoProvider              : Provider<AnalyticsDao>
amcDraftDaoProvider               : Provider<AmcDraftDao>
amcAttachmentDaoProvider          : Provider<AmcAttachmentDao>
supabaseClientProvider            : Provider<SupabaseClient>     // Supabase初期化済み前提
authStateProvider                 : StreamProvider<AuthState>

// ---- Providers (P2) ----
googleSignInProvider              : Provider<GoogleSignIn>
authRepositoryProvider            : Provider<AuthRepository>     // Supabase初期化済み前提
googleCalendarApiProvider         : Provider<GoogleCalendarApi>
observationEventRepositoryProvider: Provider<ObservationEventRepository>
recordRepositoryProvider          : Provider<RecordRepository>
eventRepositoryProvider           : Provider<EventRepository>
amcWorkSchedulerProvider          : Provider<AmcWorkScheduler>   // 現状Noop, P4でoverride
amcDraftRepositoryProvider        : Provider<AmcDraftRepository>
amcStorageRepositoryProvider      : Provider<AmcStorageRepository> // Supabase初期化済み前提

// ============================================================
//  公開メソッド
// ============================================================

AnalyticsDao   // 全て fromMillis 起点。Toggl集計は無い
  Future<int> getTotalCount(int fromMillis)
  Future<int> getPhotoCount(int fromMillis)
  Future<int> getMemoCount(int fromMillis)
  Future<List<DailyRecordCount>> getDailyRecordCounts(int fromMillis)
  Future<List<RecordTypeCount>>  getRecordTypeBreakdown(int fromMillis)
  Future<List<EventRecordCount>> getTopEventsByRecordCount(int fromMillis)

ObservationEventRepository
  Future<int>               findOrCreate(Event event)   // 重複は既存obsEventIdを返す
  Future<ObservationEvent?> findById(int obsEventId)

RecordRepository
  Stream<List<Record>>                watchRecordsByEvent(int eventId)
  Stream<List<RecordWithAttachments>> watchRecordsByEventWithAttachments(int eventId)
  Stream<List<Record>>                watchAllRecords()
  Stream<List<RecordWithAttachments>> watchAllRecordsWithAttachments()
  Future<Record?>     findRecordById(int recordId)
  Future<int>         addPhotoRecord(Event event, String filePath)             // 1 tx
  Future<int>         addMemoRecord(Event event, String text, {bool isVoice})  // 1 tx, NFC正規化
  Future<void>        deleteRecord(int recordId)
  Future<List<Photo>> getPhotosForRecord(int recordId)
  Future<List<Memo>>  getMemosForRecord(int recordId)
  Future<void>        pullFromCloud(SupabaseClient? client)                    // cloud→local pull, null-safe

EventRepository
  Stream<List<Event>> watchUpcomingEvents()
  Stream<List<Event>> watchAllEvents()
  Future<List<Event>> getUpcomingEventsOnce()
  Future<Event?>      findById(int id)
  Future<Event?>      getOngoingEvent()
  Stream<Event?>      observeOngoingEvent()                       // 60秒ごと引き直し
  Future<void>        syncFromCalendar()                          // 今日〜7日, stale削除(local-draft:除外)
  Future<Event>       createDraftEvent(String title)
  Future<Event>       closeDraftEvent(int eventId, int endTimeMillis)
  Future<Event>       finalizeDraftEvent(int eventId, String? description)   // googleId付け替え, lock保護
  Future<void>        appendMemoToGoogleEvent(Event event, String memoText)  // ミラー追記, lock保護

AuthRepository
  bool                         isSupabaseAuthenticated()
  String?                      currentSupabaseUserId()
  Future<GoogleSignInAccount?> signInSilently()
  Future<void>                 signInWithSupabase()               // 失敗時 throw
  Future<AuthClient?>          calendarAuthClient()
  static List<String>          defaultScopes

GoogleCalendarApi
  Future<gcal.Events> listEvents({required DateTime timeMin, required DateTime timeMax})
  Future<gcal.Event>  getEvent(String eventId)
  Future<gcal.Event>  insertEvent({required String summary, String? description, required int startMillis, required int endMillis})
  Future<gcal.Event>  patchEvent(String eventId, {String? description})

AmcWorkScheduler (interface)    // 実体はP4。波2では起動されない前提でOK
  Future<void> enqueueAttachmentUpload()
  Future<void> enqueueRecordSync()

AmcDraftRepository
  Stream<int>  watchUnsyncedCount()
  Future<int>  getOrCreateDraftForEvent(int obsEventId)   // ※obsEventId(eventIdではない)
  Future<void> appendRevision(int draftRecordId, String newBody)  // 1 tx, idempotent, →sync起動
  Future<int>  queueAttachment({required int draftRecordId, required String localUri, required String mimeType, String? checksum})  // →upload起動
  Future<void> markRecordSynced(int draftRecordId, {String? remoteRecordId, String? currentRevisionId})
  String       buildCalendarMirrorBody(String body, {String? referenceUrl})

AmcStorageRepository
  Future<String>    uploadBinary({required String storagePath, required Uint8List bytes, required String mimeType})
  Future<Uint8List> downloadBytes(String storagePath)
  Future<String>    downloadToLocal({required int attachmentId, required String storagePath, required String mimeType})

// ---- 波2が守る制約 ----
// 1. amcWorkSchedulerProvider は Noop。同期workerは動かない前提で実装してよい。
// 2. Supabase未初期化(dart-define未設定)では auth/storage/supabaseClient を watch するとthrow。
//    ローカル完結画面のテストでは触らない。
// 3. add_record: observationEventRepository.findOrCreate(event) で obsEventId を解決してから
//    amcDraftRepository.getOrCreateDraftForEvent(obsEventId) を呼ぶ。
