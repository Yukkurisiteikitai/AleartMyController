# AleartMyController Flutter — Claude Code ガイド

## プロジェクト概要

Android (Kotlin/Jetpack Compose) 実装を Flutter へ移管するプロジェクト。
iOS / Web 展開も対象。設計の正本は `docs/migration_plan.md`。

---

## セッション開始時に必ずやること

```bash
git status                        # 未コミット変更の確認
flutter analyze lib/              # エラーがないことを確認
flutter test                      # 12/12 green を確認
cat docs/wave5_handoff.md         # 最新の引き継ぎ資料を確認（waveN_handoff.md）
```

**重要**: 作業前に最新の引き継ぎ資料（`docs/waveN_handoff.md`）を読む。
設計の決定事項・落とし穴・残タスクが全部ここに入っている。

---

## ローカル開発環境

```bash
make gen-env        # local.properties → dart_defines.json（初回 or 変更後）
make run-web        # Web 起動（Chrome）
make run-android    # Android 起動
make build-apk      # Android debug APK ビルド
flutter test        # テスト実行
flutter analyze lib/ # 静的解析
```

`dart_defines.json` は gitignore 済み。`../../local.properties` から `SUPABASE_*` を自動抽出。

---

## 設計ドキュメント

| ファイル | 用途 |
|---|---|
| `@docs/migration_plan.md` | 設計の正本。§番号で参照される |
| `@docs/frozen_contract.md` | Repository / DAO の公開 API 契約（変更禁止） |
| `@docs/waveN_handoff.md` | 最新の引き継ぎ資料（完了状態・落とし穴・次タスク） |

コールドスタート時は必ずこの順で読む: `waveN_handoff.md` → 必要なら `migration_plan.md`。

---

## アーキテクチャ早見表

```
UI (Screen)
  ↓ ref.watch
Notifier (Riverpod)        ← 状態管理、Android ViewModel 相当
  ↓ ref.read
Repository                 ← ビジネスロジック、ローカル DB + クラウド同期
  ↓
DAO (drift)                ← ローカル SQLite
  +
Supabase Client            ← クラウド同期（supabaseClientProvider が null なら無効）
  +
Google Calendar API        ← GoogleCalendarApi wrapper
```

- `frozen_contract.md` に載っているメソッドシグネチャは変更しない
- Supabase 未初期化時は `supabaseClientProvider` が `null` を返す（クラッシュしない設計）
- Web では `kIsWeb` ガード必須の機能: 通知・workmanager・path_provider・flutter_image_compress・speech_to_text・permission_handler

---

## Web 対応ルール

```dart
// NG: Web でクラッシュする
final dir = await getApplicationDocumentsDirectory();

// OK: kIsWeb ガード付き
if (kIsWeb) {
  // TODO(web): Blob/IndexedDB 方針（後フェーズ）
  return;
}
final dir = await getApplicationDocumentsDirectory();
```

既にガード済みの機能: `workmanager` / `flutter_local_notifications` / `permission_handler`
/ `NotificationService` / `serverClientId` (GoogleSignIn) / setup redirect (GoRouter)

---

## セッション終了時に必ずやること

### 1. 検証

```bash
flutter analyze lib/      # エラー 0 件
flutter test              # 全 green
# 変更内容に応じて:
make build-apk            # Android ビルド確認
make run-web              # Web 動作確認
```

### 2. 引き継ぎ資料の作成

**タスクが完了したら `docs/waveN_handoff.md` を作成する（Nをインクリメント）。**

必須セクション:

```markdown
# 波N 引き継ぎ資料

最終更新: YYYY-MM-DD

## 現状スナップショット
（analyze / test / ビルド状態）

## 今回触ったファイル一覧
（新規作成 / 変更 それぞれテーブルで）

## 判明した落とし穴
（API 差異・ハマりポイント・回避策）

## 次のタスク（waveN+1）
（残タスク・実装済みフック・スレッドに貼るプロンプトベース）
```

### 3. コミット

```bash
git add <変更ファイル>    # -A や . は使わない（機密ファイルの誤コミット防止）
git commit -m "feat: ..."
```

---

## よくある落とし穴

| 問題 | 対処 |
|---|---|
| `String.fromEnvironment` が空 | `main.dart` に `defaultValue` 済み。`make run-*` で `--dart-define-from-file` も渡る |
| Web で setup 画面に飛ぶ | `_RouterNotifier.redirect` に `if (kIsWeb) return null` が入っている（正常） |
| テストが setup redirect で失敗 | `appLaunchProvider.overrideWith(_SetupCompleteNotifier.new)` を ProviderScope に追加 |
| APK ビルドで `checkDebugAarMetadata` 失敗 | `build.gradle.kts` に `isCoreLibraryDesugaringEnabled = true` + `desugar_jdk_libs` が必要 |
| `serverClientId is not supported on web` | `kIsWeb ? null : _googleWebClientId` で分岐 |
| `valueOrNull` が undefined (Riverpod 3.x) | `asData?.value` を使う |

---

## 新しいエージェント・セッションへの引き継ぎ方

1. `docs/waveN_handoff.md` を作成（上記テンプレート）
2. 次セッションのプロンプト冒頭に貼る:

```
@docs/waveN_handoff.md
@docs/migration_plan.md  # 必要な §番号のみ

# タスク: XXX
...
```

`@ファイルパス` でファイルをコンテキストに直接渡すと、説明なしで正確に伝わる。

---

## パッケージ制約

新しいパッケージを追加する前に確認:
- Web 対応かどうか（`pub.dev` の Platforms バッジ）
- Web 非対応なら `kIsWeb` ガードで包む
- `frozen_contract.md` で定義済みの API と競合しないか
