import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'models/venue.dart';
import 'package:pubs_financial/app/providers.dart';

final venuesProvider = FutureProvider<List<Venue>>((ref) async {
  ref.keepAlive();

  final api = ref.read(apiClientProvider);
  final res = await api.dio.get('/v1/financials/trends');

 return api.decodeOrThrow<List<Venue>>(
  res,
  (json) => (json as List)
      .whereType<Map>()
      .map((e) => Venue.fromJson(e.cast<String, dynamic>()))
      .where((v) => v.id != 0) // drop invalid rows
      .toList(),
  );
});
