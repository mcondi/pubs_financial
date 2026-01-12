import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/providers.dart';

class CategoryRepository {
  CategoryRepository(this.ref);
  final Ref ref;

  Future<Map<String, dynamic>> fetchVenueSummary({
    required int venueId,
    String? weekEnd, // YYYY-MM-DD
  }) async {
    final api = ref.read(apiClientProvider);

    final res = await api.dio.get(
      '/v1/financials/venue/$venueId/summary',
      queryParameters: {
        if (weekEnd != null && weekEnd.isNotEmpty) 'weekEnd': weekEnd,
      },
    );

    return api.decodeOrThrow<Map<String, dynamic>>(
      res,
      (json) => (json as Map).cast<String, dynamic>(),
    );
  }
}

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return CategoryRepository(ref);
});
