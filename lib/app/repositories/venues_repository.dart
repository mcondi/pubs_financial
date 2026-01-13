import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers.dart';
import '../models/venue.dart';

class VenuesRepository {
  VenuesRepository(this.ref);
  final Ref ref;

  Future<List<Venue>> fetchVenues() async {
    final api = ref.read(apiClientProvider);

    final res = await api.dio.get('/v1/financials/trends');

    return api.decodeOrThrow<List<Venue>>(
      res,
      (json) => (json as List)
          .whereType<Map>()
          .map((e) => Venue.fromJson(e.cast<String, dynamic>()))
          .toList(),
    );
  }
}

final venuesRepositoryProvider = Provider<VenuesRepository>((ref) {
  return VenuesRepository(ref);
});
