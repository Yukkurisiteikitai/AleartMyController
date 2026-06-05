import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'setup_notifier.dart';

/// オンボーディング画面（Android: SetupScreen / SetupViewModel 相当）。
///
/// completeSetup() 完了後は GoRouter の redirect が /events へ自動遷移する。
class SetupScreen extends ConsumerWidget {
  const SetupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(setupNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('セットアップ')),
      body: Center(
        child: state.isLoading || state.isSigningIn
            ? const CircularProgressIndicator()
            : Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.calendar_today, size: 64),
                    const SizedBox(height: 24),
                    const Text(
                      'AleartMyController',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Google カレンダーと連携して予定を管理しましょう。',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    if (state.error != null) ...[
                      Text(
                        'エラー: ${state.error}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                    ],
                    ElevatedButton.icon(
                      onPressed: () => ref
                          .read(setupNotifierProvider.notifier)
                          .completeSetup(),
                      icon: const Icon(Icons.login),
                      label: const Text('Google でサインインして始める'),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
