# 波3 引き継ぎ資料（P4 / P5）

最終更新: 2026-06-03

---

## 現状スナップショット

| 項目 | 状態 |
|---|---|
| 波1 (P0/P1/P2) | ✅ コミット済み (fead013) |
| 波2 (9画面) | ✅ コミット済み (fead013) |
| `flutter analyze lib/` | ✅ エラー0件 / info 8件のみ |
| テスト | ✅ 12/12 green |
| drift web 対応 | ✅ `web/drift_worker.js` + `web/sqlite3.wasm` 追加済み |
| Supabase 未初期化ガード | ✅ `supabase_providers.dart` に null ガード追加済み |

---

## 残る lint info 8件（放置可）

| ファイル | 内容 | 対応要否 |
|---|---|---|
| `add_record_notifier.dart` | `localeId` deprecated (speech_to_text) | P5 か後続で対応 |
| `settings_screen.dart` | `groupValue`/`onChanged` deprecated (Flutter 3.32+) | RadioGroup 移行で解消、低優先 |
| 各 screen.dart | `__` 変数スタイル | 放置可 |

---

## 次のタスク: 波3

### P4: worker 層（横断的・単一スレッド）

**設計書**: `docs/migration_plan.md` の §4.2, §4.3, §5.2

実装するファイル（すべて新規）:

```
lib/services/
  amc_attachment_upload_worker.dart  ← Storage upload → READY（ファイル削除しない）
  amc_record_sync_worker.dart        ← §4.3 の順序厳守
  reminder_worker.dart               ← 15分周期、deep link payload=eventId
  notification_service.dart          ← flutter_local_notifications ラッパー
```

**§4.3 同期順序（厳守）**:
1. `records` upsert（idempotency_key で冪等）
2. `revisions` insert
3. `attachments` insert（remoteRecordId 確定後）
4. ローカル添付ファイル削除
5. `markRecordSynced(draftRecordId, remoteRecordId, currentRevisionId)`

**重要制約**:
- workmanager コールバックは別 isolate → Supabase / drift / Repository を isolate 内で再初期化
- `cloud_sync_enabled=false` のとき両 AMC worker は副作用なしでスキップ
- Web 分岐 (`kIsWeb`) で workmanager を無効化し、フォアグラウンド実行にフォールバック
- `amcWorkSchedulerProvider` は現在 Noop 実装 → P4 で本実装に差し替える

**frozen_contract で使うAPI**（`docs/frozen_contract.md` 参照）:
```
AmcWorkScheduler.enqueueAttachmentUpload()
AmcWorkScheduler.enqueueRecordSync()
AmcDraftRepository.queueAttachment(...)
AmcDraftRepository.appendRevision(...)
AmcDraftRepository.markRecordSynced(...)
AmcStorageRepository.uploadBinary(...)
```

---

### P5: 統合・プラットフォーム・最終検証（P4 完了後）

**設計書**: `docs/migration_plan.md` の §8, §10

実施項目:

1. **deep link 配線**
   - 通知タップ → `go_router` で `/add-record/:eventId` へのディープリンク
   - `app_router.dart` の redirect ロジックに `appLaunchProvider` を結線
     （`setup_notifier.dart` に `appLaunchProvider` 実装済み）

2. **iOS**
   - `ios/Runner/Info.plist` にカメラ・マイク・通知の権限文言追加
   - Supabase OAuth リダイレクト URL 設定

3. **Android**
   - `POST_NOTIFICATIONS` 等を `permission_handler` で要求する UI 導線

4. **Web フォールバック**（`docs/migration_plan.md` §8）
   - 通知・定期バックグラウンド → 無効化済み（kIsWeb で分岐）
   - 写真パス → Blob 方針の TODO を明記（P5 で確認）

5. **最終検証コマンド**
   ```bash
   flutter analyze           # 全クリーン
   flutter test              # 全 green
   flutter build apk --debug # ビルド成功
   flutter run -d chrome     # Web 動作確認
   ```

---

## 既知の落とし穴（波2 で学んだこと）

| 問題 | 内容 | 対処 |
|---|---|---|
| **bgIsolation** | バックグラウンドエージェントはデフォルトでメイン checkout に書き込めない | `.claude/settings.json` に `"worktree": {"bgIsolation": "none"}` 追加済み |
| **Riverpod 3.x family** | `AutoDisposeFamilyNotifier` は存在しない | コンストラクタ引数パターン: `class MyNotifier extends Notifier<S>` + `MyNotifier(this.arg)` で family |
| **Riverpod 3.x autoDispose** | `AutoDisposeNotifier` は存在しない | `NotifierProvider.autoDispose<N, S>(N.new)` |
| **drift web** | `driftDatabase(name:)` だけでは Chrome でクラッシュ | `web:` パラメータに `DriftWebOptions` が必要 |
| **Supabase 未初期化** | dart-define 未設定時に auth/storage 系 provider が throw | `supabase_providers.dart` に null ガード追加済み |
| **RecordWithAttachments import** | `record_dao.dart` のインポートが必要 | `data/local/daos/record_dao.dart` を追加 |

---

## P4 スレッドに貼るプロンプトベース

```
# プロジェクト前提（コールドスタート用）
- 作業対象: /Users/yuuto/learn_lab/AleartMyController/flutter/amc
- 移管元: /Users/yuuto/learn_lab/AleartMyController
- 設計: flutter/amc/docs/migration_plan.md を必ず最初に読む（§4.2, §4.3, §5.2）
- frozen_contract: flutter/amc/docs/frozen_contract.md
- 作業前に git status 確認。指示外ファイルは触らない。
- 完了時に「触ったファイル一覧」「不足API・計画との食い違い」を報告。

# タスク: Phase 4 worker 層（横断的・単一スレッドで）
wave2 完了後に着手。

実装ファイル（すべて新規）:
- lib/services/notification_service.dart
- lib/services/amc_attachment_upload_worker.dart
- lib/services/amc_record_sync_worker.dart
- lib/services/reminder_worker.dart

重要制約:
- workmanager コールバックは別 isolate → isolate 内で Supabase/drift/Repository を再初期化
- cloud_sync_enabled=false の時、両 AMC worker は副作用なしでスキップ
- kIsWeb で workmanager 無効化、フォアグラウンド実行にフォールバック
- amcWorkSchedulerProvider（現在 Noop）を本実装に差し替える
- §4.3 同期順序厳守: records upsert → revisions → attachments → local削除 → markRecordSynced

完了条件:
- flutter analyze クリーン
- worker 登録が main.dart から配線されている
- Web 分岐(kIsWeb)で workmanager 無効化・フォアグラウンドフォールバック確認
- 触ったファイル一覧 + 凍結APIで不足した点を報告
```

---

## ファイル配置（参考）

```
flutter/amc/
├── lib/
│   ├── features/          ← 波2完了 (9画面)
│   ├── data/
│   │   ├── local/         ← 波1完了 (drift DB + DAO)
│   │   └── repository/    ← 波2完了 (6 Repository)
│   ├── providers/         ← 波2完了
│   ├── services/          ← ★P4 で新規作成
│   ├── core/
│   └── routing/app_router.dart
├── web/
│   ├── drift_worker.js    ← 追加済み
│   └── sqlite3.wasm       ← 追加済み
└── docs/
    ├── migration_plan.md  ← 設計の正本
    ├── frozen_contract.md ← Repository/DAO 公開API契約
    ├── amc_handoff.md     ← Android 実装意図
    └── wave3_handoff.md   ← 本ファイル
```
