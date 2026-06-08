# 波6 引き継ぎ資料（P6: SetupScreen 実装）

最終更新: 2026-06-05

---

## 現状スナップショット

| 項目 | 状態 |
|---|---|
| 波1〜5 (P0〜P5) | ✅ コミット済み (6dda3ec) |
| 波6 (P6 SetupScreen) | ✅ コミット済み (7086462) |
| `flutter analyze lib/` | ✅ エラー 0 件 / info 8 件（変化なし） |
| テスト | ✅ 12/12 green |

---

## P6 で触ったファイル一覧

### 変更
| ファイル | 変更内容 |
|---|---|
| `lib/features/setup/setup_screen.dart` | スタブ → `ConsumerWidget` 実装。ローディング表示・エラー表示・サインインボタン |

### 新規作成（P5 未コミット分を同セッションでコミット）
| ファイル | 内容 |
|---|---|
| `CLAUDE.md` | プロジェクトガイド（セッション開始/終了手順・アーキテクチャ早見表） |
| `Makefile` | `gen-env` / `run-web` / `run-android` / `build-apk` |
| `docs/wave5_handoff.md` | P5 完了状態・落とし穴・P6 タスク定義 |

---

## SetupScreen の実装詳細

```
SetupScreen (ConsumerWidget)
  ↓ ref.watch
setupNotifierProvider (SetupState)
  ├── isLoading / isSigningIn → CircularProgressIndicator
  ├── error → エラーテキスト表示
  └── ボタン → ref.read(setupNotifierProvider.notifier).completeSetup()
                  → GoRouter の _RouterNotifier が isComplete を検知 → /events へ自動遷移
```

---

## 計画との食い違い

なし。wave5_handoff.md §1 の最小実装イメージどおりに実装した。

---

## E2E 確認状況

| 確認項目 | 状態 |
|---|---|
| `flutter analyze` クリーン | ✅ |
| `flutter test` 12/12 green | ✅ |
| Web 実機サインイン → /events 遷移 | 未確認（実機・Supabase 資格情報が必要） |
| Android 実機サインイン → 写真追加 | 未確認（実機が必要） |

実機 E2E は `make run-web` / `make run-android` で確認可能。
事前に `make gen-env`（`../../local.properties` に `SUPABASE_*` が必要）。

---

## 次のタスク（wave7 候補）

| 優先度 | タスク |
|---|---|
| 高 | 実機 E2E（Web: Google Sign-In → /events）|
| 高 | 実機 E2E（Android: 写真追加 → Supabase アップロード）|
| 中 | `settings_screen.dart` の `Radio` deprecated 警告対応（RadioGroup 移行） |
| 低 | `unnecessary_underscores` info 対応 |

---

## ローカル開発環境

```bash
make gen-env        # local.properties → dart_defines.json
make run-web        # Web 起動
make run-android    # Android 起動
make build-apk      # APK ビルド
flutter test
flutter analyze lib/
```

---

## wave7 スレッドに貼るプロンプトベース

```
# プロジェクト前提（コールドスタート用）
- 作業対象: /Users/yuuto/learn_lab/AleartMyController/flutter/amc
- 設計: @docs/migration_plan.md
- 引き継ぎ: @docs/wave6_handoff.md
- frozen_contract: @docs/frozen_contract.md
- 作業前に git status 確認。指示外ファイルは触らない。
- 完了時に wave7_handoff.md を作成。

# タスク: E2E 動作確認 + 警告対応

## 1. E2E 確認
- make run-web: Google Sign-In → /events 遷移
- make run-android: 写真追加 → Supabase アップロード

## 2. deprecated 警告対応（任意）
- settings_screen.dart: Radio → RadioGroup 移行
```
