# 波4 引き継ぎ資料（P5）

最終更新: 2026-06-03

---

## 現状スナップショット

| 項目 | 状態 |
|---|---|
| 波1 (P0/P1/P2) | ✅ コミット済み (fead013) |
| 波2 (9画面) | ✅ コミット済み (fead013) |
| 波3 P4 (worker 層) | ✅ 実装完了・analyze クリーン |
| `flutter analyze lib/` | ✅ エラー0件 / info 8件のみ（波2 から変化なし） |
| テスト | ✅ 12/12 green |

---

## P4 で触ったファイル一覧

### 新規作成
| ファイル | 内容 |
|---|---|
| `lib/core/_stub_io.dart` | `dart:io` Web 用スタブ（条件付きインポート用） |
| `lib/data/remote/supabase/amc_dto.dart` | `AmcRecordInsertDto` / `AmcRecordPatchDto` / `AmcRevisionInsertDto` / `AmcAttachmentInsertDto` |
| `lib/data/preferences/app_preferences.dart` | `AppPreferences` 静的アクセサ（worker isolate から呼べる） |
| `lib/services/notification_service.dart` | `flutter_local_notifications` ラッパ、チャンネル `observation_reminders` |
| `lib/services/amc_attachment_upload_worker.dart` | Storage アップロード worker（PENDING→READY、ローカル削除なし） |
| `lib/services/amc_record_sync_worker.dart` | DB 同期 worker（§4.3 順序厳守） |
| `lib/services/reminder_worker.dart` | 15 分周期リマインダー + `registerPeriodicTask()` |
| `lib/services/amc_work_scheduler_impl.dart` | `WorkmanagerAmcWorkScheduler`（Noop の置き換え） |

### 変更
| ファイル | 変更内容 |
|---|---|
| `lib/providers/repository_providers.dart` | `amcWorkSchedulerProvider` を `WorkmanagerAmcWorkScheduler` に差し替え |
| `lib/main.dart` | `callbackDispatcher` 追加、`NotificationService.initialize()` / `Workmanager().initialize()` / `ReminderWorker.registerPeriodicTask()` を `!kIsWeb` ガードで追加 |

---

## P4 で判明した API の差異（frozen_contract との食い違い）

| 項目 | frozen_contract / 設計書の記述 | 実際 |
|---|---|---|
| `flutter_local_notifications` v21 | 設計書に API バージョン指定なし | `initialize()` / `show()` が全引数名前付き（`settings:` / `id:` 等）に変更 |
| `workmanager` 周期タスク | `ExistingWorkPolicy` で統一 | 周期タスクは `ExistingPeriodicWorkPolicy` を使う（型が別） |
| `Workmanager().initialize()` | `isInDebugMode` パラメータあり | deprecated → 引数なしが正しい |

---

## P5 で残る作業

### 1. deep link 配線（通知タップ → `/add-record/:eventId`）

**実装済みフック（P4 で用意）:**
- `NotificationService.onNotificationTapped` — フォアグラウンドタップ時の `Stream<String>`（payload = eventId）
- `NotificationService.getLaunchNotificationPayload()` — バックグラウンド/killed 状態からの起動時に payload を返す

**やること:**
- `setup_notifier.dart` にある `appLaunchProvider` を確認し、`getLaunchNotificationPayload()` を結線する
- `app_router.dart` の redirect ロジックに `appLaunchProvider` を接続する
- アプリ起動中（フォアグラウンド）は `NotificationService.onNotificationTapped` を listen して `context.go('/add-record/$eventId')` する

**ルート定義（既存）:**
```
/add-record/:eventId  →  AddRecordScreen(eventId: int)
```

### 2. iOS 権限（`ios/Runner/Info.plist`）

追加が必要な権限文言:
```xml
<key>NSCameraUsageDescription</key>
<string>イベントの証拠写真を撮影するために使用します。</string>
<key>NSMicrophoneUsageDescription</key>
<string>音声メモを録音するために使用します。</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>写真ライブラリから画像を選択するために使用します。</string>
<!-- 通知権限は flutter_local_notifications が実行時に要求するため plist 不要 -->
```

Supabase OAuth リダイレクト URL 設定:
```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>io.supabase.amc</string>  <!-- Supabase Dashboard の設定値に合わせる -->
    </array>
  </dict>
</array>
```

### 3. Android 権限要求 UI（`permission_handler`）

`POST_NOTIFICATIONS`（Android 13+）とカメラ・マイク権限を UI 導線で要求する。
SetupScreen または AddRecordScreen の初回起動時に実装する。

```dart
import 'package:permission_handler/permission_handler.dart';

// 通知権限
await Permission.notification.request();
// カメラ
await Permission.camera.request();
// マイク
await Permission.microphone.request();
```

### 4. Web フォールバック確認（§8）

- 通知・定期バックグラウンド: `kIsWeb` ガード済み（P4 で実装）→ 動作確認のみ
- 写真パス: Web では `File` 経由のローカルパスが使えない → Blob 方針の TODO を明記（`camera_service.dart` か `add_record_notifier.dart` に `// TODO(web): Blob/IndexedDB 方針は後フェーズ` コメントを追記）

### 5. 最終検証コマンド

```bash
flutter analyze           # エラー0件を確認
flutter test              # 12/12 green を確認
flutter build apk --debug # Android ビルド成功
flutter run -d chrome     # Web 動作確認（通知・workmanager は無効化済みで起動すること）
```

