# 波7 引き継ぎ資料（P6 E2E 完了・警告対応）

最終更新: 2026-06-05

---

## 現状スナップショット

| 項目 | 状態 |
|---|---|
| 波1〜6 (P0〜P6) | ✅ コミット済み |
| 波7 (P7 バグ修正・E2E) | ✅ 実装完了・未コミット |
| `flutter analyze lib/` | ✅ エラー 0 件 / info 8 件 |
| テスト | ✅ 12/12 green |
| Web E2E（Google Sign-In → /events） | ✅ 動作確認済み |
| Android E2E（記録追加） | ✅ 動作確認済み（Pixel 8 / Android 16） |

---

## P7 で触ったファイル一覧

### 変更
| ファイル | 変更内容 |
|---|---|
| `lib/data/repository/auth_repository.dart` | Web: `signInWithOAuth`（nonce 問題回避）/ Mobile: 既存フロー維持 |
| `lib/main.dart` | `initializeDateFormatting('ja')` 追加（LocaleData 例外修正） |
| `Makefile` | `run-android` の `-d android` → `-d 3B171FDJH0039F`（Pixel 8 device ID） |

---

## P7 で判明した落とし穴

| 問題 | 内容 | 対処 |
|---|---|---|
| **Web: nonce mismatch** | `google_sign_in_web`（GIS）が `id_token` に nonce を自動埋め込み → `signInWithIdToken` で不一致 | Web は `supabase.auth.signInWithOAuth(redirectTo: Uri.base.origin)` に切り替え |
| **Android: SHA-1 未登録** | GCP に Android OAuth クライアントがなく `SignInHubActivity` がすぐ閉じる | GCP で Android クライアント作成・SHA-1 `0D:D0:67:D1:47:C2:C2:56:1D:4C:6A:CA:52:3E:8A:45:4A:0B:56:5D` を登録 |
| **People API 未有効** | Google Sign-In 後に `SERVICE_DISABLED` エラー | GCP で People API を有効化 |
| **LocaleData 例外** | `DateFormat('M/d(E)', 'ja')` 等が初期化前に呼ばれクラッシュ | `main()` で `await initializeDateFormatting('ja')` |
| **`-d android` が通らない** | Flutter が `-d android` でデバイスを解決できない場合がある | Makefile で device ID（`3B171FDJH0039F`）を直接指定 |
| **setup フラグが先行書き込み** | sign-in 失敗でも `first_run_setup_complete` が立ち、次回起動でセットアップをスキップ | 既知の設計（§9: 失敗許容）。初回は sign-in 失敗でも `/events` に入れる。 |

---

## 次のタスク（wave8 候補）

| 優先度 | タスク |
|---|---|
| 中 | `settings_screen.dart`: `Radio` → `RadioGroup` 移行（deprecated 警告 2 件） |
| 低 | `unnecessary_underscores` info 対応（4 件） |
| 要検討 | `Makefile` の device ID をハードコードしている → `flutter devices` で動的取得に改善 |
| 要検討 | Android sign-in 後に Supabase セッションが確立されているか検証 |

---

## GCP 設定メモ（このプロジェクト）

| 種別 | クライアント ID |
|---|---|
| Web | `900637494289-fu2ut4f59boqi4a123hpmk6ujequ7a02.apps.googleusercontent.com` |
| Android (debug) | `900637494289-cgmvttu7obsva8malig7nlumfri0dsco.apps.googleusercontent.com` |

Android の SHA-1: `0D:D0:67:D1:47:C2:C2:56:1D:4C:6A:CA:52:3E:8A:45:4A:0B:56:5D`（debug keystore）

---

## wave8 スレッドに貼るプロンプトベース

```
# プロジェクト前提（コールドスタート用）
- 作業対象: /Users/yuuto/learn_lab/AleartMyController/flutter/amc
- 設計: @docs/migration_plan.md
- 引き継ぎ: @docs/wave7_handoff.md
- frozen_contract: @docs/frozen_contract.md
- 作業前に git status 確認。指示外ファイルは触らない。
- 完了時に wave8_handoff.md を作成してコミット。

# タスク: 警告対応

## 1. Radio → RadioGroup 移行
- lib/features/settings/settings_screen.dart:188 の deprecated Radio を修正

## 2. unnecessary_underscores 対応
- 該当箇所: flutter analyze lib/ で確認
```
