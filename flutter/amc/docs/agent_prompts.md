# Flutter 移管 — マルチエージェント実装プロンプト集

`docs/migration_plan.md` を別スレッド（コールドスタート）のエージェントで実装するための、そのまま貼れるプロンプト集。

## 投げる順番

1. **波1（直列）**: P0 → P1 → P2 を順番に。P1 完了の DAO 一覧、P2 完了の `FROZEN_CONTRACT` を必ず手元に保存する。
2. **波2（並列）**: `FROZEN_CONTRACT` を貼って機能スレッドを並列起動。重い3画面（add_record / dashboard / settings）は単独、軽い画面は同時で可。
3. **波3（直列）**: 各機能スレッドの成果を順にマージ → P4 → P5。

> 鍵: コールドな別スレッドには毎回「契約（FROZEN_CONTRACT）を貼る」「触っていいディレクトリを1つに限定する」を徹底する。崩れると統合時に Repository API 食い違いで全滅する。

---

## 0. 全スレッド共通ヘッダ（毎回これを先頭に貼る）

```
# プロジェクト前提（コールドスタート用）
- 作業対象: /Users/yuuto/learn_lab/AleartMyController/flutter/amc （Flutter プロジェクト）
- 移管元: /Users/yuuto/learn_lab/AleartMyController（Android/Kotlin 実装）
- 設計の唯一の正本: flutter/amc/docs/migration_plan.md を必ず最初に読むこと
- Android の実装意図参照: docs/amc_handoff.md
- 作業前に必ず `git status` を確認。指示外のファイルは触らない。
- 完了時は必ず「触ったファイル一覧」と「計画と食い違った点・不足API」を報告すること。
- 不明点を勝手に発明しない。仕様が曖昧なら止めて質問する。
```

---

## 波1（直列・単一スレッドで P0→P1→P2 の順）

### スレッド P0：足場

```
[共通ヘッダを貼る]

# タスク: Phase 0 足場のみ
migration_plan.md の §1, §2, §6.1 に従い、以下だけを作る。機能ロジックは書くな。

1. pubspec.yaml に §7 の依存を追加（supabase_flutter / google_sign_in は導入済み）。
   drift, riverpod, go_router, googleapis, extension_google_sign_in_as_googleapis_auth,
   shared_preferences, flutter_local_notifications, workmanager, image_picker,
   flutter_image_compress, speech_to_text, path_provider, gal, permission_handler,
   synchronized, rxdart, intl, + dev: drift_dev, build_runner, riverpod_generator。
2. main.dart: `await Supabase.initialize(url, anonKey)` → ProviderScope → runApp。
   url/anonKey は --dart-define から読む形にし、TODO コメントで明示。
3. app.dart: MaterialApp.router + Material3 テーマ（core/theme/ にスタブ）。
4. routing/app_router.dart: §6.1 の全ルートを「空画面（Placeholder）」で先に定義。
   StatefulShellRoute でボトムバー(ホーム/履歴/分析)+中央FAB。
   ★ここで全ルートのスタブを置くのが重要。後続の機能エージェントはこの画面の中身だけ差し替える。
5. §2 のディレクトリ構造を空ファイル/TODOで作る（features/ は空画面、providers/ は空）。

完了条件: `flutter analyze` がクリーン、`flutter run` でボトムバー付きの空アプリが起動する。
build_runner はまだ走らせなくてよい（drift は次フェーズ）。
```

### スレッド P1：drift データ層（★並列禁止の土台）

