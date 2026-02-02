import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/app_config.dart';

class AlertsRepository {
  AlertsRepository(this.ref);
  final Ref ref;

  /// Unified alert sender.
  /// Uses the existing alert path for now, but sends title/body so the server can build the push correctly.
  Future<void> sendAlert({
    required int venueId,
    required String venueName,
    required String title,
    required String body,
    String severity = 'info',
    String? type, // optional, e.g. "health", "gaming", "licensing", "police"
  }) async {
    final api = ref.read(apiClientProvider);

    // Keep your current path (update later once backend supports a dedicated endpoint if needed)
    final path = AppConfig.alertHealthInspectionPath;

    final res = await api.dio.post(
      path,
      data: <String, dynamic>{
        'originVenueId': venueId,
        'originVenueName': venueName,

        // ✅ NEW fields (preferred by updated backend)
        'title': title,
        'body': body,

        // ✅ Backward compatibility if backend still expects "notes"
        'notes': body,

        'severity': severity,
        if (type != null) 'type': type,
      },
    );

    api.decodeOrThrow(res, (_) => true);
  }

  // ------------------------------------------------------------------
  // Optional: keep old method name so existing call sites still compile
  // (You can delete this once you've updated all screens to sendAlert)
  // ------------------------------------------------------------------
  Future<void> sendHealthInspectionAlert({
    required int venueId,
    required String venueName,
    required String notes,
    String severity = 'info',
  }) {
    return sendAlert(
      venueId: venueId,
      venueName: venueName,
      title: 'Alert from $venueName',
      body: notes,
      severity: severity,
      type: 'health', // best guess
    );
  }
}

final alertsRepositoryProvider = Provider<AlertsRepository>((ref) {
  return AlertsRepository(ref);
});
