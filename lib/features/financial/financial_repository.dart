import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart'; // where apiClientProvider lives

class FinancialRepository {
  FinancialRepository(this.ref);
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

final financialRepositoryProvider = Provider<FinancialRepository>((ref) {
  return FinancialRepository(ref);
});
