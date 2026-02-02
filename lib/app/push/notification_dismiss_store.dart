import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const _kLastDismissedKey = 'last_dismissed_notification_key';

class NotificationDismissStore {
  NotificationDismissStore(this._storage);
  final FlutterSecureStorage _storage;

  Future<String?> getLastDismissed() => _storage.read(key: _kLastDismissedKey);

  Future<void> setLastDismissed(String key) => _storage.write(key: _kLastDismissedKey, value: key);
}

final notificationDismissStoreProvider = Provider<NotificationDismissStore>((ref) {
  return NotificationDismissStore(const FlutterSecureStorage());
});
