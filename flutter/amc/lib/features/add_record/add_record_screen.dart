import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/theme/app_theme.dart';
import '../../data/local/daos/record_dao.dart';
import '../../data/local/tables.dart';
import 'add_record_notifier.dart';

/// 記録追加画面（Android: AddRecordScreen / AddRecordViewModel 相当）。
class AddRecordScreen extends ConsumerStatefulWidget {
  const AddRecordScreen({super.key, required this.eventId});

  final int eventId;

  @override
  ConsumerState<AddRecordScreen> createState() => _AddRecordScreenState();
}

class _AddRecordScreenState extends ConsumerState<AddRecordScreen>
    with SingleTickerProviderStateMixin {
  final _memoController = TextEditingController();
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(addRecordNotifierProvider.notifier).init(widget.eventId);
      if (!kIsWeb) _requestMediaPermissions();
    });
  }

  Future<void> _requestMediaPermissions() async {
    await [
      Permission.notification,
      Permission.camera,
      Permission.microphone,
    ].request();
  }

  @override
  void dispose() {
    _memoController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(addRecordNotifierProvider);
    final notifier = ref.read(addRecordNotifierProvider.notifier);

    ref.listen<AddRecordState>(addRecordNotifierProvider, (prev, next) {
      if (next.errorMessage != null &&
          next.errorMessage != prev?.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: '閉じる',
              onPressed: notifier.clearError,
            ),
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(
          state.event?.title ?? '記録を追加',
          overflow: TextOverflow.ellipsis,
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primary,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.textSecondary,
          tabs: const [
            Tab(icon: Icon(Icons.photo_camera_outlined), text: '写真'),
            Tab(icon: Icon(Icons.notes_outlined), text: 'メモ'),
          ],
        ),
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                // ── 写真タブ ─────────────────────────────────────────────
                _PhotoTab(state: state, notifier: notifier),
                // ── メモタブ ─────────────────────────────────────────────
                _MemoTab(
                  state: state,
                  notifier: notifier,
                  memoController: _memoController,
                ),
              ],
            ),
    );
  }
}

// ── 写真タブ ──────────────────────────────────────────────────────────────────

class _PhotoTab extends StatelessWidget {
  const _PhotoTab({required this.state, required this.notifier});

  final AddRecordState state;
  final AddRecordNotifier notifier;

  @override
  Widget build(BuildContext context) {
    final photoRecords = state.records
        .where((r) => r.record.recordType == RecordType.photo)
        .toList();

    return Column(
      children: [
        // カメラプレビューエリア
        Padding(
          padding: const EdgeInsets.all(AppTheme.spacingMd),
          child: _CameraPreviewArea(state: state, notifier: notifier),
        ),

        // サムネグリッド
        if (photoRecords.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
            child: Row(
              children: [
                Text('追加済み写真', style: AppTheme.titleMedium),
                const SizedBox(width: AppTheme.spacingSm),
                Text('${photoRecords.length} 件', style: AppTheme.labelMedium),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingMd,
                vertical: AppTheme.spacingXs,
              ),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: AppTheme.spacingSm,
                mainAxisSpacing: AppTheme.spacingSm,
              ),
              itemCount: photoRecords.length,
              itemBuilder: (context, index) {
                final reversed =
                    photoRecords[photoRecords.length - 1 - index];
                final firstPhoto = reversed.photos.isNotEmpty
                    ? reversed.photos.first
                    : null;
                return _PhotoThumbnail(
                  filePath: firstPhoto?.filePath,
                  count: reversed.photos.length,
                );
              },
            ),
          ),
        ] else
          const Expanded(child: _EmptyPhotoState()),

        const SizedBox(height: AppTheme.spacingMd),
      ],
    );
  }
}

class _CameraPreviewArea extends StatelessWidget {
  const _CameraPreviewArea({required this.state, required this.notifier});

  final AddRecordState state;
  final AddRecordNotifier notifier;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: AppTheme.textPrimary.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // カメラはWebでは非対応
          if (!kIsWeb)
            _CameraButton(
              icon: Icons.camera_alt_outlined,
              label: 'カメラで撮影',
              onPressed: state.isBusy
                  ? null
                  : () => notifier.addPhotoFromCamera(),
            ),
          if (!kIsWeb)
            Container(width: 1, height: 80, color: AppTheme.divider),
          _CameraButton(
            icon: Icons.photo_library_outlined,
            label: kIsWeb ? '画像を選択' : 'ギャラリーから',
            onPressed: state.isBusy
                ? null
                : () => notifier.addPhotoFromGallery(),
          ),
        ],
      ),
    );
  }
}

class _CameraButton extends StatelessWidget {
  const _CameraButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppTheme.primary, size: 28),
            ),
            const SizedBox(height: AppTheme.spacingSm),
            Text(label, style: AppTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _PhotoThumbnail extends StatelessWidget {
  const _PhotoThumbnail({this.filePath, required this.count});

  final String? filePath;
  final int count;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (filePath != null)
            Image.asset(
              filePath!,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                color: AppTheme.primary.withValues(alpha: 0.1),
                child: const Icon(
                  Icons.photo_outlined,
                  color: AppTheme.primary,
                ),
              ),
            )
          else
            Container(
              color: AppTheme.primary.withValues(alpha: 0.1),
              child: const Icon(
                Icons.photo_outlined,
                color: AppTheme.primary,
              ),
            ),
          if (count > 1)
            Positioned(
              bottom: 4,
              right: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '+${count - 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _EmptyPhotoState extends StatelessWidget {
  const _EmptyPhotoState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.add_photo_alternate_outlined,
            size: 48,
            color: AppTheme.primary.withValues(alpha: 0.4),
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Text('写真を追加しましょう', style: AppTheme.bodySmall),
        ],
      ),
    );
  }
}