---

## P4 で学んだ落とし穴

| 問題 | 内容 | 対処 |
|---|---|---|
| **flutter_local_notifications v21 API 破壊的変更** | `initialize(settings:)` / `show(id:, title:, body:, notificationDetails:)` が全部名前付き引数に変更 | 公式 pub.dev の最新 API を確認してから実装する |
| **workmanager 周期タスクの型** | `registerPeriodicTask` の `existingWorkPolicy` は `ExistingPeriodicWorkPolicy`（一回タスクとは別型） | ワンショットは `ExistingWorkPolicy`、周期は `ExistingPeriodicWorkPolicy` |
| **workmanager `isInDebugMode` deprecated** | 0.9.x で deprecated、引数なし `initialize(callbackDispatcher)` が正しい | 引数を省略する |
| **worker isolate の Supabase 初期化** | Web は `kIsWeb` → `Supabase.instance.client`（main で初期化済）、native は worker isolate が fresh → `await Supabase.initialize()` を毎回呼ぶ | `kIsWeb` 分岐で `_getOrInitSupabase()` を統一 |
| **dart:io 条件付きインポート** | Worker ファイルに `dart:io` を使うと Web ビルドで失敗 | `import 'dart:io' if (dart.library.html) '../core/_stub_io.dart'` で解決 |

---

## P5 スレッドに貼るプロンプトベース

```
# プロジェクト前提（コールドスタート用）
- 作業対象: /Users/yuuto/learn_lab/AleartMyController/flutter/amc
- 設計: flutter/amc/docs/migration_plan.md を必ず最初に読む（§8, §10）
- 引き継ぎ: flutter/amc/docs/wave4_handoff.md（P4 完了状態・残タスク）
- frozen_contract: flutter/amc/docs/frozen_contract.md
- 作業前に git status 確認。指示外ファイルは触らない。
- 完了時に「触ったファイル一覧」「計画との食い違い」を報告。

# タスク: Phase 5 統合・プラットフォーム・最終検証

P4 完了後に着手。analyze クリーン・テスト 12/12 green の状態から開始。

## 1. deep link 配線（最優先）
- `NotificationService.getLaunchNotificationPayload()` を main.dart または appLaunchProvider に結線
- `NotificationService.onNotificationTapped`（Stream<String>）を listen して go_router で
  `/add-record/:eventId` にナビゲートする
- setup_notifier.dart の `appLaunchProvider` を確認して組み込む

## 2. iOS Info.plist
- カメラ・マイク・写真ライブラリの NSUsageDescription を追加
- Supabase OAuth リダイレクト URL（CFBundleURLTypes）を設定

## 3. Android 権限 UI
- `permission_handler` で POST_NOTIFICATIONS・カメラ・マイクを要求する画面導線を追加
  （SetupScreen または AddRecordScreen 初回起動時が適切）

## 4. Web TODO コメント追加
- `camera_service.dart` か `add_record_notifier.dart` に
  `// TODO(web): 写真パスは Blob/IndexedDB 方針（後フェーズ）` を追記

## 5. 最終検証
flutter analyze           # エラー0件
flutter test              # 全 green
flutter build apk --debug # ビルド成功
flutter run -d chrome     # Web 動作確認

完了条件:
- deep link が動作する（通知タップ → AddRecordScreen に遷移）
- iOS plist に権限文言が追加されている
- Android 権限要求 UI が追加されている
- flutter analyze クリーン / テスト全 green / apk ビルド成功
- 触ったファイル一覧 + 計画との食い違いを報告
```

---

## ファイル配置（参考）

```
flutter/amc/
├── lib/
│   ├── core/
│   │   └── _stub_io.dart       ← P4 追加（dart:io スタブ）
│   ├── data/
│   │   ├── preferences/
│   │   │   └── app_preferences.dart  ← P4 実装完了
│   │   ├── remote/supabase/
│   │   │   └── amc_dto.dart          ← P4 実装完了
│   │   └── repository/
│   │       └── amc_work_scheduler.dart ← NoopAmcWorkScheduler は残存（参照のみ）
│   ├── features/          ← 波2完了 (9画面)
│   ├── providers/
│   │   └── repository_providers.dart ← P4 で WorkmanagerAmcWorkScheduler に差し替え済み
│   ├── services/
│   │   ├── notification_service.dart         ← P4 実装完了
│   │   ├── amc_attachment_upload_worker.dart ← P4 実装完了
│   │   ├── amc_record_sync_worker.dart       ← P4 実装完了
│   │   ├── reminder_worker.dart              ← P4 実装完了
│   │   └── amc_work_scheduler_impl.dart      ← P4 新規（WorkmanagerAmcWorkScheduler）
│   ├── routing/app_router.dart ← P5 で deep link redirect 追加
│   └── main.dart               ← P4 でワーカー配線済み
├── ios/Runner/Info.plist       ← P5 で権限追加
└── docs/
    ├── migration_plan.md       ← 設計の正本（§8, §10 が P5 対象）
    ├── frozen_contract.md      ← Repository/DAO 公開API契約
    ├── wave3_handoff.md        ← P4/P5 のタスク定義
    └── wave4_handoff.md        ← 本ファイル（P5 引き継ぎ）
```
