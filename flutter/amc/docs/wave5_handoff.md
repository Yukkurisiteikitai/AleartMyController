# 波5 引き継ぎ資料（P6: SetupScreen + E2E）

最終更新: 2026-06-05

---

## 現状スナップショット

| 項目 | 状態 |
|---|---|
| 波1〜4 (P0〜P4) | ✅ コミット済み (71ac38c) |
| 波5 (P5 統合・プラットフォーム) | ✅ 実装完了・未コミット（feature/Yukkurisiteikitai/flutter_changes） |
| `flutter analyze lib/` | ✅ エラー0件 / info 8件（波4から変化なし） |
| テスト | ✅ 12/12 green |
| `flutter build apk --debug` | ✅ 成功 |
| `make run-web` | ✅ 起動確認済み（Web UI 正常表示） |

---

## P5 で触ったファイル一覧

### 新規作成
| ファイル | 内容 |
|---|---|
| `Makefile` | `make run` / `make run-web` / `make build-apk` — dart_defines.json を自動生成してから flutter run |
| `dart_defines.json` | `local.properties` から自動生成（gitignore 済み）。`make gen-env` で再生成 |

### 変更
| ファイル | 変更内容 |
|---|---|
| `lib/routing/app_router.dart` | 静的クラス → `routerProvider`（Riverpod）+ `_RouterNotifier`（appLaunchProvider の redirect）。Web は `kIsWeb` で redirect スキップ |
| `lib/app.dart` | `ConsumerStatefulWidget` 化。`onNotificationTapped` stream listen（フォアグラウンド deep link）+ `getLaunchNotificationPayload`（起動時 deep link） |
| `lib/main.dart` | `SUPABASE_URL` / `SUPABASE_ANON_KEY` に `defaultValue`（anon key は公開値） |
| `lib/providers/repository_providers.dart` | `_googleWebClientId` 追加。`GoogleSignIn(serverClientId: kIsWeb ? null : _googleWebClientId)` |
| `lib/features/add_record/add_record_notifier.dart` | `_pickAndAddPhoto()` に `kIsWeb` ガード（写真未対応メッセージ）+ `startVoiceInput()` に `kIsWeb` ガード（音声未対応メッセージ） |
| `lib/features/add_record/add_record_screen.dart` | `_requestMediaPermissions()`（POST_NOTIFICATIONS / camera / microphone）を `initState` で呼ぶ（`!kIsWeb` ガード済み） |
| `lib/data/repository/amc_storage_repository.dart` | `downloadToLocal()` に `kIsWeb` ガード（`UnsupportedError` throw） |
| `lib/services/amc_attachment_upload_worker.dart` | `_upload()` 冒頭に `kIsWeb` ガード（`markFailed('WEB_FILE_READ_UNSUPPORTED')` して skip） |
| `ios/Runner/Info.plist` | NSCamera / NSMicrophone / NSPhotoLibrary UsageDescription 追加。CFBundleURLTypes（`io.supabase.amc`）追加 |
| `android/app/build.gradle.kts` | `isCoreLibraryDesugaringEnabled = true` + `desugar_jdk_libs:2.1.4`（flutter_local_notifications の要件） |
| `web/index.html` | `<meta name="google-signin-client_id">` 追加（google_sign_in_web の要件） |
| `test/widget_test.dart` | `appLaunchProvider.overrideWith(_SetupCompleteNotifier.new)` 追加（setup redirect バイパス） |
| `.gitignore` | `dart_defines.json` 追加 |

---

## P5 で判明した落とし穴

| 問題 | 内容 | 対処 |
|---|---|---|
| **setup redirect で Web UI 消失** | `appLaunchProvider` が false → 全ルートを `/setup` にリダイレクト | `_RouterNotifier.redirect` に `if (kIsWeb) return null` |
| **`serverClientId` は Web 非対応** | `google_sign_in_web` が `params.serverClientId == null` を assert | `kIsWeb ? null : _googleWebClientId` で分岐 |
| **`String.fromEnvironment` はコンパイル時定数** | `flutter run` だけでは空になる | `defaultValue` で anon key を埋め込み。`make run-web` でも `--dart-define-from-file` で上書き可 |
| **path_provider / FlutterImageCompress / SpeechToText が Web 非対応** | ランタイムクラッシュ | `_pickAndAddPhoto` / `startVoiceInput` / `downloadToLocal` / `_upload` 冒頭に `kIsWeb` ガード |
| **`flutter_local_notifications` が core library desugaring を要求** | APK ビルド失敗 | `build.gradle.kts` に `isCoreLibraryDesugaringEnabled = true` + `desugar_jdk_libs` |
| **widget_test が setup redirect でホーム画面を見つけられない** | `_RouterNotifier` が `appLaunchProvider=false` で `/setup` に飛ばす | テストで `appLaunchProvider.overrideWith(_SetupCompleteNotifier.new)` |

---

## P6 で残る作業

### 1. SetupScreen 実装（最優先）

**現状**: `lib/features/setup/setup_screen.dart` がスタブ（`'SetupScreen — TODO (Wave 2: setup)'`）

