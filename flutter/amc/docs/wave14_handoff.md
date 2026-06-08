# 波14 引き継ぎ資料

最終更新: 2026-06-05

---

## 現状スナップショット

| 項目 | 状態 |
|---|---|
| `flutter analyze lib/` | info 1件のみ（`localeId` deprecated・既存コード） |
| `flutter test` | 12/12 green |
| `make build-apk` | ✓ `build/app/outputs/flutter-apk/app-debug.apk` |
| ブランチ | `feature/Yukkurisiteikitai/flutter_changes` |
| 最終コミット | `bbe925f` feat: 波14 Cloud→Local データ同期 — RecordRepository.pullFromCloud() 実装 |

---

## 今回触ったファイル一覧

### 波14 — Cloud→Local データ同期

| ファイル | 内容 |
|---|---|
| `docs/frozen_contract.md` | `RecordRepository.pullFromCloud()` シグネチャを追記 |
| `lib/data/local/daos/amc_draft_dao.dart` | `getExistingRemoteRecordIds()` を追加（pull 重複チェック用） |
| `lib/data/repository/observation_event_repository.dart` | `findOrCreateByRaw()` を追加（クラウド由来レコード用） |
| `lib/data/repository/record_repository.dart` | `AmcDraftDao` 追加・`pullFromCloud()` 実装 |
| `lib/providers/repository_providers.dart` | `recordRepositoryProvider` に `amcDraftDao` を渡す |
| `lib/features/settings/settings_notifier.dart` | `isSyncing` / `lastSyncError` 追加・`syncNow()` 実装 |
| `lib/features/settings/settings_screen.dart` | 「今すぐ同期」ボタンを追加 |
| `test/repository_test.dart` | `amcDraftDao` パラメータを追加（コンパイルエラー修正） |

---

## 実装内容

### `RecordRepository.pullFromCloud(SupabaseClient? client)`

```
Supabase amc_records
  ↓ .eq('owner_user_id', userId).isFilter('deleted_at', null)
差分チェック（AmcDraftDao.getExistingRemoteRecordIds() で既存 remoteRecordId を取得）
  ↓ 新規のみ処理
ObservationEvent の find or create（google_calendar_event_id or "cloud:{id}" で解決）
  ↓
トランザクション:
  records(type=memo) + memos + amc_draft_records(syncState=synced, remoteRecordId=cloud.id)
```

**制限事項（今波の対象外）:**
- `current_body` が空のレコード（添付のみ）はスキップ
- 写真添付（`amc_attachments`）のダウンロードは未実装
- `google_calendar_event_id` がない場合は `"cloud:{remoteId}"` の合成 ID を使う
- 引数なし `observation_event` のタイトルは `current_body` 先頭50字を使う

### `SettingsNotifier.syncNow()`

- `isSyncing = true` にしてから `pullFromCloud()` を呼ぶ
- 失敗時は `lastSyncError` に格納、クラッシュしない設計
- サインイン前はボタン無効（UI 側で `isSignedIn` チェック）

---

## 判明した落とし穴

- `supabase_flutter` の IS NULL フィルタは `.isFilter('column', null)` （`.is_()` は未定義）
- `RecordRepository` のコンストラクタ変更によりテストもコンパイルエラーになった → `test/repository_test.dart` に `amcDraftDao` 追加が必要

---

## 残っている課題

| 優先度 | 課題 | 対応方針 |
|---|---|---|
| 高 | 写真添付のクラウド pull | `amc_attachments` を取得し `AmcStorageRepository.downloadToLocal()` でローカル保存 |
| 中 | 自動同期トリガー | サインイン時・アプリ起動時に自動で `syncNow()` を呼ぶ（`SettingsNotifier.build()` 内） |
| 中 | マスコット実アセット | `assets/images/mascot_placeholder.png` を差し替え |
| 中 | Android 写真プレビュー確認 | `Image.file` 修正済み。実機再起動で確認 |
| 低 | `localeId` deprecated 警告 | `add_record_notifier.dart:297` を `SpeechListenOptions.localeId` に変更 |
| 低 | Swift Package Manager 警告 | プラグイン側対応待ち |

---

## 次のタスク（波15）

### 優先タスク: 写真添付のクラウド pull & 自動同期

```bash
# 実装対象
lib/data/repository/record_repository.dart  # pullFromCloud に写真処理を追加
lib/data/repository/amc_storage_repository.dart  # downloadToLocal 活用
lib/features/settings/settings_notifier.dart  # build() での自動 syncNow
```

実装方針:
1. `pullFromCloud()` で `amc_attachments` も取得（`type='IMAGE'` のみ）
2. `AmcStorageRepository.downloadToLocal()` で Storage から端末にダウンロード
3. 取得済みの `recordId` に対して `photos` 行を追加（`filePath = localPath`）
4. `SettingsNotifier.build()` 内で `authStateProvider` の変化時に `syncNow()` を呼ぶ

### 波15 スレッド用プロンプト

```
@docs/wave14_handoff.md
@docs/frozen_contract.md

# タスク: 波15 写真添付クラウド pull & 自動同期

前提:
- 波14 まで: analyze 1 info / test 12/12 / APK✓
- pullFromCloud() のテキスト記録部分は完成済み
- AmcStorageRepository.downloadToLocal() は既実装

実装手順:
1. pullFromCloud() に写真添付処理を追加
   - amc_attachments(type='IMAGE', status='READY')を取得
   - AmcStorageRepository.downloadToLocal() でローカル保存
   - photos 行を insertOrIgnore（filePath=localPath）
2. SettingsNotifier.build() で authStateProvider 変化時に自動同期
3. frozen_contract.md は変更禁止（必要なら先に合意）

完了条件:
- flutter analyze lib/ info 1件のみ
- flutter test 12/12 green
- docs/wave15_handoff.md 作成
```