```
[共通ヘッダを貼る]

# タスク: Phase 1 データ層のみ
migration_plan.md の §3 全体が仕様。

1. data/local/tables.dart: UI用5表（Events/ObservationEvents/Records/Photos/Memos）
2. data/local/amc_tables.dart: AMCキュー3表（AmcDraftRecords/AmcRecordRevisions/AmcAttachmentQueue）
   §3.2 のカラム・enum・unique key を厳密に。
3. data/local/database.dart: schemaVersion=1。beforeOpen で PRAGMA foreign_keys=ON。
4. data/local/daos/: §3.4 のクエリを実装（Toggl 集計は除外）。
5. `dart run build_runner build --delete-conflicting-outputs` で .g.dart 生成。

不変条件(§9): events削除がrecordsを巻き込まない/CASCADEはobservation_events経由。

完了条件: `flutter analyze` クリーン。生成コードがコミット可能な状態。
★最後に必須: 後続Repositoryが依存するDAOの全公開メソッドのシグネチャを一覧出力せよ。
  これを Phase 2 の入力にする。
```

### スレッド P2：Repository（最後に「契約凍結」を出力）

```
[共通ヘッダを貼る]

# タスク: Phase 2 Repository層 + 契約凍結
migration_plan.md の §3.3後半, §4.1, §5 が仕様。P1 で生成済みのDAOを使う。

実装する Repository（依存順）:
1. ObservationEventRepository（findOrCreate: insert-or-ignore→既存返し）
2. RecordRepository（addPhotoRecord/addMemoRecord を1トランザクションで。NFC正規化）
3. EventRepository（syncFromCalendar/createDraft/closeDraft/finalizeDraft/appendMemo,
   observeOngoingEvent は Stream.periodic(60s)+switchMap(rxdart),
   googleEventId別ロックは package:synchronized）
4. AuthRepository（google_sign_in idToken → supabase.auth.signInWithIdToken）
5. AmcDraftRepository（queueAttachment/appendRevision→enqueueSyncWorker/markRecordSynced）
6. AmcStorageRepository（uploadBinary / downloadToLocal）

providers/repository_providers.dart と providers/supabase_providers.dart に Provider 登録。

不変条件(§9): §9 ローカル/クラウド両方を厳守。特にメモ追記のキー別ロックと stale削除の local-draft:除外。

完了条件: `flutter analyze` クリーン + Repository のユニットテスト（JOIN/バッジ集計/findOrCreate）。
★最後に必須【契約凍結】: 全Providerと全公開メソッドのシグネチャを
  「FROZEN_CONTRACT」という見出しで1ブロックにまとめて出力せよ。
  これを波2の各機能スレッドにそのまま貼る。
```

---

## 波2（★並列・機能ごとに別スレッド）

> 起動条件: P2 が出した **FROZEN_CONTRACT** を手元にコピーしておくこと。各スレッドに貼る。

### 機能スレッド テンプレ（下の表で `{}` を埋めて複製）

```
[共通ヘッダを貼る]

# タスク: Phase 3 単一機能のみ ─ 担当は「{画面名}」だけ
別スレッドが他機能を並行実装中。お前の責務は1機能に閉じる。

読むこと:
- migration_plan.md の §6.2 の {Notifier名} 行、§6.1 の該当ルート、§9
- 移管元 Android: app/src/main/java/com/example/aleartmycontroller/ui/viewmodel/{VM}.kt
                  app/src/main/java/com/example/aleartmycontroller/ui/screen/{Screen}.kt

使ってよいAPI（新設・変更禁止。これ以外のRepositoryを触るな）:
----- FROZEN_CONTRACT を以下に貼る -----
{P2が出力した契約をここに貼り付け}
----------------------------------------

編集してよいファイル:
- lib/features/{dir}/** のみ
- 共有widgetが要れば lib/widgets/ に新規追加のみ可（既存widgetの改変は不可）

読むだけ・編集禁止:
- providers/**, data/**, database.dart, main.dart, pubspec.yaml
- app_router.dart（ルートはP0で定義済み。画面の中身だけ差し替える）
- build_runner は走らせるな（生成コードは確定済み）

不変条件(§9): {この機能に効く不変条件を表から転記}

完了条件:
- `flutter analyze lib/features/{dir}` クリーン
- P0の空画面（Placeholder）が実装に置き換わり、既存ルートから到達できる
- 触ったファイル一覧 + 「凍結APIで不足した点」を報告
```

### 複製用の埋め込み表

