import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'settings_notifier.dart';

/// 設定画面（Android: SettingsScreen / SettingsViewModel 相当）。
///
/// - インターバル / 通知 ON-OFF / Supabase サインイン再試行 / クラウド同期トグル /
///   ローカルキュー要約を実装する（migration_plan.md §6.2 / §9）。
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(settingsNotifierProvider);
    final notifier = ref.read(settingsNotifierProvider.notifier);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('設定')),
      body: ListView(
        children: [
          // ---------------------------------------------------------------
          // Supabase 認証セクション
          // ---------------------------------------------------------------
          _SectionHeader(title: 'クラウド認証'),
          if (!state.isSignedIn) ...[
            ListTile(
              leading: const Icon(Icons.cloud_off, color: Colors.orange),
              title: const Text('Supabase 未サインイン'),
              subtitle: const Text('クラウド同期を使うにはサインインが必要です。'),
            ),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: FilledButton.icon(
                onPressed:
                    state.isSigningIn ? null : () => notifier.retrySignIn(),
                icon: state.isSigningIn
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.login),
                label:
                    Text(state.isSigningIn ? 'サインイン中…' : 'Google でサインイン'),
              ),
            ),
            if (state.signInError != null)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Text(
                  'エラー: ${state.signInError}',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.error),
                ),
              ),
          ] else ...[
            ListTile(
              leading: const Icon(Icons.cloud_done, color: Colors.green),
              title: const Text('Supabase サインイン済み'),
            ),
          ],
          const Divider(),

          // ---------------------------------------------------------------
          // クラウド同期トグル（§9: shared_preferences で永続化）
          // ---------------------------------------------------------------
          _SectionHeader(title: 'クラウド同期'),
          SwitchListTile(
            secondary: const Icon(Icons.sync),
            title: const Text('クラウド同期を有効にする'),
            subtitle: const Text(
                'OFF にすると写真・メモはローカルにのみ保存されます。'),
            value: state.cloudSyncEnabled,
            onChanged: (v) => notifier.setCloudSyncEnabled(v),
          ),
          const Divider(),

          // ---------------------------------------------------------------
          // ローカルキュー要約（未同期件数）
          // ---------------------------------------------------------------
          _SectionHeader(title: 'ローカルキュー'),
          ListTile(
            leading: const Icon(Icons.pending_actions),
            title: const Text('未同期の記録'),
            trailing: Text(
              '${state.unsyncedCount} 件',
              style: theme.textTheme.bodyLarge,
            ),
            subtitle: state.unsyncedCount > 0
                ? const Text('クラウド同期が有効になると自動的に送信されます。')
                : const Text('すべて同期済みです。'),
          ),
          const Divider(),

          // ---------------------------------------------------------------
          // 通知
          // ---------------------------------------------------------------
          _SectionHeader(title: '通知'),
          SwitchListTile(
            secondary: const Icon(Icons.notifications),
            title: const Text('リマインダー通知'),
            subtitle: const Text('進行中のイベントがあるときに通知します。'),
            value: state.notificationsEnabled,
            onChanged: (v) => notifier.setNotificationsEnabled(v),
          ),
          const Divider(),

          // ---------------------------------------------------------------
          // インターバル
          // ---------------------------------------------------------------
          _SectionHeader(title: '記録インターバル'),
          _IntervalSelector(
            currentMinutes: state.intervalMinutes,
            presetOrder: state.presetOrder,
            onChanged: notifier.setIntervalMinutes,
          ),
          const Divider(),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Helper widgets
// ---------------------------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }
}

/// インターバル選択（プリセット + カスタム）。
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
            title: Text(label),
            value: minutes,
          );
        }).toList(),
      ),
    );
  }
}
