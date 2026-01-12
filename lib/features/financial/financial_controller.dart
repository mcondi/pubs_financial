import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'financial_repository.dart';

/// You likely already have these in your app:
/// - authTokenProvider (String? token)
/// - venuesProvider (List<Venue>)
///
/// If your names differ, just swap them.
final authTokenProvider = Provider<String?>((ref) => null);

class Venue {
  final int id;
  final String name;
  const Venue(this.id, this.name);
}

/// Replace with your real venues provider
final venuesProvider = Provider<List<Venue>>((ref) {
  return const [
    Venue(26, 'Group'),
    // ...
  ];
});

class FinancialMetric {
  final String name;
  final double weeklyRatio; // 0.0..n (1.11 means 111%)
  final double ytdRatio;
  final String weekAmount;
  final String ytdAmount;

  const FinancialMetric({
    required this.name,
    required this.weeklyRatio,
    required this.ytdRatio,
    required this.weekAmount,
    required this.ytdAmount,
  });
}

class FinancialNotes {
  final bool hasComment;
  final String? commentText;
  final String? category;
  final String? generalNote;
  final List<String> hashtags;

  const FinancialNotes({
    required this.hasComment,
    this.commentText,
    this.category,
    this.generalNote,
    required this.hashtags,
  });

  bool get hasAny =>
      hasComment ||
      (generalNote != null && generalNote!.trim().isNotEmpty) ||
      hashtags.isNotEmpty;
}

class FinancialState {
  final bool isLoading;
  final String? error;
  final int venueId;
  final String? weekEnd; // yyyy-MM-dd
  final String? prevWeekEnd;
  final String? nextWeekEnd;
  final List<FinancialMetric> metrics;
  final FinancialNotes? notes;

  const FinancialState({
    required this.isLoading,
    required this.venueId,
    this.error,
    this.weekEnd,
    this.prevWeekEnd,
    this.nextWeekEnd,
    required this.metrics,
    this.notes,
  });

  FinancialState copyWith({
    bool? isLoading,
    String? error,
    int? venueId,
    String? weekEnd,
    String? prevWeekEnd,
    String? nextWeekEnd,
    List<FinancialMetric>? metrics,
    FinancialNotes? notes,
  }) {
    return FinancialState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      venueId: venueId ?? this.venueId,
      weekEnd: weekEnd ?? this.weekEnd,
      prevWeekEnd: prevWeekEnd ?? this.prevWeekEnd,
      nextWeekEnd: nextWeekEnd ?? this.nextWeekEnd,
      metrics: metrics ?? this.metrics,
      notes: notes ?? this.notes,
    );
  }
}

class FinancialController extends StateNotifier<FinancialState> {
  FinancialController(this.ref)
      : super(FinancialState(
          isLoading: true,
          venueId: ref.read(venuesProvider).first.id,
          metrics: const [],
        ));

  final Ref ref;

  Future<void> load({int? venueId, String? weekEnd}) async {
    final token = ref.read(authTokenProvider);
    if (token == null || token.isEmpty) {
      state = state.copyWith(isLoading: false, error: 'Not authenticated');
      return;
    }

    final effectiveVenueId = venueId ?? state.venueId;

    state = state.copyWith(
      isLoading: true,
      error: null,
      venueId: effectiveVenueId,
    );

    try {
      final json = await ref.read(financialRepositoryProvider).fetchVenueSummary(
            venueId: effectiveVenueId,
            weekEndIsoDate: weekEnd,
            token: token,
          );

      // JSON keys align with Snapshot work:
      // weekEnd, prevWeekEnd, nextWeekEnd, metrics[], optional notes
      final weekEndOut = (json['weekEnd'] as String?)?.split('T').first;
      final prevOut = (json['prevWeekEnd'] as String?)?.split('T').first;
      final nextOut = (json['nextWeekEnd'] as String?)?.split('T').first;

      final metricsJson = (json['metrics'] as List? ?? const [])
          .cast<Map<String, dynamic>>();

      final metrics = metricsJson.map((m) {
        final name = (m['metric'] ?? m['name'] ?? '').toString();

        // iOS converts percent/100 => ratio (e.g. 111% => 1.11) :contentReference[oaicite:2]{index=2}
        final weeklyRatio =
            ((m['weeklyPercent'] as num?)?.toDouble() ?? 0) / 100.0;
        final ytdRatio = ((m['ytdPercent'] as num?)?.toDouble() ?? 0) / 100.0;

        final weekAmount = _formatCurrency((m['weeklyActual'] as num?)?.toDouble());
        final ytdAmount = _formatCurrency((m['ytdActual'] as num?)?.toDouble());

        return FinancialMetric(
          name: name,
          weeklyRatio: weeklyRatio,
          ytdRatio: ytdRatio,
          weekAmount: weekAmount,
          ytdAmount: ytdAmount,
        );
      }).toList();

      FinancialNotes? notes;
      final notesJson = json['notes'];
      if (notesJson is Map<String, dynamic>) {
        notes = FinancialNotes(
          hasComment: (notesJson['hasComment'] as bool?) ?? false,
          commentText: notesJson['commentText'] as String?,
          category: notesJson['category'] as String?,
          generalNote: notesJson['generalNote'] as String?,
          hashtags: (notesJson['hashtags'] as List? ?? const [])
              .map((e) => e.toString())
              .toList(),
        );
      }

      state = state.copyWith(
        isLoading: false,
        weekEnd: weekEndOut,
        prevWeekEnd: prevOut,
        nextWeekEnd: nextOut,
        metrics: metrics,
        notes: notes,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  static String _formatCurrency(double? value) {
    if (value == null) return r'$0';
    // Keep it simple & iOS-like (no decimals) like your Swift formatter :contentReference[oaicite:3]{index=3}
    final v = value.round();
    final s = v.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (m) => ',',
    );
    return '\$$s';
  }
}

final financialControllerProvider =
    StateNotifierProvider<FinancialController, FinancialState>((ref) {
  return FinancialController(ref);
});
