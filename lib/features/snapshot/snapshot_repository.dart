import '../../core/api_client.dart';

class SnapshotRepository {
  final ApiClient api;
  SnapshotRepository(this.api);

  /// Mirrors iOS: GET /v1/financials/venue/{venueId}/summary?weekEnd=YYYY-MM-DD
  Future<Map<String, dynamic>> fetchVenueSummary({
    required int venueId,
    String? weekEnd, // YYYY-MM-DD
  }) async {
    final resp = await api.dio.get(
      '/v1/financials/venue/$venueId/summary',
      queryParameters: weekEnd == null ? null : {'weekEnd': weekEnd},
    );

    return api.decodeOrThrow(resp, (json) => (json as Map).cast<String, dynamic>());
  }
}
