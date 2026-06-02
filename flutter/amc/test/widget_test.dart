// P0 スモークテスト: アプリが起動し、ホーム（イベント一覧）とボトムバーが描画されること。
// 各機能の本格的なテストは Wave 2 以降で features/*/ ごとに追加する。

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:amc/app.dart';

void main() {
  testWidgets('app boots to home shell with bottom bar', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: AmcApp()));
    await tester.pumpAndSettle();

    // ホーム（イベント一覧）のスタブが表示される。
    expect(find.text('EventListScreen — TODO (Wave 2: event_list)'), findsOneWidget);

    // ボトムバーの3タブ + 中央 FAB。
    expect(find.text('ホーム'), findsOneWidget);
    expect(find.text('履歴'), findsOneWidget);
    expect(find.text('分析'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsOneWidget);
  });
}