| 画面名 | {dir} | {Notifier名} | {VM}/{Screen} | この機能の不変条件(§9) |
|---|---|---|---|---|
| イベント一覧(ホーム) | `event_list` | EventListNotifier | EventListViewModel / EventListScreen | stale削除が`local-draft:%`除外 / バッジ集計はLEFT JOIN |
| イベント詳細 | `event_detail` | EventDetailNotifier | EventDetailViewModel / EventDetailScreen | events削除がrecordsを巻き込まない |
| 記録追加 | `add_record` | AddRecordNotifier | AddRecordViewModel / AddRecordScreen | record+添付は1トランザクション / 下書き作成→同期worker起動 / NFC正規化 |
| 記録ダッシュボード | `dashboard` | RecordDashboardNotifier | RecordDashboardViewModel / RecordDashboardScreen | タイマーStream.periodic(1s) / 長押し・ダブルタップ停止(GestureDetector) |
| 記録詳細 | `record_detail` | RecordDetailNotifier | RecordDetailViewModel / RecordDetailScreen | （特になし、表示のみ） |
| 履歴 | `history` | HistoryNotifier | HistoryViewModel / HistoryScreen | 3テーブルJOIN結果の表示整合 |
| 分析 | `analytics` | AnalyticsNotifier | AnalyticsViewModel / AnalyticsScreen | Toggl集計は除外する |
| 設定 | `settings` | SettingsNotifier | SettingsViewModel / SettingsScreen | cloud_sync_enabledトグル / Supabaseサインイン再試行導線 |
| セットアップ | `setup` | SetupNotifier | SetupViewModel / SetupScreen | first_run_setup_completeでredirect / 完了時Supabaseサインイン |

> `record_detail` のように依存が薄い画面と `dashboard` のように重い画面が混在する。
> **重い3つ（add_record / dashboard / settings）は別々のスレッドに単独で割り当て**、軽いものは並べても可。

---

## 波3（直列・単一スレッド）

### スレッド P4：クラウド/通知 worker

```
[共通ヘッダを貼る]

# タスク: Phase 4 worker層（横断的なので単一スレッドで）
migration_plan.md の §4.2, §4.3, §5.2 が仕様。波2 完了後に着手。

1. services/amc_attachment_upload_worker.dart（Storage upload→READY。ファイル削除しない）
2. services/amc_record_sync_worker.dart（§4.3 の順序厳守: records upsert→revisions insert→
   attachments insert→ローカル削除→markRecordSynced）
3. services/reminder_worker.dart + notification_service.dart（15分周期, deep link payload=eventId）
4. workmanager コールバックは別isolateなので、isolate内でSupabase/drift/Repositoryを再初期化。
5. cloud_sync_enabled=false の時、両AMC workerは副作用なしでスキップ。

不変条件(§9 クラウド): 添付削除順序 / remoteRecordId確定後のINSERT / idempotency_key冪等 /
Supabase.initializeはrunApp前にawait済み（P0で担保）。

完了条件: `flutter analyze` クリーン。worker登録がmainから配線されている。
Web分岐(kIsWeb)でworkmanagerを無効化しフォアグラウンド実行にフォールバック。
```

### スレッド P5：統合・プラットフォーム・最終検証

```
[共通ヘッダを貼る]

# タスク: Phase 5 統合と最終検証
波2/P4 を全てマージした後に実行。

1. 通知タップ→go_routerで /add-record/:eventId へのdeep link配線を確認・修正。
2. iOS: Info.plist にカメラ/マイク/通知の権限文言。Supabaseリダイレクト URL。
3. Android: POST_NOTIFICATIONS等の権限を permission_handler で要求する導線。
4. §8 の Web フォールバック（通知/定期background無効、写真パス→Blob方針のTODO明記）。
5. 全体検証: `flutter analyze` 全クリーン、`flutter test` 全緑、`flutter build apk --debug` 成功。

完了条件: 上記コマンドが全て成功。残課題（後フェーズ §10）を一覧化して報告。
```
