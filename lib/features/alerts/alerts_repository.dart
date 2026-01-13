import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/providers.dart';

class AlertsRepository {
  AlertsRepository(this.ref);
  final Ref ref;

  Future<void> sendHealthInspectionAlert({
    required int venueId,
    required String venueName,
    required String notes,
    String severity = 'info', // "info" / "warning" / "critical" etc.
  }) async {
    final api = ref.read(apiClientProvider);

    // iOS uses: POST /v1/alerts/health-inspection
    final res = await api.dio.post(
      '/v1/alerts/health-inspection',
      data: <String, dynamic>{
        'originVenueId': venueId,
        'originVenueName': venueName,
        'notes': notes,
        'severity': severity,
      },
    );

    // Just ensure 2xx
api.decodeOrThrow(res, (_) => true);

  }
}

final alertsRepositoryProvider = Provider<AlertsRepository>((ref) {
  return AlertsRepository(ref);
});
