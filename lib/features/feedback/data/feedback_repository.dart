import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../core/api_client.dart';
import '../models/feedback_models.dart';

class FeedbackRepository {
  final ApiClient api;

  FeedbackRepository(this.api);

  Future<CreateFeedbackResponse> createFeedback({
    required String title,
    required String description,
    required FeedbackType type,
    required FeedbackSeverity severity,
    required bool isAnonymous,
    String? reporterName,
    String? reporterEmail,
    String? source,
    List<File> attachments = const [],
  }) async {
    final typeStr = feedbackTypeToApi(type);
    final severityStr = feedbackSeverityToApi(severity);

    final fields = <String, dynamic>{
      'title': title,
      'description': description,

      // Main expected names
      'feedbackType': typeStr,
      'severity': severityStr,
      'isAnonymous': isAnonymous ? 'true' : 'false',

      // Aliases to survive DTO naming differences
      'type': typeStr,
      'FeedbackType': typeStr,
      'Severity': severityStr,
      'IsAnonymous': isAnonymous ? 'true' : 'false',
    };

    if (!isAnonymous) {
      if (reporterName != null && reporterName.trim().isNotEmpty) {
        fields['reporterName'] = reporterName.trim();
        fields['ReporterName'] = reporterName.trim();
      }
      if (reporterEmail != null && reporterEmail.trim().isNotEmpty) {
        fields['reporterEmail'] = reporterEmail.trim();
        fields['ReporterEmail'] = reporterEmail.trim();
      }
    }

    if (source != null && source.trim().isNotEmpty) {
      fields['source'] = source.trim();
      fields['Source'] = source.trim();
    }

    final formData = FormData.fromMap(fields);

    // IMPORTANT:
    // Dio MultipartFile objects are single-use. If we want to include the same
    // physical file under multiple keys, we MUST create a new MultipartFile
    // for each key (or use clone()).
    for (final f in attachments) {
      final fileName = f.path.split(Platform.pathSeparator).last;

      final mf1 = await MultipartFile.fromFile(
        f.path,
        filename: fileName,
      );
      formData.files.add(MapEntry('attachments', mf1));

      // Add under 'files' too (some controllers use List<IFormFile> files)
      final mf2 = await MultipartFile.fromFile(
        f.path,
        filename: fileName,
      );
      formData.files.add(MapEntry('files', mf2));
    }

    if (kDebugMode) {
      debugPrint('FEEDBACK ▶ POST /api/Feedback');
      debugPrint('FEEDBACK ▶ fields: ${fields.keys.toList()}');
      debugPrint('FEEDBACK ▶ attachments count: ${attachments.length}');
      if (attachments.isNotEmpty) {
        debugPrint('FEEDBACK ▶ attaching files under keys: attachments + files (duplicated MultipartFile instances)');
      }
    }

    final res = await api.dio.post(
      '/api/Feedback',
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );

    return api.decodeOrThrow(res, (json) => CreateFeedbackResponse.fromJson(json));
  }
}
