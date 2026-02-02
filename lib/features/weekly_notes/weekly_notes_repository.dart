import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/api_client.dart';
import '../trends/trends_dtos.dart';
import '../trends/trends_repository.dart';

class WeeklyNotesRepository {
  WeeklyNotesRepository(this.api, this.trendsRepo);
  final ApiClient api;
  final TrendsRepository trendsRepo;

  Future<WeekNotesResponse?> fetchWeekNotes({
    required String weekEndISO,
    int? venueId,
  }) {
    return trendsRepo.fetchWeekNotes(weekEndISO: weekEndISO, venueId: venueId);
  }

  /// ✅ Assumed save endpoint (update if your backend differs)
  /// Common patterns:
  /// - POST /v1/notes/week  (upsert)
  /// - PUT  /v1/notes/week
  Future<WeekNotesResponse> upsertWeekNotes({
    required String weekEndISO,
    int? venueId, // null = group
    required String category,
    required String? generalNote,
    required List<String> hashtags,
  }) async {
    final resp = await api.dio.post(
      '/v1/notes/week',
      data: {
        'weekEndISO': weekEndISO,
        if (venueId != null) 'venueId': venueId,
        'category': category,
        'generalNote': generalNote,
        'hashtags': hashtags,
      },
    );

    return api.decodeOrThrow(resp, (json) => WeekNotesResponse.fromJson(json as Map<String, dynamic>));
  }

  /// Optional: clear/delete (only if your backend supports it)
  Future<void> deleteWeekNotes({
    required String weekEndISO,
    int? venueId,
  }) async {
    try {
      await api.dio.delete(
        '/v1/notes/week',
        queryParameters: {
          'weekEndISO': weekEndISO,
          if (venueId != null) 'venueId': venueId,
        },
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return;
      rethrow;
    }
  }
}

final weeklyNotesRepositoryProvider = Provider<WeeklyNotesRepository>((ref) {
  final api = ref.read(apiClientProvider);
  final trends = ref.read(trendsRepositoryProvider);
  return WeeklyNotesRepository(api, trends);
});
