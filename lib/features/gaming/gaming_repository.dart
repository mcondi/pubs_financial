import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';

class GamingRepository {
  GamingRepository(this.ref);
  final Ref ref;

  Future<Map<String, dynamic>> fetchGamingSummary({
    required int venueId,
    String? weekEnd, // YYYY-MM-DD
  }) async {
    final api = ref.read(apiClientProvider);

    final res = await api.dio.get(
      '/v1/gaming/summary',
      queryParameters: {
        'venueId': venueId,
        if (weekEnd != null && weekEnd.isNotEmpty) 'weekEnd': weekEnd,
      },
    );

    return api.decodeOrThrow<Map<String, dynamic>>(
      res,
      (json) => (json as Map).cast<String, dynamic>(),
    );
  }
}

final gamingRepositoryProvider = Provider<GamingRepository>((ref) {
  return GamingRepository(ref);
});