**実装済みの Notifier / Provider（使うだけでよい）:**
- `SetupNotifier` / `setupNotifierProvider` — `completeSetup()` で Google Sign-In → Supabase サインイン → フラグ書き込み
- `AppLaunchNotifier` / `appLaunchProvider` — フラグ読み込み（GoRouter redirect 用）
- `AuthRepository.signInWithSupabase()` — Google Sign-In → Supabase ID token サインイン

**やること:**
- 「始める」ボタン → `ref.read(setupNotifierProvider.notifier).completeSetup()`
- `state.isSigningIn` 中はローディング表示
- `state.error` があればエラー表示
- `state.isComplete = true` になったら GoRouter の redirect が `/events` へ自動遷移（配線済み）

```dart
// 最小実装イメージ
class SetupScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(setupNotifierProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('セットアップ')),
      body: Center(
        child: state.isLoading || state.isSigningIn
            ? const CircularProgressIndicator()
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (state.error != null) Text('エラー: ${state.error}', ...),
                  ElevatedButton(
                    onPressed: () => ref.read(setupNotifierProvider.notifier).completeSetup(),
                    child: const Text('Google でサインインして始める'),
                  ),
                ],
              ),
      ),
    );
  }
}
```

### 2. E2E 動作確認

```bash
make run-web       # Web: Google Sign-In → カレンダー同期 → イベント一覧表示
make run-android   # Android: サインイン → 写真追加 → Supabase アップロード
```

確認ポイント:
- SetupScreen でサインイン → `/events` に自動遷移
- イベント一覧同期ボタン → Google Calendar のイベントが表示
- 記録追加 → Supabase Storage にアップロードされること
- 通知タップ → `/add-record/:eventId` に遷移（Android 実機のみ）

### 3. wave6_handoff.md 作成（完了時）

---

## ローカル開発環境

```bash
# 環境変数セットアップ（初回 or local.properties 変更後）
make gen-env

# Web 起動
make run-web

# Android 起動
make run-android

# APK ビルド
make build-apk

# テスト・静的解析
flutter test
flutter analyze lib/
```

`dart_defines.json` は `local.properties`（`../../local.properties`）から自動生成。
`SUPABASE_URL` / `SUPABASE_ANON_KEY` / `SUPABASE_GOOGLE_WEB_CLIENT_ID` が含まれる。

---

## P6 スレッドに貼るプロンプトベース

```
# プロジェクト前提（コールドスタート用）
- 作業対象: /Users/yuuto/learn_lab/AleartMyController/flutter/amc
- 設計: @docs/migration_plan.md を最初に読む（§6.2 が SetupScreen 設計）
- 引き継ぎ: @docs/wave5_handoff.md（P5 完了状態・残タスク）
- frozen_contract: @docs/frozen_contract.md
- 作業前に git status 確認。指示外ファイルは触らない。
- 完了時に wave6_handoff.md を作成して「触ったファイル一覧」「計画との食い違い」を記録。

# タスク: SetupScreen 実装 + E2E 確認

## 1. SetupScreen 実装
- lib/features/setup/setup_screen.dart がスタブ → 実装する
- SetupNotifier / appLaunchProvider は実装済み（wave5_handoff.md §1 参照）
- Google Sign-In → completeSetup() → GoRouter が自動で /events にリダイレクト

## 2. E2E 動作確認
- make run-web でサインイン → カレンダー同期 → イベント一覧
- make run-android で写真追加 → Supabase アップロード確認

## 完了条件
- SetupScreen が動作し、サインイン後 /events に遷移する
- flutter analyze クリーン / テスト全 green
- wave6_handoff.md 作成
```

---

## ファイル配置（参考）

```
flutter/amc/
├── Makefile                  ← P5 新規（gen-env / run / run-web / build-apk）
├── dart_defines.json         ← gitignore・make gen-env で生成
├── lib/
│   ├── app.dart              ← P5: ConsumerStatefulWidget・deep link 配線
│   ├── main.dart             ← P5: SUPABASE_URL defaultValue
│   ├── routing/
│   │   └── app_router.dart   ← P5: routerProvider + _RouterNotifier
│   ├── providers/
│   │   └── repository_providers.dart ← P5: GoogleSignIn serverClientId 分岐
│   ├── features/
│   │   ├── setup/
│   │   │   ├── setup_screen.dart    ← P6 で実装（現状スタブ）
│   │   │   └── setup_notifier.dart  ← 実装済み
│   │   └── add_record/
│   │       ├── add_record_notifier.dart ← P5: kIsWeb ガード追加
│   │       └── add_record_screen.dart   ← P5: 権限要求追加
│   ├── data/repository/
│   │   └── amc_storage_repository.dart ← P5: downloadToLocal kIsWeb ガード
│   └── services/
│       └── amc_attachment_upload_worker.dart ← P5: _upload kIsWeb ガード
├── ios/Runner/Info.plist     ← P5: 権限文言 + Supabase URL スキーム
├── android/app/build.gradle.kts ← P5: core library desugaring
├── web/index.html            ← P5: google-signin-client_id meta タグ
└── docs/
    ├── migration_plan.md     ← 設計の正本
    ├── frozen_contract.md    ← Repository/DAO 公開 API 契約
    ├── wave4_handoff.md      ← P5 タスク定義
    └── wave5_handoff.md      ← 本ファイル（P6 引き継ぎ）
```
