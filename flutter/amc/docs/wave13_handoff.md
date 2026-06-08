# 波13 引き継ぎ資料

最終更新: 2026-06-05

---

## 現状スナップショット

| 項目 | 状態 |
|---|---|
| `flutter analyze lib/` | info 1件のみ（`localeId` deprecated・既存コード） |
| `flutter test` | 12/12 green |
| `make build-apk` | ✓ `build/app/outputs/flutter-apk/app-debug.apk` |
| `flutter build web` | ✓ `build/web` |
| ブランチ | `feature/Yukkurisiteikitai/flutter_changes` |
| 最終コミット | `aeda839` feat: UX改善 — 自動同期・+ボタン記録開始・履歴タイムライン・メモ修正 |

---

## 今回触ったファイル一覧

### 波13 — 統合・最終検証（新規作成）

| ファイル | 内容 |
|---|---|
| `docs/wave13_handoff.md` | 本ファイル（統合検証完了・次タスク） |

変更ファイルなし（検証のみ）。

---

## 検証結果詳細

### flutter analyze
```
info • 'localeId' is deprecated and shouldn't be used.
  Use SpeechListenOptions.localeId instead.
  lib/features/add_record/add_record_notifier.dart:297:7 • deprecated_member_use

1 issue found.
```
→ 波12時点から変化なし。既知の 1 info のみ。

### flutter test
```
00:02 +12: All tests passed!
```

### make build-apk
```
✓ Built build/app/outputs/flutter-apk/app-debug.apk
```
警告（info のみ・破壊的変更なし）:
- KGP 適用プラグイン（flutter_image_compress_common, image_picker_android 等）— 将来の Flutter でエラー化予定。プラグイン側対応待ち。
- Swift Package Manager 非対応（workmanager_apple, flutter_image_compress_common）— 同上。

### flutter build web
```
✓ Built build/web
```
Wasm dry run 成功（`--wasm` フラグで更に最適化可能）。

---

## 判明した落とし穴

波13 では新しい落とし穴は発生しなかった。波12 までの既知事項は `wave12_handoff.md` 参照。

---

## 残っている課題

| 優先度 | 課題 | 対応方針 |
|---|---|---|
| 高 | Web↔Android Supabase データ共有 | `RecordRepository` に cloud→local pull 実装が必要（Repository 層変更） |
| 中 | マスコット実アセット | `assets/images/mascot_placeholder.png` を差し替え。`MascotWidget` を `Image.asset` に更新（TODO(asset) タグ済み） |
| 中 | Android 写真プレビュー確認 | `Image.file` 修正済み。実機再起動で表示を確認 |
| 低 | `localeId` deprecated 警告 | `add_record_notifier.dart:297` を `SpeechListenOptions.localeId` に変更 |
| 低 | Swift Package Manager 警告 | workmanager_apple / flutter_image_compress がSPM未対応。プラグイン側の対応待ち |
| 低 | KGP 適用プラグイン警告 | 将来の Flutter で build エラー化。各プラグインの新バージョン対応待ち |

---

## 次のタスク（波14）

### 優先タスク: Cloud↔Local データ同期

最も重要な未実装機能。Web でログイン・記録し、Android でも同じデータが見えるようにする。

```bash
# 実装対象
lib/data/repositories/record_repository.dart  # cloud→local pull 実装
lib/providers/settings_notifier.dart          # 同期トリガー確認
```

実装方針:
1. `RecordRepository.pullFromCloud()` メソッド追加（`frozen_contract.md` に追記してから実装）
2. Supabase の `records` / `photos` / `memos` テーブルから差分を取得
3. ローカル Drift DB に upsert（`idempotency_key` で重複防止）
4. `SettingsNotifier.syncNow()` から呼び出す

### 波14 スレッド用プロンプト

```
@docs/wave13_handoff.md
@docs/migration_plan.md
@docs/frozen_contract.md

# タスク: 波14 Cloud→Local データ同期

RecordRepository に cloud pull を実装してください。

前提:
- 波13 まで: analyze 1 info / test 12/12 / APK✓ / Web✓
- Supabase クライアントは `supabaseClientProvider`（null 時は無効、クラッシュしない設計）
- `frozen_contract.md` のメソッドシグネチャは変更前に合意を取ること

実装手順:
1. `frozen_contract.md` に `pullFromCloud()` シグネチャを追記（変更内容を報告してから実装）
2. `RecordRepository` に実装
3. `SettingsNotifier.syncNow()` から呼び出す
4. kIsWeb ガード不要（Supabase は Web 対応）

完了条件:
- `flutter analyze lib/` info 1件のみ
- `flutter test` 12/12 green
- `docs/wave14_handoff.md` 作成
```

---

## 設計メモ（次セッションへの注意点）

- `frozen_contract.md` のメソッドシグネチャは変更禁止（変更する場合は必ず先に合意）
- Riverpod 3.x では `valueOrNull` 非推奨 → `asData?.value` を使う
- `kIsWeb` ガード必須: カメラ・音声録音・`dart:io`(`Image.file`)・`path_provider`・`workmanager`・`permission_handler`
- `build_runner` は走らせない（生成コードは確定済み）
- コミットは `git add <ファイル>` 個別追加（`-A` や `.` 禁止）
- Supabase は Web・Android 両対応のため `kIsWeb` ガード不要
