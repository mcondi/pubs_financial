import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/sevenrooms_review_models.dart';

final sevenRoomsReviewDraftProvider =
    StateNotifierProvider<SevenRoomsReviewDraftController, SevenRoomsReviewDraft>(
  (ref) => SevenRoomsReviewDraftController(),
);

class SevenRoomsReviewDraftController extends StateNotifier<SevenRoomsReviewDraft> {
  SevenRoomsReviewDraftController() : super(SevenRoomsReviewDraft.initial());

  void reset() => state = SevenRoomsReviewDraft.initial();

  void setVenue(int venueId) => state = state.copyWith(venueId: venueId);
  void setDate(DateTime d) => state = state.copyWith(reviewDate: d);
  void setReviewerName(String v) => state = state.copyWith(reviewerName: v);
  void setClassification(String v) => state = state.copyWith(classification: v);
  void setNotes(String v) => state = state.copyWith(notes: v);

  void setScore(String category, int score1to5) {
    final updated = state.scores.map((s) {
      if (s.category == category) return s.copyWith(score1to5: score1to5);
      return s;
    }).toList();
    state = state.copyWith(scores: updated);
  }

  void setComments(String category, String comments) {
    final updated = state.scores.map((s) {
      if (s.category == category) return s.copyWith(comments: comments);
      return s;
    }).toList();
    state = state.copyWith(scores: updated);
  }

  void addAttachment(File f) => state = state.copyWith(attachments: [...state.attachments, f]);

  void removeAttachmentAt(int idx) {
    final list = [...state.attachments];
    if (idx < 0 || idx >= list.length) return;
    list.removeAt(idx);
    state = state.copyWith(attachments: list);
  }
}