// ── メモタブ ──────────────────────────────────────────────────────────────────

class _MemoTab extends StatelessWidget {
  const _MemoTab({
    required this.state,
    required this.notifier,
    required this.memoController,
  });

  final AddRecordState state;
  final AddRecordNotifier notifier;
  final TextEditingController memoController;

  @override
  Widget build(BuildContext context) {
    final memoRecords = state.records
        .where((r) => r.record.recordType == RecordType.memo)
        .toList();

    return Column(
      children: [
        // テキスト入力エリア
        Padding(
          padding: const EdgeInsets.all(AppTheme.spacingMd),
          child: _MemoInputArea(
            state: state,
            notifier: notifier,
            memoController: memoController,
          ),
        ),

        // メモ一覧
        if (memoRecords.isNotEmpty) ...[
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
            child: Row(
              children: [
                Text('追加済みメモ', style: AppTheme.titleMedium),
                const SizedBox(width: AppTheme.spacingSm),
                Text('${memoRecords.length} 件', style: AppTheme.labelMedium),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingMd,
                vertical: AppTheme.spacingXs,
              ),
              itemCount: memoRecords.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(height: AppTheme.spacingSm),
              itemBuilder: (context, index) {
                final item =
                    memoRecords[memoRecords.length - 1 - index];
                return _MemoItem(item: item);
              },
            ),
          ),
        ] else if (!state.isListening)
          const Expanded(child: _EmptyMemoState()),

        // 音声認識中の表示
        if (state.isListening)
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.mic, size: 48, color: AppTheme.primary),
                  const SizedBox(height: AppTheme.spacingMd),
                  Text(
                    state.voiceText.isEmpty ? '聞いています...' : state.voiceText,
                    style: AppTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),

        const SizedBox(height: AppTheme.spacingMd),
      ],
    );
  }
}

class _MemoInputArea extends StatelessWidget {
  const _MemoInputArea({
    required this.state,
    required this.notifier,
    required this.memoController,
  });

  final AddRecordState state;
  final AddRecordNotifier notifier;
  final TextEditingController memoController;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.divider),
      ),
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      child: Column(
        children: [
          TextField(
            controller: memoController,
            enabled: !state.isBusy && !state.isListening,
            maxLines: 4,
            minLines: 2,
            keyboardType: TextInputType.multiline,
            textInputAction: TextInputAction.newline,
            decoration: InputDecoration(
              hintText: state.isListening
                  ? state.voiceText.isEmpty
                      ? '音声認識中...'
                      : state.voiceText
                  : 'メモを入力',
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
          const SizedBox(height: AppTheme.spacingMd),
          Row(
            children: [
              // 音声ボタン
              OutlinedButton.icon(
                onPressed: state.isBusy
                    ? null
                    : () {
                        if (state.isListening) {
                          notifier.stopVoiceInputAndSave();
                        } else {
                          notifier.startVoiceInput();
                        }
                      },
                icon: Icon(
                  state.isListening
                      ? Icons.stop_circle_outlined
                      : Icons.mic_outlined,
                  size: 18,
                ),
                label: Text(state.isListening ? '停止して保存' : '音声メモ'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: state.isListening
                      ? Colors.red
                      : AppTheme.primary,
                  side: BorderSide(
                    color: state.isListening ? Colors.red : AppTheme.primary,
                  ),
                ),
              ),
              if (state.isListening) ...[
                const SizedBox(width: AppTheme.spacingSm),
                TextButton(
                  onPressed: notifier.cancelVoiceInput,
                  child: const Text('キャンセル'),
                ),
              ],
              const Spacer(),
              // 送信ボタン（Rowの中に収まるコンパクトサイズ）
              FilledButton.icon(
                onPressed: (state.isBusy || state.isListening)
                    ? null
                    : () {
                        final text = memoController.text;
                        if (text.trim().isEmpty) return;
                        notifier.addTextMemo(text);
                        memoController.clear();
                      },
                icon: state.isBusy
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send_rounded, size: 18),
                label: const Text('保存'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  minimumSize: const Size(0, 44),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MemoItem extends StatelessWidget {
  const _MemoItem({required this.item});

  final RecordWithAttachments item;

  @override
  Widget build(BuildContext context) {
    final isVoice =
        item.memos.isNotEmpty && item.memos.first.isVoiceMemo;
    final text = item.memos.isNotEmpty ? item.memos.first.memoText : '';
    final timeLabel = DateFormat('HH:mm').format(
      DateTime.fromMillisecondsSinceEpoch(item.record.recordTime),
    );

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.divider),
      ),
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isVoice ? Icons.mic : Icons.notes_outlined,
            size: 16,
            color: AppTheme.primary,
          ),
          const SizedBox(width: AppTheme.spacingSm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.bodyMedium,
                ),
                const SizedBox(height: 2),
                Text(timeLabel, style: AppTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyMemoState extends StatelessWidget {
  const _EmptyMemoState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.note_add_outlined,
            size: 48,
            color: AppTheme.primary.withValues(alpha: 0.4),
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Text('メモを追加しましょう', style: AppTheme.bodySmall),
          const SizedBox(height: 4),
          Text(
            'テキストまたは音声で記録できます',
            style: AppTheme.bodySmall.copyWith(fontSize: 11),
          ),
        ],
      ),
    );
  }
}
