import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import '../../../core/api_client.dart';
import 'sevenrooms_review_models.dart';

class SevenRoomsReviewRepository {
  final ApiClient api;
  SevenRoomsReviewRepository(this.api);

  Future<void> submitReview(SevenRoomsReviewDraft draft) async {
    if (draft.venueId == null) throw Exception('Venue not selected');
    if (!draft.allScored) throw Exception('All categories must be scored (1–5)');
    if (draft.classification == null || draft.classification!.trim().isEmpty) {
      throw Exception('Classification required');
    }

    final scoresPayload = draft.scores.map((s) => {
          'category': s.category,
          'score1to5': s.score1to5,
          'weightPct': s.weightPct,
          'comments': s.comments,
        }).toList();

    final form = FormData.fromMap({
      'venueId': draft.venueId,
      'reviewDate': draft.reviewDate.toIso8601String(),
      'reviewerName': draft.reviewerName,
      'classification': draft.classification,
      'notes': draft.notes,
      'scoresJson': jsonEncode(scoresPayload),
    });

    // Optional attachments (same rule as Feedback: MultipartFile is single-use)
    for (final f in draft.attachments) {
      final name = f.path.split(Platform.pathSeparator).last;
      form.files.add(MapEntry(
        'attachments',
        await MultipartFile.fromFile(f.path, filename: name),
      ));
    }

    await api.dio.post('/api/sevenroomsreviews', data: form);
  }
}
