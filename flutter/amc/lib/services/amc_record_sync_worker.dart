import 'dart:io' if (dart.library.html) '../core/_stub_io.dart';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/local/daos/amc_attachment_dao.dart';
import '../data/local/daos/amc_draft_dao.dart';
import '../data/local/database.dart';
import '../data/remote/supabase/amc_dto.dart';

const _supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const _supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

/// DB 同期 worker（migration_plan.md §4.3）。
///
/// 不変条件（§9 厳守）:
///   1. amc_records upsert → remoteRecordId 確定
///   2. amc_record_revisions insert（idempotency_key で冪等）→ current_revision_id PATCH
///   3. READY な添付を amc_attachments に insert（remoteRecordId 確定後のみ）
///   4. ローカルファイル削除（cloud_sync_enabled=true かつ非 Web のとき）
///   5. markRecordSynced
class AmcRecordSyncWorker {
  const AmcRecordSyncWorker._();

  static Future<bool> run() async {
    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool('cloud_sync_enabled') ?? true)) return true;

    if (_supabaseUrl.isEmpty || _supabaseAnonKey.isEmpty) return true;

    final client = await _getOrInitSupabase();
    if (client.auth.currentSession == null) return false; // retry

    final userId = client.auth.currentUser!.id;
    final db = AppDatabase();
    try {
      final draftDao = AmcDraftDao(db);
      final attachmentDao = AmcAttachmentDao(db);
      final drafts = await draftDao.getPendingSyncOnce();
      for (final draft in drafts) {
        try {
          await _syncDraft(client, userId, draftDao, attachmentDao, draft);
        } catch (_) {
          await draftDao.markFailed(draft.draftRecordId);
        }
      }
      return true;
    } finally {
      await db.close();
    }
  }

  static Future<void> _syncDraft(
    SupabaseClient client,
    String userId,
    AmcDraftDao draftDao,
    AmcAttachmentDao attachmentDao,
    AmcDraftRecord draft,
  ) async {
    // Step 1: upsert amc_records → remoteRecordId 確定
    final String remoteRecordId;
    if (draft.remoteRecordId == null) {
      final row = await client
          .from('amc_records')
          .insert(AmcRecordInsertDto(
            ownerUserId: userId,
            currentBody: draft.currentBody,
            visibility: draft.visibility,
          ).toJson())
          .select('id')
          .single();
      remoteRecordId = row['id'] as String;
      await draftDao.setRemoteRecordId(draft.draftRecordId, remoteRecordId);
    } else {
      remoteRecordId = draft.remoteRecordId!;
      await client
          .from('amc_records')
          .update(AmcRecordPatchDto(
            currentBody: draft.currentBody,
            visibility: draft.visibility,
          ).toJson())
          .eq('id', remoteRecordId);
    }

    // Step 2: insert latest revision + patch current_revision_id
    String? newRevisionId;
    final latestRevision =
        await draftDao.findLatestRevisionForDraft(draft.draftRecordId);
    if (latestRevision != null) {
      if (latestRevision.remoteRevisionId == null) {
        final revRow = await client
            .from('amc_record_revisions')
            .insert(AmcRevisionInsertDto(
              recordId: remoteRecordId,
              body: latestRevision.body,
              idempotencyKey: latestRevision.idempotencyKey,
            ).toJson())
            .select('id')
            .single();
        newRevisionId = revRow['id'] as String;
        await draftDao.setRevisionRemoteId(
            latestRevision.revisionLocalId, newRevisionId);
      } else {
        newRevisionId = latestRevision.remoteRevisionId;
      }
      // Patch current_revision_id on amc_records
      await client
          .from('amc_records')
          .update(AmcRecordPatchDto(
            currentBody: draft.currentBody,
            visibility: draft.visibility,
            currentRevisionId: newRevisionId,
          ).toJson())
          .eq('id', remoteRecordId);
    }

    // Step 3: insert READY attachments (remoteRecordId 確定後のみ – §9 不変条件)
    final readyAttachments =
        await attachmentDao.getReadyByDraftId(draft.draftRecordId);
    final toDelete = <String>[];
    for (final att in readyAttachments) {
      if (att.storagePath == null) continue;
      final attRow = await client
          .from('amc_attachments')
          .insert(AmcAttachmentInsertDto(
            recordId: remoteRecordId,
            storagePath: att.storagePath!,
            mimeType: att.mimeType,
            checksum: att.checksum,
          ).toJson())
          .select('id')
          .single();
      await attachmentDao.setRemoteAttachmentId(
          att.attachmentId, attRow['id'] as String);
      toDelete.add(att.localUri);
    }

    // Step 4: ローカルファイル削除（DB insert 確認後、非 Web のみ – §9 不変条件）
    if (!kIsWeb) {
      for (final uri in toDelete) {
        try {
          final path = uri.startsWith('file://') ? uri.substring(7) : uri;
          await File(path).delete();
        } catch (_) {}
      }
    }

    // Step 5: markRecordSynced
    await draftDao.markSynced(
      draft.draftRecordId,
      remoteRecordId: remoteRecordId,
      currentRevisionId: newRevisionId,
    );
  }

  static Future<SupabaseClient> _getOrInitSupabase() async {
    if (kIsWeb) return Supabase.instance.client; // already initialized in main
    await Supabase.initialize(url: _supabaseUrl, anonKey: _supabaseAnonKey);
    return Supabase.instance.client;
  }
}
