import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/models/venue.dart';
import 'alerts_repository.dart';

class AlertsState {
  final bool isSending;
  final bool showConfirm;
  final bool showSuccess;
  final String? errorMessage;

  // pending payload (like your Swift stored vars)
  final int? venueId;
  final String? venueName;
  final String? notes;
  final String severity;

  const AlertsState({
    this.isSending = false,
    this.showConfirm = false,
    this.showSuccess = false,
    this.errorMessage,
    this.venueId,
    this.venueName,
    this.notes,
    this.severity = 'info',
  });

  AlertsState copyWith({
    bool? isSending,
    bool? showConfirm,
    bool? showSuccess,
    String? errorMessage,
    int? venueId,
    String? venueName,
    String? notes,
    String? severity,
    bool clearError = false,
  }) {
    return AlertsState(
      isSending: isSending ?? this.isSending,
      showConfirm: showConfirm ?? this.showConfirm,
      showSuccess: showSuccess ?? this.showSuccess,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      venueId: venueId ?? this.venueId,
      venueName: venueName ?? this.venueName,
      notes: notes ?? this.notes,
      severity: severity ?? this.severity,
    );
  }
}

class AlertsController extends StateNotifier<AlertsState> {
  AlertsController(this.ref) : super(const AlertsState());
  final Ref ref;

  void prepareSend({
    required Venue venue,
    required String notes,
    String severity = 'info',
  }) {
    state = state.copyWith(
      venueId: venue.id,
      venueName: venue.name,
      notes: notes,
      severity: severity,
      showConfirm: true,
      showSuccess: false,
      clearError: true,
    );
  }

  void cancelConfirm() {
    state = state.copyWith(showConfirm: false);
  }

  Future<void> confirmSend() async {
    final venueId = state.venueId;
    final venueName = state.venueName;
    final notes = state.notes;

    if (venueId == null || venueName == null) return;

    state = state.copyWith(isSending: true, showConfirm: false, clearError: true);

    try {
      await ref.read(alertsRepositoryProvider).sendHealthInspectionAlert(
            venueId: venueId,
            venueName: venueName,
            notes: notes,
            severity: state.severity,
          );

      state = state.copyWith(isSending: false, showSuccess: true);
    } catch (e) {
      state = state.copyWith(isSending: false, errorMessage: e.toString());
    }
  }

  void clearSuccess() {
    state = state.copyWith(showSuccess: false);
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

final alertsControllerProvider =
    StateNotifierProvider<AlertsController, AlertsState>((ref) {
  return AlertsController(ref);
});
