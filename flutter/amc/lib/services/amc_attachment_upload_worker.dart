import 'dart:io' if (dart.library.html) '../core/_stub_io.dart';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/local/daos/amc_attachment_dao.dart';
import '../data/local/database.dart';

const _supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const _supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
const _bucket = 'amc-media';

/// Storage アップロード worker（migration_plan.md §4.2）。
///
/// PENDING / NEEDS_RETRY な添付を取得し uploadBinary → markAttachmentReady する。
/// ローカルファイル削除はここでは行わない（§9 不変条件: DB 同期後に行う）。
///
/// workmanager コールバック（別 isolate）または Web フォアグラウンドから [run] を呼ぶ。
class AmcAttachmentUploadWorker {
  const AmcAttachmentUploadWorker._();

  static Future<bool> run() async {
    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool('cloud_sync_enabled') ?? true)) return true;

    if (_supabaseUrl.isEmpty || _supabaseAnonKey.isEmpty) return true;

    final client = await _getOrInitSupabase();
    if (client.auth.currentSession == null) return false; // retry

    final userId = client.auth.currentUser!.id;
    final db = AppDatabase();
    try {
      final attachmentDao = AmcAttachmentDao(db);
      final pending = await attachmentDao.getPendingOnce();
      for (final att in pending) {
        await _upload(client, userId, attachmentDao, att);
      }
      return true;
    } finally {
      await db.close();
    }
  }

  static Future<void> _upload(
    SupabaseClient client,
    String userId,
    AmcAttachmentDao attachmentDao,
    AmcAttachment att,
  ) async {
    await attachmentDao.markUploading(att.attachmentId);
    try {
      if (kIsWeb) {
        // Web では localUri が Blob URL になるため File 経由の読み込みは不可。
        // TODO(web): IndexedDB から Blob を取得する方針（後フェーズ）。
        await attachmentDao.markFailed(att.attachmentId, errorCode: 'WEB_FILE_READ_UNSUPPORTED');
        return;
      }
      final file = File(_localPath(att.localUri));
      if (!file.existsSync()) {
        await attachmentDao.markFailed(att.attachmentId, errorCode: 'FILE_NOT_FOUND');
        return;
      }
      final bytes = Uint8List.fromList(await file.readAsBytes());
      final ext = _extFromMime(att.mimeType);
      final storagePath = '$userId/${att.draftRecordId}/${att.attachmentId}.$ext';
      await client.storage.from(_bucket).uploadBinary(
        storagePath,
        bytes,
        fileOptions: FileOptions(contentType: att.mimeType),
      );
      await attachmentDao.markReady(att.attachmentId, storagePath);
    } catch (e) {
      await attachmentDao.markNeedsRetry(att.attachmentId, errorCode: e.toString());
    }
  }

  static String _localPath(String localUri) =>
      localUri.startsWith('file://') ? localUri.substring(7) : localUri;

  static String _extFromMime(String mimeType) {
    switch (mimeType) {
      case 'audio/m4a':
        return 'm4a';
      case 'image/jpeg':
      default:
        return 'jpg';
    }
  }

  static Future<SupabaseClient> _getOrInitSupabase() async {
    if (kIsWeb) return Supabase.instance.client; // already initialized in main
    await Supabase.initialize(url: _supabaseUrl, anonKey: _supabaseAnonKey);
    return Supabase.instance.client;
  }
}
