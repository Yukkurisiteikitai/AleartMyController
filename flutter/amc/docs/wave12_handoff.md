# 波12 引き継ぎ資料

最終更新: 2026-06-05

---

## 現状スナップショット

| 項目 | 状態 |
|---|---|
| `flutter analyze lib/` | info 1件のみ（`localeId` deprecated・既存コード） |
| `flutter test` | 未確認（波9時点では 12/12 green） |
| ブランチ | `feature/Yukkurisiteikitai/flutter_changes` |
| 最終コミット | `aeda839` feat: UX改善 — 自動同期・+ボタン記録開始・履歴タイムライン・メモ修正 |

---

## 今回触ったファイル一覧

### 波11 — デザイン基盤（新規作成）

| ファイル | 内容 |
|---|---|
| `pubspec.yaml` | `fl_chart: ^0.69.0`, `table_calendar: ^3.1.3`, `assets/images/` 追加 |
| `lib/core/theme/app_theme.dart` | AppTheme 本実装（カラー・形状・スペーシング・TextStyle・ThemeData） |
| `lib/widgets/donut_progress.dart` | fl_chart PieChart ドーナツウィジェット |
| `lib/widgets/gauge_card.dart` | 半円ゲージ（CustomPainter） |
| `lib/widgets/section_card.dart` | 白カード共通ラッパー |
| `lib/widgets/stat_card.dart` | StatCard / FeatureCard |
| `lib/widgets/primary_action_button.dart` | 全幅アクションボタン（Row 内使用禁止） |
| `lib/widgets/mascot_widget.dart` | Icons.sentiment_satisfied_alt_rounded プレースホルダー |
| `lib/widgets/brand_header.dart` | "Aleart / My Controller" ロゴヘッダー |
| `lib/widgets/feature_card_section.dart` | 「こんなことができます」3行セクション |
| `assets/images/mascot_placeholder.png` | Python生成の単色プレースホルダー PNG |

### 波12 — 全6画面リスキン（変更）

| ファイル | 主な変更 |
|---|---|
| `lib/features/event_list/event_list_screen.dart` | BrandHeader・今日のDonutProgress・今日の記録リスト・自動同期（ref.listen） |
| `lib/features/event_detail/event_detail_screen.dart` | DonutProgress進捗リング・Image.file 写真表示・PrimaryActionButton |
| `lib/features/analytics/analytics_screen.dart` | GaugeCard・fl_chart BarChart（日別カウント） |
| `lib/features/history/history_screen.dart` | table_calendar・イベント＋記録の時系列タイムライン |
| `lib/features/settings/settings_screen.dart` | Google連携カード・FeatureCardSection |
| `lib/features/add_record/add_record_screen.dart` | 写真/メモタブ・kIsWeb カメラ/音声ガード・Image.file サムネイル |
| `lib/routing/app_router.dart` | BottomAppBar+centerDocked FAB → NavigationBar（Material3）に置換 |
| `lib/providers/all_events_provider.dart` | 新規：全イベント StreamProvider（履歴画面用） |

---

## 判明した落とし穴

| 問題 | 対処 |
|---|---|
| `use_null_aware_elements` lint | `if (trailing != null) trailing!` → `?trailing`（Dart 3.7+ 構文） |
| GaugeCard BOTTOM OVERFLOW | `_GaugePainter` center を `Offset(w/2, h - strokeWidth/2)` に修正 |
| `PrimaryActionButton` を Row 内に置くと overflow | `SizedBox(width: infinity)` を持つため Row 内禁止。代わりに `FilledButton.icon` を使用 |
| `Image.asset` でファイルシステム写真が表示されない | `Image.file(File(path))` + Web では Icon プレースホルダー（kIsWeb ガード必須） |
| メモタブが `isBusy` 中に無効化されていた | `enabled: !state.isBusy && !state.isListening` → `enabled: !state.isListening` のみに変更 |
| 今日のイベントカウントが全 upcoming を表示 | `state.events` を本日日付でフィルタ |
| `RecordWithAttachments.eventId` が存在しない | `{record, photos, memos}` のみのクラス。eventとrecordの紐付けは `Record.obsEventId` → 2hop が必要。現状は時系列インターリーブで代替 |
| BottomAppBar + centerDocked FAB のレイアウトが非対称 | Material3 の `NavigationBar` に全面置換 |
| マスコットが青いグラデーション上で白飛び | `MascotWidget` をホームカードから削除。Icons.sentiment_satisfied_alt_rounded は別の場所で利用 |
| ログイン後の同期がボタン手動 | `ref.listen(settingsNotifierProvider)` で `isSignedIn: false→true` 遷移を検知し自動同期 |

---

## 次のタスク（波13）

### 波13: 統合・最終検証

```bash
flutter analyze lib/    # 1 info のみであること（localeId deprecated は既存）
flutter test            # 12/12 green を確認
make build-apk          # Android debug APK ビルド確認
make run-web            # Web 動作確認
```

### 残っている課題

| 優先度 | 課題 | 対応方針 |
|---|---|---|
| 高 | Web↔Android Supabase データ共有 | `RecordRepository` に cloud→local pull 実装が必要（Repository 層変更） |
| 中 | マスコット実アセット | `assets/images/mascot_placeholder.png` を差し替え。`MascotWidget` を `Image.asset` に更新（TODO(asset) タグ済み） |
| 中 | Android 写真プレビュー確認 | `Image.file` 修正済み。実機再起動で表示を確認 |
| 低 | `localeId` deprecated 警告 | `add_record_notifier.dart:297` を `SpeechListenOptions.localeId` に変更 |
| 低 | Swift Package Manager 警告 | workmanager_apple / flutter_image_compress がSPM未対応。プラグイン側の対応待ち |

### 波13 スレッド用プロンプト

```
@docs/wave12_handoff.md
@docs/migration_plan.md

# タスク: 波13 統合・最終検証

以下を順番に実施してください:
1. `flutter analyze lib/` — info 1件（localeId）以外のエラーがないことを確認
2. `flutter test` — 12/12 green を確認
3. `make build-apk` — Android debug APK ビルド確認
4. `make run-web` — Web 動作確認（NavigationBar・タブ切替・カレンダー）
5. 全画面を `docs/ui_agent_prompts.md` のモックアップと比較
6. `docs/wave13_handoff.md` を作成
```

---

## 設計メモ（次セッションへの注意点）

- `frozen_contract.md` のメソッドシグネチャは変更禁止（表示層は呼ぶだけ）
- Riverpod 3.x では `valueOrNull` 非推奨 → `asData?.value` を使う
- `kIsWeb` ガード必須: カメラ・音声録音・`dart:io`(`Image.file`)・`path_provider`・`workmanager`・`permission_handler`
- `build_runner` は走らせない（生成コードは確定済み）
- コミットは `git add <ファイル>` 個別追加（`-A` や `.` 禁止）
