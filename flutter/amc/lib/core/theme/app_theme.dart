import 'package:flutter/material.dart';

/// アプリ全体の Material 3 テーマ。
///
/// Android (`ui/theme/`) のカラー/タイポ移植先。現状は seed カラーからの
/// 自動生成スタブ。Phase 後半で Android のカラートークンに合わせて拡張する。
class AppTheme {
  AppTheme._();

  // TODO(theme): Android の ui/theme/Color.kt のシードカラーに合わせる。
  static const Color _seed = Color(0xFF2962FF);

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: _seed),
      );

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _seed,
          brightness: Brightness.dark,
        ),
      );
}
