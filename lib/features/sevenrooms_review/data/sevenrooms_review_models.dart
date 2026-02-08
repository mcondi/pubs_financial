import 'dart:io';

class SevenRoomsCategoryDef {
  final String key;
  final int weightPct;
  final String help;
  const SevenRoomsCategoryDef({
    required this.key,
    required this.weightPct,
    required this.help,
  });
}

const sevenRoomsCategories = <SevenRoomsCategoryDef>[
  SevenRoomsCategoryDef(
    key: 'Daily Usage & Discipline',
    weightPct: 25,
    help:
        'Daily booking sheet reviewed before service, VIPs/regulars identified, walk-ins logged, seating completed in SevenRooms.',
  ),
  SevenRoomsCategoryDef(
    key: 'Guest Data Quality',
    weightPct: 20,
    help:
        'Email/phone captured, tags used consistently, preferences recorded (seats/drinks), duplicates merged.',
  ),
  SevenRoomsCategoryDef(
    key: 'Marketing & EDM Usage',
    weightPct: 15,
    help:
        'EDMs/campaigns sent, segmentation used (VIP/lapsed), direct booking links used, measurable outcomes.',
  ),
  SevenRoomsCategoryDef(
    key: 'Revenue & Inventory Control',
    weightPct: 20,
    help:
        'Turn times aligned, access rules/blocks used, deposits/CC holds where needed, peak periods protected.',
  ),
  SevenRoomsCategoryDef(
    key: 'Reporting & Ownership',
    weightPct: 20,
    help:
        'VM can run core reports, understands no-shows/channel mix, clear owner at venue, training enforced.',
  ),
];

class SevenRoomsScoreDraft {
  final String category;
  final int weightPct;
  final int score1to5; // 0 = not set
  final String comments;

  SevenRoomsScoreDraft({
    required this.category,
    required this.weightPct,
    required this.score1to5,
    required this.comments,
  });

  SevenRoomsScoreDraft copyWith({
    int? score1to5,
    String? comments,
  }) {
    return SevenRoomsScoreDraft(
      category: category,
      weightPct: weightPct,
      score1to5: score1to5 ?? this.score1to5,
      comments: comments ?? this.comments,
    );
  }
}

class SevenRoomsReviewDraft {
  final int? venueId;
  final DateTime reviewDate;
  final String reviewerName;
  final String? classification; // required at submit
  final String notes;

  final List<SevenRoomsScoreDraft> scores;
  final List<File> attachments;

  SevenRoomsReviewDraft({
    required this.venueId,
    required this.reviewDate,
    required this.reviewerName,
    required this.classification,
    required this.notes,
    required this.scores,
    required this.attachments,
  });

  factory SevenRoomsReviewDraft.initial() {
    return SevenRoomsReviewDraft(
      venueId: null,
      reviewDate: DateTime.now(),
      reviewerName: '',
      classification: null,
      notes: '',
      scores: sevenRoomsCategories
          .map((c) => SevenRoomsScoreDraft(
                category: c.key,
                weightPct: c.weightPct,
                score1to5: 0,
                comments: '',
              ))
          .toList(),
      attachments: const [],
    );
  }

  SevenRoomsReviewDraft copyWith({
    int? venueId,
    DateTime? reviewDate,
    String? reviewerName,
    String? classification,
    String? notes,
    List<SevenRoomsScoreDraft>? scores,
    List<File>? attachments,
  }) {
    return SevenRoomsReviewDraft(
      venueId: venueId ?? this.venueId,
      reviewDate: reviewDate ?? this.reviewDate,
      reviewerName: reviewerName ?? this.reviewerName,
      classification: classification ?? this.classification,
      notes: notes ?? this.notes,
      scores: scores ?? this.scores,
      attachments: attachments ?? this.attachments,
    );
  }

  bool get allScored => scores.every((s) => s.score1to5 >= 1 && s.score1to5 <= 5);
}
