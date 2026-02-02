import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthSession {
  final String accessToken;
  final String refreshToken;
  final DateTime accessExpiry;

  AuthSession({
    required this.accessToken,
    required this.refreshToken,
    required this.accessExpiry,
  });

  bool get isExpired => DateTime.now().isAfter(accessExpiry);

  Map<String, dynamic> toJson() => {
        'accessToken': accessToken,
        'refreshToken': refreshToken,
        'accessExpiry': accessExpiry.toIso8601String(),
      };

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    return AuthSession(
      accessToken: json['accessToken'],
      refreshToken: json['refreshToken'],
      accessExpiry: DateTime.parse(json['accessExpiry']),
    );
  }
}

class TokenStore extends ChangeNotifier {
  static const _key = 'auth_session';

  final FlutterSecureStorage _storage;
  AuthSession? _session;

  TokenStore(this._storage);

  AuthSession? get session => _session;
  bool get isLoggedIn => _session != null;

  Future<void> init() async {
    final raw = await _storage.read(key: _key);
    if (raw != null) {
      _session = AuthSession.fromJson(jsonDecode(raw));
    }
    notifyListeners();
  }

  Future<void> saveSession(AuthSession session) async {
    _session = session;
    await _storage.write(key: _key, value: jsonEncode(session.toJson()));
    notifyListeners();
  }

  Future<void> clear() async {
    _session = null;
    await _storage.delete(key: _key);
    notifyListeners();
  }
}
