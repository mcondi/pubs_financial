import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsStore {
  SettingsStore(this._storage);

  final FlutterSecureStorage _storage;

  static const _defaultVenueKey = 'defaultVenueId';
  static const _useFaceIdKey = 'useFaceId';

  Future<int?> readDefaultVenueId() async {
    final s = await _storage.read(key: _defaultVenueKey);
    if (s == null) return null;
    return int.tryParse(s);
  }

  Future<void> writeDefaultVenueId(int id) async {
    await _storage.write(key: _defaultVenueKey, value: id.toString());
  }

  Future<bool> readUseFaceId() async {
    final s = await _storage.read(key: _useFaceIdKey);
    return s == 'true';
  }

  Future<void> writeUseFaceId(bool value) async {
    await _storage.write(key: _useFaceIdKey, value: value ? 'true' : 'false');
  }
}

final flutterSecureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

final settingsStoreProvider = Provider<SettingsStore>((ref) {
  return SettingsStore(ref.watch(flutterSecureStorageProvider));
});
