# Flutter UIデザイン化 — マルチエージェント実装プロンプト集（波11〜13）

当初UIイメージ（`../../docs/ChatGPT_Image_202662_08_45_08.png`）を忠実再現するためのagentプロンプト集。
`agent_prompts.md`（波1〜3＝機能移植）の続編。機能・データ層は完成済みのため、**表示層だけ**を差し替える。

## 前提（現状の確定事実）

- 波1〜9で全9画面の機能・Repository・同期・worker は実装済み（`flutter analyze` 0件 / test 12/12）。
- **デザイン層は未着手**。現状は素のMaterial 3（seed `0xFF2962FF`）。
  - `app_theme.dart` はスタブ（自前コメントで明記）。
  - チャート系（fl_chart）・カレンダー系（table_calendar）パッケージ未導入。
  - 共有widgetは `empty_state_placeholder.dart` 1個のみ。アセット（マスコット等）なし。

## 当初UIイメージとの差分（リスキン対象）

| 画面 | モックの姿 | 現状 | 波12担当 |
|---|---|---|---|
| ホーム | ブランドヘッダ + ドーナツ進捗82% + マスコット + イベントカード | `AppBar('イベント一覧')` + 素のListView | ◎ |
| イベント詳細 | 進捗リング72% + タイマー43min + 大ボタン | 標準レイアウト | ◎ |
| 記録を追加 | 写真/メモタブ + カメラプレビュー + サムネ | 機能実装済（要デザイン調整） | ○ |
| 分析 | ゲージ76% + 週次棒グラフ + ヒートマップ | LinearProgressIndicator + リスト | ◎ |
| 履歴 | 月間カレンダー（ドット付き） | フラットListView | ◎ |
| 設定・連携 | Google連携カード + 「こんなことができます」紹介 | 標準トグル/Radio | ○ |

## 投げる順番（★順序厳守）

1. **波11（直列・1スレッド）**: デザイン基盤。テーマ本実装＋共有widget群＋アセット。
   最後に **DESIGN_CONTRACT**（共有widget一覧＋テーマトークン）を出力し手元保存。
2. **波12（並列・画面ごと別スレッド）**: DESIGN_CONTRACT を貼って各画面をリスキン。
   重い3画面（ホーム / 分析 / 履歴）は単独スレッド、軽い画面（設定 / イベント詳細 / 記録追加）は並べて可。
3. **波13（直列・1スレッド）**: 統合・全プラットフォーム最終検証。

> 鍵: 波2と同じく「DESIGN_CONTRACT を毎回貼る」「触っていいディレクトリを1つに限定」。
> **Notifier / Repository / data/ は読むだけ・編集禁止**。崩すと機能が壊れる。

---

## 0. 全スレッド共通ヘッダ（毎回先頭に貼る）

```
# プロジェクト前提（コールドスタート用）
- 作業対象: /Users/yuuto/learn_lab/AleartMyController/flutter/amc
- 当初UIイメージ（忠実再現の目標）: /Users/yuuto/learn_lab/AleartMyController/docs/ChatGPT_Image_202662_08_45_08.png
- 設計の正本: docs/migration_plan.md / 公開API契約: docs/frozen_contract.md
- CLAUDE.md のWeb対応ルール・パッケージ制約を厳守（新パッケージはWeb対応必須 or kIsWebガード）。
- 作業前に必ず `git status`。指示外ファイルは触らない。
- 機能ロジックは完成済み。お前の責務は「表示層のみ」。Notifier/Repository/data/ は読むだけ。
- 完了時は「触ったファイル一覧」と「凍結契約で不足した点」を必ず報告。
- 不明点を発明しない。曖昧なら止めて質問する。
```

---

## 波11（直列・1スレッド）デザイン基盤

```
[共通ヘッダを貼る]

# タスク: 波11 デザイン基盤のみ（画面リスキンはまだ行わない）
当初UIイメージ（上記PNG）を必ず最初に開いて配色・角丸・余白・要素を観察すること。

実装するもの:
1. lib/core/theme/app_theme.dart をスタブ→本実装。
   - PNG の配色をトークン化（プライマリ青系・背景オフホワイト・カード白・サクセス/警告色）。
   - CardTheme（角丸16前後・elevation低め・余白）、AppBarTheme、テキストスタイル階層。
   - light/dark 両対応。既存の seed `0xFF2962FF` を起点に PNG に寄せる。
2. pubspec.yaml に UIパッケージを追加（★Web対応バッジを pub.dev で確認してから）:
   - fl_chart（ドーナツ/ゲージ/棒グラフ）
   - table_calendar（履歴の月間カレンダー）
   ※ Web非対応のものは選ばない。代替が無ければ自前CustomPainterで実装。
3. lib/widgets/ に再利用コンポーネントを新規作成（★中身は汎用、画面ロジックは持たせない）:
   - BrandHeader（"Aleart My Controller" + サブコピー、ホーム用）
   - DonutProgress（割合 0.0〜1.0 を受け取りドーナツ＋中央%表示。fl_chart）
   - GaugeCard（半円ゲージ＋数値。分析用）
   - StatCard / FeatureCard（設定の「こんなことができます」紹介カード）
   - SectionCard（白カード共通ラッパー：角丸・余白・任意タイトル）
   - PrimaryActionButton（PNG の大型「記録する」ボタン）
4. assets/ にマスコット（PNG のおばけ風キャラ）を配置。
   - 元画像が無ければ簡易プレースホルダ（SVG or 単色シェイプ）で代替し、TODO(asset) を明記。
   - pubspec.yaml の flutter: assets: に登録。

制約:
- features/**, providers/**, data/** は読むだけ・編集禁止（widget はダミーデータで単体プレビュー）。
- build_runner は走らせない（生成コードは確定済み）。

完了条件:
- `flutter analyze lib/` クリーン / `flutter test` 12/12 green を維持。
- 各共有widgetがダミー値で描画できる（簡易プレビューScreen か widget test で確認）。
- ★最後に必須【DESIGN_CONTRACT】: 全共有widgetのコンストラクタ・引数と、
  テーマトークン（色名/役割・主要TextStyle名・角丸/余白の定数）を
  「DESIGN_CONTRACT」見出しで1ブロックに出力。これを波12の各スレッドに貼る。
```

