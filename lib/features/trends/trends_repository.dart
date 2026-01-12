import 'package:dio/dio.dart';
import '../../core/api_client.dart';
import 'trends_dtos.dart';

class TrendsRepository {
  final ApiClient api;
  TrendsRepository(this.api);

  Future<List<TrendsVenue>> fetchTrendsVenues() async {
    final resp = await api.dio.get('/v1/financials/trends');
    return api.decodeOrThrow(resp, (json) {
      final list = (json as List).cast<dynamic>();
      return list.map((e) => TrendsVenue.fromJson(e as Map<String, dynamic>)).toList();
    });
  }

  Future<TrendsVenueWeeklySummary> fetchTrendsSummary({
    required int venueId,
    String? weekEnd, // YYYY-MM-DD
  }) async {
    final resp = await api.dio.get(
      '/v1/financials/trends/venue/$venueId/summary',
      queryParameters: weekEnd == null ? null : {'weekEnd': weekEnd},
    );

    return api.decodeOrThrow(resp, (json) {
      return TrendsVenueWeeklySummary.fromJson(json as Map<String, dynamic>);
    });
  }

  /// Notes: GET /v1/notes/week?weekEndISO=YYYY-MM-DD&venueId=#
  /// If venueId is null => Group notes.
  Future<WeekNotesResponse?> fetchWeekNotes({
    required String weekEndISO, // YYYY-MM-DD
    int? venueId,
  }) async {
    try {
      final resp = await api.dio.get(
        '/v1/notes/week',
        queryParameters: {
          'weekEndISO': weekEndISO,
          if (venueId != null) 'venueId': venueId,
        },
      );

      return api.decodeOrThrow(resp, (json) {
        return WeekNotesResponse.fromJson(json as Map<String, dynamic>);
      });
    } on DioException catch (e) {
      // If API returns 404 when no notes exist, treat as "no notes"
      final code = e.response?.statusCode;
      if (code == 404) return null;
      rethrow;
    }
  }
}
