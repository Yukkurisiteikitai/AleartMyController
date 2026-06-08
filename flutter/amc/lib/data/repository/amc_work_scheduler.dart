/// クラウド同期 worker の起動を抽象化する（§4.2/§4.3）。
///
/// 実体（workmanager によるユニークワーク登録）は P4 で実装し、
/// `amcWorkSchedulerProvider` を override して差し替える。
/// P2 時点では [NoopAmcWorkScheduler] を使い、Repository が worker に
/// 直接依存しないようにする（ファイル所有権の分離）。
abstract interface class AmcWorkScheduler {
  Future<void> enqueueAttachmentUpload();
  Future<void> enqueueRecordSync();
}

/// 何もしない既定実装（P4 までのプレースホルダ）。
class NoopAmcWorkScheduler implements AmcWorkScheduler {
  const NoopAmcWorkScheduler();

  @override
  Future<void> enqueueAttachmentUpload() async {}

  @override
  Future<void> enqueueRecordSync() async {}
}
