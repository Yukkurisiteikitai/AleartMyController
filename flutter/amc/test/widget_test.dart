// アプリ起動スモークテスト: ホームシェル（ボトムバー3タブ + 中央FAB）が描画されること。
//
// Wave 2 実装後の注意:
// - ホームは実画面(event_list, DB依存) → appDatabaseProvider を in-memory DB に override。
// - Supabase 未初期化でも supabaseClientProvider は null を返すのでクラッシュしない。
// - シェルは IndexedStack で history/analytics も同時 mount し、両画面はロード中に
//   CircularProgressIndicator を出す。pumpAndSettle はこのアニメで止まらないため使わず、
//   pump() で1フレームだけ描画して shell の存在を検証する。

import 'package:amc/app.dart';
import 'package:amc/data/local/database.dart';
import 'package:amc/features/setup/setup_notifier.dart';
import 'package:amc/providers/database_providers.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// セットアップ完了済みを返すスタブ（テスト用）。
class _SetupCompleteNotifier extends AppLaunchNotifier {
  @override
  Future<bool> build() async => true;
}

void main() {
  testWidgets(
    'app boots to home shell with bottom bar',
    (tester) async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            // セットアップ完了済みとして router の /setup リダイレクトを回避する。
            appLaunchProvider.overrideWith(_SetupCompleteNotifier.new),
          ],
          child: const AmcApp(),
        ),
      );
      // 1フレーム描画 + 非同期ロードを少し進める（pumpAndSettle は spinner で止まらない）。
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // ボトムバーの3タブ + 中央 FAB（app_router の shell が描画されている）。
      expect(find.text('ホーム'), findsOneWidget);
      expect(find.text('履歴'), findsOneWidget);
      expect(find.text('分析'), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsOneWidget);

      // drift は stream 購読解除時に Timer(Duration.zero) でクリーンアップを遅延する
      // （mount 中の各 watch 分）。ツリーを明示破棄 → pumpAndSettle で全 Timer/microtask を
      // 排出し、「pending timer」リーク判定を回避する（アプリ側のバグではない）。
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    },
    timeout: const Timeout(Duration(seconds: 30)),
  );
}
