import 'package:drift/drift.dart';

import '../database.dart';
import '../tables.dart';

part 'photo_dao.g.dart';

@DriftAccessor(tables: [Photos])
class PhotoDao extends DatabaseAccessor<AppDatabase> with _$PhotoDaoMixin {
  PhotoDao(super.attachedDatabase);

  Future<int> insertPhoto(PhotosCompanion photo) => into(photos).insert(photo);

  Future<void> deleteById(int photoId) =>
      (delete(photos)..where((t) => t.photoId.equals(photoId))).go();

  Stream<List<Photo>> watchByRecord(int recordId) =>
      (select(photos)..where((t) => t.recordId.equals(recordId))).watch();

  Future<List<Photo>> findByRecord(int recordId) =>
      (select(photos)..where((t) => t.recordId.equals(recordId))).get();
}
