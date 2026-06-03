import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase Storage への直接アップロード / ダウンロード（Android: AmcStorageRepository 相当）。
///
/// バケット `amc-media` は private。パス設計(§4.4):
///   {owner_user_id}/{draft_record_id}/{attachment_id}.{jpg|m4a}
class AmcStorageRepository {
  AmcStorageRepository(this._supabase);

  /// Supabase 未初期化なら null。Storage 操作を呼んだ時のみエラーにする。
  final SupabaseClient? _supabase;

  static const String _bucket = 'amc-media';

  SupabaseClient _requireClient() {
    final client = _supabase;
    if (client == null) {
      throw StateError(
        'Supabase が初期化されていません。SUPABASE_URL / SUPABASE_ANON_KEY を '
        '--dart-define で設定してください。',
      );
    }
    return client;
  }

  /// バイナリを Storage にアップロードし、保存した storagePath を返す。
  Future<String> uploadBinary({
    required String storagePath,
    required Uint8List bytes,
    required String mimeType,
  }) async {
    await _requireClient().storage.from(_bucket).uploadBinary(
          storagePath,
          bytes,
          fileOptions: FileOptions(contentType: mimeType, upsert: true),
        );
    return storagePath;
  }

  /// Storage から認証付きでダウンロードして bytes を返す。
  Future<Uint8List> downloadBytes(String storagePath) {
    return _requireClient().storage.from(_bucket).download(storagePath);
  }

  /// Storage からダウンロードして端末ローカルにファイル保存し、保存先パスを返す。
  ///
  /// TODO(P3/UI): Android は端末 Downloads(MediaStore)、iOS/Web は別保存先が望ましい。
  /// 現状はアプリのドキュメント領域に保存する暫定実装。ダウンロードボタン UI 実装時に
  /// `gal` 等でギャラリー/Downloads 保存へ差し替える(§4.5)。
  Future<String> downloadToLocal({
    required int attachmentId,
    required String storagePath,
    required String mimeType,
  }) async {
    final bytes = await downloadBytes(storagePath);
    final ext = _extensionFor(mimeType);
    final dir = await getApplicationDocumentsDirectory();
    final downloads = Directory('${dir.path}/downloads');
    if (!downloads.existsSync()) {
      downloads.createSync(recursive: true);
    }
    final file = File('${downloads.path}/amc_$attachmentId.$ext');
    await file.writeAsBytes(bytes);
    return file.path;
  }

  String _extensionFor(String mimeType) {
    final m = mimeType.toLowerCase();
    if (m.contains('jpeg') || m.contains('jpg')) return 'jpg';
    if (m.contains('png')) return 'png';
    if (m.contains('m4a') || m.contains('mp4') || m.contains('aac')) return 'm4a';
    return 'bin';
  }
}
