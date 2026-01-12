import 'package:dio/dio.dart';
import '../../core/app_config.dart';
import '../../core/api_client.dart';
import '../../core/api_errors.dart';
import 'auth_dtos.dart';

class AuthRepository {
  final ApiClient api;
  AuthRepository(this.api);

  Future<String> login(String emailOrUsername, String password) async {
    try {
      final resp = await api.dio.post(
        AppConfig.loginPath,
        options: Options(headers: {'Content-Type': 'application/json'}),
        data: LoginRequest(emailOrUsername: emailOrUsername, password: password).toJson(),
      );

      final login = api.decodeOrThrow(resp, (json) => LoginResponse.fromJson(json));
      await api.tokenStore.writeToken(login.token);
      return login.token;
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == 401) throw ApiAuthException.invalidCredentials;
      if (e.error is ApiAuthException) throw e.error as ApiAuthException;

      final body = e.response?.data?.toString() ?? e.message ?? 'Unknown error';
      throw ApiHttpException(statusCode: status ?? 0, message: body);
    }
  }

  Future<void> logout() => api.tokenStore.clear();
}
