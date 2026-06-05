import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../widgets/feature_card_section.dart';
import '../../widgets/section_card.dart';
import '../../core/theme/app_theme.dart';
import 'settings_notifier.dart';

/// 設定画面（Android: SettingsScreen / SettingsViewModel 相当）。
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(settingsNotifierProvider);
    final notifier = ref.read(settingsNotifierProvider.notifier);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('設定・連携')),
      body: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingMd,
          vertical: AppTheme.spacingMd,
        ),
        children: [
          // ── Google 連携カード ────────────────────────────────────────────
          _GoogleConnectionCard(state: state, notifier: notifier),
          const SizedBox(height: AppTheme.spacingMd),

          // ── こんなことができます ─────────────────────────────────────────
          const FeatureCardSection(),
          const SizedBox(height: AppTheme.spacingMd),

          // ── クラウド同期 ─────────────────────────────────────────────────
          SectionCard(
            title: 'クラウド同期',
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              secondary: const Icon(Icons.sync, color: AppTheme.primary),
              title: const Text('クラウド同期を有効にする'),
              subtitle: const Text('OFF にすると写真・メモはローカルにのみ保存されます。'),
              value: state.cloudSyncEnabled,
              onChanged: (v) => notifier.setCloudSyncEnabled(v),
            ),
          ),
          const SizedBox(height: AppTheme.spacingMd),

          // ── 未同期件数 ──────────────────────────────────────────────────
          SectionCard(
            title: 'ローカルキュー',
            child: Row(
              children: [
                const Icon(Icons.pending_actions, color: AppTheme.textSecondary),
                const SizedBox(width: AppTheme.spacingMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('未同期の記録'),
                      const SizedBox(height: 2),
                      Text(
                        state.unsyncedCount > 0
                            ? 'クラウド同期が有効になると自動的に送信されます。'
                            : 'すべて同期済みです。',
                        style: AppTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Text(
                  '${state.unsyncedCount} 件',
                  style: AppTheme.titleMedium.copyWith(
                    color: state.unsyncedCount > 0
                        ? AppTheme.warning
                        : AppTheme.success,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spacingMd),

          // ── 通知 ────────────────────────────────────────────────────────
          SectionCard(
            title: '通知',
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              secondary:
                  const Icon(Icons.notifications, color: AppTheme.primary),
              title: const Text('リマインダー通知'),
              subtitle: const Text('進行中のイベントがあるときに通知します。'),
              value: state.notificationsEnabled,
              onChanged: (v) => notifier.setNotificationsEnabled(v),
            ),
          ),
          const SizedBox(height: AppTheme.spacingMd),

          // ── 記録インターバル ─────────────────────────────────────────────
          SectionCard(
            title: '記録インターバル',
            child: _IntervalSelector(
              currentMinutes: state.intervalMinutes,
              presetOrder: state.presetOrder,
              onChanged: notifier.setIntervalMinutes,
            ),
          ),
          const SizedBox(height: AppTheme.spacingLg),
        ],
      ),
    );
  }
}

// ── Google 連携カード ──────────────────────────────────────────────────────────

class _GoogleConnectionCard extends StatelessWidget {
  const _GoogleConnectionCard({
    required this.state,
    required this.notifier,
  });

  final SettingsState state;
  final SettingsNotifier notifier;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: state.isSignedIn
            ? AppTheme.success.withValues(alpha: 0.08)
            : AppTheme.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(
          color: state.isSignedIn
              ? AppTheme.success.withValues(alpha: 0.3)
              : AppTheme.divider,
        ),
      ),
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(color: AppTheme.divider),
            ),
            child: Icon(
              Icons.account_circle_rounded,
              color: state.isSignedIn ? AppTheme.success : AppTheme.textSecondary,
              size: 28,
            ),
          ),
          const SizedBox(width: AppTheme.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Google 連携',
                  style: AppTheme.titleMedium,
                ),
                const SizedBox(height: 2),
                Text(
                  state.isSignedIn
                      ? 'カレンダーと同期中'
                      : 'サインインしてカレンダーを同期',
                  style: AppTheme.bodySmall,
                ),
                if (state.signInError != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    state.signInError!,
                    style: AppTheme.bodySmall.copyWith(color: Colors.red),
                  ),
                ],
              ],
            ),
          ),
          if (!state.isSignedIn)
            FilledButton(
              onPressed:
                  state.isSigningIn ? null : () => notifier.retrySignIn(),
              style: FilledButton.styleFrom(
                minimumSize: const Size(72, 36),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                textStyle: const TextStyle(fontSize: 13),
              ),
              child: state.isSigningIn
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('接続'),
            )
          else
            Icon(
              Icons.check_circle_rounded,
              color: AppTheme.success,
              size: 28,
            ),
        ],
      ),
    );
  }
}

// ── インターバルセレクタ ────────────────────────────────────────────────────────

class _IntervalSelector extends StatelessWidget {
  const _IntervalSelector({
    required this.currentMinutes,
    required this.presetOrder,
    required this.onChanged,
  });

  final int currentMinutes;
  final String presetOrder;
  final void Function(int) onChanged;

  static const _labels = {
    0: 'カスタム',
    1: '1 分',
    3: '3 分',
    5: '5 分',
    10: '10 分',
    25: '25 分',
    30: '30 分',
    60: '60 分',
  };

  @override
  Widget build(BuildContext context) {
    final presets = presetOrder
        .split(',')
        .map(int.tryParse)
        .whereType<int>()
        .toList();

    return RadioGroup<int>(
      groupValue: currentMinutes,
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: presets.map((minutes) {
          final label = _labels[minutes] ?? '$minutes 分';
          return RadioListTile<int>(
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: Text(label),
            value: minutes,
          );
        }).toList(),
      ),
    );
  }
}
