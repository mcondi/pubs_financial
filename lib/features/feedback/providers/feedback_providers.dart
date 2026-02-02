import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api_providers.dart';
import '../data/feedback_repository.dart';
import '../models/feedback_models.dart';

final feedbackRepositoryProvider = Provider<FeedbackRepository>((ref) {
  final api = ref.watch(apiClientProvider);
  return FeedbackRepository(api);
});

class FeedbackSubmitState {
  final bool isSubmitting;
  final String? error;
  final CreateFeedbackResponse? result;

  const FeedbackSubmitState({
    this.isSubmitting = false,
    this.error,
    this.result,
  });

  FeedbackSubmitState copyWith({
    bool? isSubmitting,
    String? error,
    CreateFeedbackResponse? result,
  }) {
    return FeedbackSubmitState(
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: error,
      result: result,
    );
  }
}

class FeedbackSubmitNotifier extends StateNotifier<FeedbackSubmitState> {
  final FeedbackRepository repo;

  FeedbackSubmitNotifier(this.repo) : super(const FeedbackSubmitState());

  Future<void> submit({
    required String title,
    required String description,
    required FeedbackType type,
    required FeedbackSeverity severity,
    required bool isAnonymous,
    String? reporterName,
    String? reporterEmail,
    List<File> attachments = const [],
  }) async {
    state = state.copyWith(isSubmitting: true, error: null, result: null);

    try {
      final res = await repo.createFeedback(
        title: title,
        description: description,
        type: type,
        severity: severity,
        isAnonymous: isAnonymous,
        reporterName: reporterName,
        reporterEmail: reporterEmail,
        source: 'Flutter',
        attachments: attachments,
      );

      state = state.copyWith(isSubmitting: false, result: res);
    } catch (e) {
      state = state.copyWith(isSubmitting: false, error: e.toString());
    }
  }

  void reset() => state = const FeedbackSubmitState();
}

final feedbackSubmitProvider =
    StateNotifierProvider<FeedbackSubmitNotifier, FeedbackSubmitState>((ref) {
  final repo = ref.watch(feedbackRepositoryProvider);
  return FeedbackSubmitNotifier(repo);
});
