import 'package:dio/dio.dart';

import '../../core/api_client.dart';
import '../../core/app_config.dart';
import '../../core/token_store.dart';
import '../../core/api_errors.dart';
import 'auth_dtos.dart';

class AuthRepository {
  final ApiClient api;
  AuthRepository(this.api);

  Future<void> login(String user, String pass) async {
    try {
      final resp = await api.dio.post(
        AppConfig.loginPath,
        options: Options(headers: {'Content-Type': 'application/json'}),
        data: LoginRequest(
          emailOrUsername: user,
          password: pass,
        ).toJson(),
      );

      final status = resp.statusCode ?? 0;
      final ct = resp.headers.value('content-type');
      final body = resp.data;

      // Guards to prevent the “data missing” / decode crashes
      if (body == null || (body is String && body.trim().isEmpty)) {
        throw ApiHttpException(
          statusCode: status,
          message: 'Login failed: server returned no data (status $status).',
        );
      }

      if (ct != null && !ct.contains('application/json')) {
        throw ApiHttpException(
          statusCode: status,
          message: 'Login failed: unexpected response type ($ct).',
        );
      }

      final r = api.decodeOrThrow(resp, (json) => LoginResponse.fromJson(json));

      final expiry = DateTime.now().add(Duration(seconds: r.expiresInSeconds));

      await api.tokenStore.saveSession(
        AuthSession(
          accessToken: r.accessToken,
          refreshToken: r.refreshToken,
          accessExpiry: expiry,
        ),
      );
    } on DioException catch (e) {
      final status = e.response?.statusCode ?? 0;

      final message = () {
        final d = e.response?.data;
        if (d is Map && d['message'] is String) return d['message'] as String;
        if (d is String && d.trim().isNotEmpty) return d;
        return e.message ?? 'Login failed';
      }();

      // ignore: avoid_print
      print('LOGIN dio error status=$status');

      throw ApiHttpException(
        statusCode: status,
        message: 'Login failed (HTTP $status): $message',
      );
    }
  }

  Future<AuthSession?> refresh(String refreshToken) async {
    try {
      final resp = await api.dio.post(
        AppConfig.refreshPath,
        options: Options(headers: {'Content-Type': 'application/json'}),
        data: RefreshRequest(refreshToken).toJson(),
      );

      final r = api.decodeOrThrow(resp, (json) => RefreshResponse.fromJson(json));

      return AuthSession(
        accessToken: r.accessToken,
        refreshToken: r.refreshToken,
        accessExpiry: DateTime.now().add(Duration(seconds: r.expiresInSeconds)),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> logout() async {
    await api.tokenStore.clear();
  }
}
