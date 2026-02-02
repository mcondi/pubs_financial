import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../features/auth/auth_dtos.dart';
import 'api_errors.dart';
import 'app_config.dart';
import 'token_store.dart';

class ApiClient {
  final Dio dio;
  final TokenStore tokenStore;

  ApiClient({required this.dio, required this.tokenStore});

  static ApiClient create(TokenStore tokenStore) {
    final dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.baseUrl,
        headers: {'Accept': 'application/json'},
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 30),
      ),
    );

    // Separate Dio used ONLY for refresh, with NO interceptors
    final refreshDio = Dio(
      BaseOptions(
        baseUrl: AppConfig.baseUrl,
        headers: {'Accept': 'application/json'},
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 30),
      ),
    );

    final client = ApiClient(dio: dio, tokenStore: tokenStore);

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final session = tokenStore.session;

          if (kDebugMode) {
            final hasSession = session != null;
            final hasAccess = session?.accessToken.isNotEmpty == true;
            final hasRefresh = session?.refreshToken.isNotEmpty == true;
            debugPrint(
              'API ▶ ${options.method} ${options.baseUrl}${options.path} '
              'hasSession=$hasSession hasAccess=$hasAccess hasRefresh=$hasRefresh',
            );
            if (session != null) {
              debugPrint(
                'API ▶ accessExpiry=${session.accessExpiry.toIso8601String()} expired=${session.isExpired}',
              );
            }
          }

          if (session != null && session.accessToken.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer ${session.accessToken}';
          }

          handler.next(options);
        },
        onError: (e, handler) async {
          final status = e.response?.statusCode;

          // Only handle 401s here
          if (status != 401) {
            return handler.next(e);
          }

          if (kDebugMode) {
            debugPrint('API ❌ 401 for ${e.requestOptions.method} ${e.requestOptions.uri}');
          }

          final session = tokenStore.session;

          if (kDebugMode) {
            debugPrint(
              'API ❌ sessionExists=${session != null} refreshPresent=${session?.refreshToken.isNotEmpty == true}',
            );
          }

          // No session -> force logout
          if (session == null || session.refreshToken.isEmpty) {
            await tokenStore.clear();
            return handler.reject(e.copyWith(error: ApiAuthException.sessionExpired));
          }

          // Prevent infinite loops
          final alreadyRetried = e.requestOptions.extra['__retried'] == true;
          if (alreadyRetried) {
            await tokenStore.clear();
            return handler.reject(e.copyWith(error: ApiAuthException.sessionExpired));
          }

          try {
            if (kDebugMode) {
              debugPrint('API 🔁 attempting refresh via ${AppConfig.baseUrl}${AppConfig.refreshPath}');
            }

            // Call refresh endpoint using refreshDio (no auth interceptor)
            final refreshResp = await refreshDio.post(
              AppConfig.refreshPath,
              options: Options(headers: {'Content-Type': 'application/json'}),
              data: RefreshRequest(session.refreshToken).toJson(),
            );

            final rr = client.decodeOrThrow(
              refreshResp,
              (json) => RefreshResponse.fromJson(json),
            );

            final newSession = AuthSession(
              accessToken: rr.accessToken,
              refreshToken: rr.refreshToken,
              accessExpiry: DateTime.now().add(Duration(seconds: rr.expiresInSeconds)),
            );

            await tokenStore.saveSession(newSession);

            if (kDebugMode) {
              debugPrint('API ✅ refresh succeeded; retrying original request once');
            }

            // Retry original request once with new token
            final ro = e.requestOptions;

            // Mark it retried
            ro.extra['__retried'] = true;

            // Build new headers based on old ones
            final newHeaders = Map<String, dynamic>.from(ro.headers);
            newHeaders['Authorization'] = 'Bearer ${newSession.accessToken}';

            // Create a fresh Options for retry
            final retryOptions = Options(
              method: ro.method,
              headers: newHeaders,
              responseType: ro.responseType,
              contentType: ro.contentType,
              followRedirects: ro.followRedirects,
              validateStatus: ro.validateStatus,
              receiveDataWhenStatusError: ro.receiveDataWhenStatusError,
              extra: ro.extra,
              sendTimeout: ro.sendTimeout,
              receiveTimeout: ro.receiveTimeout,
            );

            final retryResponse = await dio.request<dynamic>(
              ro.path,
              data: ro.data,
              queryParameters: ro.queryParameters,
              options: retryOptions,
              cancelToken: ro.cancelToken,
              onReceiveProgress: ro.onReceiveProgress,
              onSendProgress: ro.onSendProgress,
            );

            return handler.resolve(retryResponse);
          } on DioException catch (re) {
            final rs = re.response?.statusCode;

            if (kDebugMode) {
              debugPrint('API 🔁 refresh failed status=$rs error=${re.error}');
            }

            // If refresh endpoint says unauthorized/bad request -> session truly expired
            if (rs == 401 || rs == 400) {
              await tokenStore.clear();
              return handler.reject(e.copyWith(error: ApiAuthException.sessionExpired));
            }

            // Network / timeout / 5xx: don't clear session, just bubble original 401 up
            return handler.reject(e);
          } catch (ex) {
            if (kDebugMode) {
              debugPrint('API 🔁 refresh threw unexpected error: $ex');
            }
            // Unknown failure: don't clear session aggressively
            return handler.reject(e);
          }
        },
      ),
    );

    return client;
  }

  /// Keep this so existing repositories keep compiling
  T decodeOrThrow<T>(Response response, T Function(dynamic json) mapper) {
    final status = response.statusCode ?? 0;
    if (status >= 200 && status < 300) return mapper(response.data);

    final body = response.data?.toString() ?? '<no body>';
    throw ApiHttpException(statusCode: status, message: body);
  }
}
