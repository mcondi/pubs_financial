import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'models/venue.dart';
import 'venues_provider.dart';

const int groupVenueId = 26;

final venuesSortedProvider = Provider<AsyncValue<List<Venue>>>((ref) {
  final async = ref.watch(venuesProvider);

  return async.whenData((venues) {
    final list = [...venues];

    list.sort((a, b) {
      if (a.id == groupVenueId && b.id != groupVenueId) return -1;
      if (b.id == groupVenueId && a.id != groupVenueId) return 1;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });

    return list;
  });
});
