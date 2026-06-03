import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:workmanager/workmanager.dart';

import '../data/repository/amc_work_scheduler.dart';
import 'amc_attachment_upload_worker.dart';
import 'amc_record_sync_worker.dart';

const _attachmentUnique = 'amc_attachment_upload';
const _syncUnique = 'amc_record_sync';

/// workmanager による AmcWorkScheduler 本実装（P4）。
///
/// Android/iOS: workmanager でバックグラウンド isolate に処理を委譲する。
/// Web: workmanager 非対応のため Worker.run() をフォアグラウンドで直接実行する。
class WorkmanagerAmcWorkScheduler implements AmcWorkScheduler {
  const WorkmanagerAmcWorkScheduler();

  @override
  Future<void> enqueueAttachmentUpload() async {
    if (kIsWeb) {
      await AmcAttachmentUploadWorker.run();
      return;
    }
    await Workmanager().registerOneOffTask(
      _attachmentUnique,
      _attachmentUnique,
      existingWorkPolicy: ExistingWorkPolicy.keep,
    );
  }

  @override
  Future<void> enqueueRecordSync() async {
    if (kIsWeb) {
      await AmcRecordSyncWorker.run();
      return;
    }
    await Workmanager().registerOneOffTask(
      _syncUnique,
      _syncUnique,
      existingWorkPolicy: ExistingWorkPolicy.keep,
    );
  }
}