---

## 波12（★並列・画面ごと別スレッド）画面リスキン

> 起動条件: 波11の **DESIGN_CONTRACT** を手元にコピー。各スレッドに貼る。
> 重い3つ（ホーム / 分析 / 履歴）は単独。軽い3つ（設定 / イベント詳細 / 記録追加）は並べて可。

### 機能スレッド テンプレ（下表で `{}` を埋めて複製）

```
[共通ヘッダを貼る]

# タスク: 波12 単一画面リスキンのみ ─ 担当は「{画面名}」だけ
別スレッドが他画面を並行リスキン中。責務は1画面に閉じる。
当初UIイメージ（PNG）の {画面名} 区画を目標に、見た目だけ作り替える。

使ってよいAPI（新設・変更禁止）:
----- DESIGN_CONTRACT を以下に貼る -----
{波11が出力した契約をここに貼り付け}
----------------------------------------

編集してよいファイル:
- lib/features/{dir}/{screen}.dart の build/ウィジェット部分のみ
- 必要なら同 dir 内に表示専用の小widgetファイルを追加可

読むだけ・編集禁止:
- 同 dir の *_notifier.dart（状態取得APIは変えない。ref.watch する形だけ維持）
- providers/**, data/**, lib/widgets/**（波11確定）, app_theme.dart, app_router.dart

リスキン要件(PNG準拠): {下表の「再現ポイント」を転記}

完了条件:
- `flutter analyze lib/features/{dir}` クリーン / `flutter test` 12/12 維持
- 既存ルートから到達でき、Notifier の状態（loading/error/empty/data）が全て描画される
- 触ったファイル一覧 + 「DESIGN_CONTRACT で不足した点」を報告
```

### 複製用の埋め込み表

| 画面名 | {dir} / {screen} | 再現ポイント（PNG準拠） | 重さ |
|---|---|---|---|
| ホーム | `event_list` / event_list_screen.dart | BrandHeader + サブコピー + DonutProgress(今日の達成%) + マスコット + イベントカード化（件数バッジ・進捗）+ Google未連携時のサインインカード | 単独 |
| 分析 | `analytics` / analytics_screen.dart | GaugeCard(達成%) + 週次棒グラフ(fl_chart) + 日別ヒートマップ/カレンダー風。週/月セグメントは維持 | 単独 |
| 履歴 | `history` / history_screen.dart | table_calendar の月間ビュー + 記録ある日にドット。日付タップで下に当日記録リスト | 単独 |
| 設定・連携 | `settings` / settings_screen.dart | Google連携カード（接続状態） + 「こんなことができます」FeatureCard群。トグル/Radioは維持 | 並列可 |
| イベント詳細 | `event_detail` / event_detail_screen.dart | DonutProgress/進捗リング + 経過タイマー表示 + PrimaryActionButton「記録する」 | 並列可 |
| 記録を追加 | `add_record` / add_record_screen.dart | 写真/メモのタブ整形 + カメラプレビュー枠 + サムネグリッド + 保存ボタンを PNG 調に | 並列可 |

> record_detail / setup は PNG に区画が無いため波12対象外（テーマ適用で自動追従。必要なら波13で微調整）。

---

## 波13（直列・1スレッド）統合・最終検証

```
[共通ヘッダを貼る]

# タスク: 波13 統合と最終検証（波12を全マージ後）
1. 全画面でテーマ/共有widgetが一貫しているか通し確認（record_detail/setup含む）。
2. ライト/ダーク両方、Web/Android両方で崩れがないか。kIsWeb 分岐の表示確認。
3. 当初UIイメージ（PNG）と並べて主要6画面の再現度をレビュー、差分を一覧化。
4. 全体検証: `flutter analyze lib/` 0件 / `flutter test` 12/12 / `make build-apk` / `make run-web`。
5. docs/wave13_handoff.md を作成（テンプレは CLAUDE.md 準拠）してコミット。

完了条件: 上記コマンド全成功 + PNG との残差分リスト化。
```

---

## 注意（CLAUDE.md より再掲）

- 新パッケージは pub.dev の Platforms バッジで **Web対応を確認**。非対応なら `kIsWeb` ガード。
- `frozen_contract.md` のメソッドシグネチャは変更禁止（表示層は呼ぶだけ）。
- `valueOrNull` は使わず `asData?.value`（Riverpod 3.x）。
- コミットは個別 `git add <file>`（`-A`/`.` 禁止）。doc は `docs:` プレフィックス。
