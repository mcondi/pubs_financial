import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SettingsStore {
  SettingsStore(this._storage);

  final FlutterSecureStorage _storage;

  // ---------- Keys ----------
  static const _defaultVenueKey = 'defaultVenueId';
  static const _useFaceIdKey = 'useFaceId';

  // Stored credentials for Face ID auto-login
  static const _bioUserKey = 'bio_user';
  static const _bioPassKey = 'bio_pass';

  // ---------- Default venue ----------

  Future<int?> readDefaultVenueId() async {
    final s = await _storage.read(key: _defaultVenueKey);
    if (s == null) return null;
    return int.tryParse(s);
  }

  Future<void> writeDefaultVenueId(int id) async {
    await _storage.write(key: _defaultVenueKey, value: id.toString());
  }

  // ---------- Face ID toggle ----------

  Future<bool> readUseFaceId() async {
    final s = await _storage.read(key: _useFaceIdKey);
    return s == 'true';
  }

  Future<void> writeUseFaceId(bool value) async {
    await _storage.write(
      key: _useFaceIdKey,
      value: value ? 'true' : 'false',
    );

    // If user turns Face ID OFF, clear stored creds for safety
    if (!value) {
      await clearBiometricCreds();
    }
  }

  // ---------- Biometric credentials ----------

  /// Store username + password securely for Face ID auto-login
  Future<void> storeBiometricCreds({
    required String user,
    required String pass,
  }) async {
    await _storage.write(key: _bioUserKey, value: user);
    await _storage.write(key: _bioPassKey, value: pass);
  }

  /// Read stored credentials (returns null if missing)
Future<({String user, String pass})?> readBiometricCreds() async {
    final user = await _storage.read(key: _bioUserKey);
    final pass = await _storage.read(key: _bioPassKey);

    if (user == null || user.isEmpty || pass == null || pass.isEmpty) {
      return null;
    }

    return (user: user, pass: pass);
  }

  /// Clear stored credentials
  Future<void> clearBiometricCreds() async {
    await _storage.delete(key: _bioUserKey);
    await _storage.delete(key: _bioPassKey);
  }
}
