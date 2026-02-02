import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_providers.dart'; // ✅ single source of truth: tokenStoreProvider + apiClientProvider

class PushRegistrationService {
  PushRegistrationService(this.ref);
  final Ref ref;

  bool _isRunning = false;
  DateTime? _startedAt;

  static bool _refreshListenerInstalled = false;

  /// Call after login (recommended) and optionally on app start.
  Future<void> registerIfPossible() async {
    if (_isRunning) return;

    final jwt = ref.read(tokenStoreProvider).session?.accessToken;
    if (jwt == null || jwt.isEmpty) {
      if (kDebugMode) debugPrint('📲 Push register: skip (no JWT yet)');
      return;
    }

    _isRunning = true;
    _startedAt = DateTime.now();

    try {
      await _registerWithRetries();
      _ensureRefreshListenerInstalled();
    } finally {
      _isRunning = false;
    }
  }

  Future<void> _registerWithRetries() async {
    const maxAttempts = 15; // ~45s if retryDelay is 3s
    const retryDelay = Duration(seconds: 3);
    const maxDuration = Duration(seconds: 60);

    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      final elapsed = DateTime.now().difference(_startedAt ?? DateTime.now());
      if (elapsed > maxDuration) {
        if (kDebugMode) debugPrint('📲 Push register: stopping after ${elapsed.inSeconds}s');
        return;
      }

      final ok = await _tryRegisterOnce();
      if (ok) return;

      if (kDebugMode) {
        debugPrint('📲 Push register: retrying in ${retryDelay.inSeconds}s (attempt $attempt/$maxAttempts)');
      }
      await Future<void>.delayed(retryDelay);
    }

    if (kDebugMode) debugPrint('📲 Push register: gave up after $maxAttempts attempts');
  }

  Future<bool> _tryRegisterOnce() async {
    final messaging = FirebaseMessaging.instance;

    // 1) Ask permission (iOS) - safe on Android too
    final perm = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (kDebugMode) {
      debugPrint('🔔 Notification permission: ${perm.authorizationStatus}');
    }

    // 2) iOS: wait briefly for APNs token
    final apnsToken = await _waitForApnsToken(messaging);
    if (kDebugMode) debugPrint('🍎 APNs token: ${apnsToken ?? "(null)"}');

    // On iOS, APNs token is required for reliable token registration.
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      if (apnsToken == null || apnsToken.isEmpty) {
        return false; // retry later
      }
    }

    // 3) Now safe to request FCM token
    String? fcmToken;
    try {
      fcmToken = await messaging.getToken();
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ getToken failed: $e');
      return false;
    }

    if (kDebugMode) debugPrint('🟩 FCM token: ${_short(fcmToken)}');

    if (fcmToken == null || fcmToken.isEmpty) {
      return false;
    }

    // 4) Register with backend
    try {
      await _registerWithBackend(fcmToken);
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Backend register failed: $e');
      return false;
    }
  }

  Future<String?> _waitForApnsToken(FirebaseMessaging messaging) async {
    // Keep short. Outer retry loop handles longer waits.
    for (var i = 0; i < 10; i++) {
      final t = await messaging.getAPNSToken();
      if (t != null && t.isNotEmpty) return t;
      await Future<void>.delayed(const Duration(milliseconds: 300));
    }
    return null;
  }

  Future<void> _registerWithBackend(String fcmToken) async {
    final api = ref.read(apiClientProvider);

    // TODO: confirm your actual endpoint
    const path = '/v1/devices/register';

    if (kDebugMode) debugPrint('➡️ POST $path token=${_short(fcmToken)}');

    final res = await api.dio.post(
      path,
      data: {
        'deviceToken': fcmToken,
        'platform': defaultTargetPlatform == TargetPlatform.iOS ? 'iOS' : 'Android',
      },
    );

    api.decodeOrThrow(res, (_) => true);

    if (kDebugMode) debugPrint('✅ register response ${res.statusCode}');
  }

  void _ensureRefreshListenerInstalled() {
    if (_refreshListenerInstalled) return;
    _refreshListenerInstalled = true;

    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      if (kDebugMode) debugPrint('🔁 FCM token refreshed: ${_short(newToken)}');
      try {
        await _registerWithBackend(newToken);
      } catch (e) {
        if (kDebugMode) debugPrint('❌ Register on refresh failed: $e');
      }
    });
  }

  static String _short(String? t) {
    if (t == null || t.isEmpty) return '(null)';
    return '${t.substring(0, t.length > 10 ? 10 : t.length)}...';
  }
}

final pushRegistrationServiceProvider = Provider<PushRegistrationService>((ref) {
  return PushRegistrationService(ref);
});
