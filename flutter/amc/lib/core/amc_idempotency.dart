import 'package:uuid/uuid.dart';

/// idempotency_key 生成 helper（Android: AmcIdempotency 相当）。
class AmcIdempotency {
  AmcIdempotency._();

  static const _uuid = Uuid();

  static String newKey() => _uuid.v4();
}
