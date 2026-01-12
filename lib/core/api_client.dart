import 'package:dio/dio.dart';

import 'api_errors.dart';
import 'app_config.dart';
import 'token_store.dart';

class ApiClient {
  final Dio dio;
  final TokenStore tokenStore;

  ApiClient({required this.dio, required this.tokenStore});

  static ApiClient create(TokenStore tokenStore) {
    final dio = Dio(BaseOptions(
      baseUrl: AppConfig.baseUrl,
      headers: {'Accept': 'application/json'},
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 30),
    ));

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await tokenStore.readToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (e, handler) async {
          final status = e.response?.statusCode;

          // ✅ If token expired / invalid => clear token so router redirects to /login
          if (status == 401) {
            await tokenStore.clear();
            handler.reject(
              DioException(
                requestOptions: e.requestOptions,
                response: e.response,
                type: e.type,
                error: ApiAuthException.sessionExpired,
              ),
            );
            return;
          }

          handler.next(e);
        },
      ),
    );

    return ApiClient(dio: dio, tokenStore: tokenStore);
  }

  T decodeOrThrow<T>(Response response, T Function(dynamic json) mapper) {
    final status = response.statusCode ?? 0;
    if (status >= 200 && status < 300) return mapper(response.data);

    final body = response.data?.toString() ?? '<no body>';
    throw ApiHttpException(statusCode: status, message: body);
  }
}
