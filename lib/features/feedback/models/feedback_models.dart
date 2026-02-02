enum FeedbackType { bug, issue, idea, featureRequest }
enum FeedbackSeverity { low, medium, high, critical }

String feedbackTypeToApi(FeedbackType t) {
  switch (t) {
    case FeedbackType.bug: return 'Bug';
    case FeedbackType.issue: return 'Issue';
    case FeedbackType.idea: return 'Idea';
    case FeedbackType.featureRequest: return 'FeatureRequest';
  }
}

String feedbackSeverityToApi(FeedbackSeverity s) {
  switch (s) {
    case FeedbackSeverity.low: return 'Low';
    case FeedbackSeverity.medium: return 'Medium';
    case FeedbackSeverity.high: return 'High';
    case FeedbackSeverity.critical: return 'Critical';
  }
}

/// Response: keep flexible because your API might return PublicId, FeedbackId, etc.
class CreateFeedbackResponse {
  final int? feedbackId;
  final String? publicId;
  final String? message;

  CreateFeedbackResponse({this.feedbackId, this.publicId, this.message});

  factory CreateFeedbackResponse.fromJson(Map<String, dynamic> json) {
    return CreateFeedbackResponse(
      feedbackId: (json['feedbackId'] is int) ? json['feedbackId'] as int : null,
      publicId: (json['publicId'] as String?) ?? (json['PublicId'] as String?),
      message: json['message'] as String?,
    );
  }
}
