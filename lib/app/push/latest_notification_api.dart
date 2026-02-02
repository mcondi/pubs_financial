import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pubs_financial/core/api_client.dart';
import 'package:pubs_financial/app/providers.dart';
import 'latest_notification_provider.dart';

class LatestNotificationApi {
  final ApiClient _api;

  LatestNotificationApi(this._api);

  Future<LatestNotification?> fetchLatest({required String userName}) async {
    final resp = await _api.dio.get(
      '/v1/notifications/latest',
      queryParameters: {'user': userName},
    );

    // ✅ Debug log (keep for now)
    // ignore: avoid_print
    print('LatestNotification GET status=${resp.statusCode} data=${resp.data}');

    return _api.decodeOrThrow<LatestNotification?>(resp, (json) {
      if (json == null) return null;
      if (json is! Map) return null;

      final map = (json).cast<String, dynamic>();

      // Support both camelCase and PascalCase from .NET
      final title = (map['title'] ?? map['Title'] ?? '').toString();
      final body = (map['body'] ?? map['Body'] ?? '').toString();

      final sentUtcRaw = (map['sentUtc'] ??
              map['SentUtc'] ??
              map['sentUTC'] ??
              map['SentUTC'] ??
              '')
          .toString();

      final receivedAt =
          DateTime.tryParse(sentUtcRaw)?.toLocal() ?? DateTime.now();

      if (title.isEmpty && body.isEmpty) return null;

      return LatestNotification(
        title: title,
        body: body,
        receivedAt: receivedAt,
      );
    });
  }
}

final latestNotificationApiProvider = Provider<LatestNotificationApi>((ref) {
  final api = ref.watch(apiClientProvider);
  return LatestNotificationApi(api);
});
