class TrendsVenue {
  final int id; // venueId
  final String name;
  final String region;

  final double currYtdRevenue;
  final double prevYtdRevenue;
  final double currYtdEbitda;
  final double prevYtdEbitda;

  final double? currYtdBudgetRevenue;
  final double? currYtdBudgetEbitda;

  TrendsVenue({
    required this.id,
    required this.name,
    required this.region,
    required this.currYtdRevenue,
    required this.prevYtdRevenue,
    required this.currYtdEbitda,
    required this.prevYtdEbitda,
    this.currYtdBudgetRevenue,
    this.currYtdBudgetEbitda,
  });

  factory TrendsVenue.fromJson(Map<String, dynamic> json) {
    double numVal(String k) => (json[k] as num).toDouble();
    double? numOpt(String k) => json[k] == null ? null : (json[k] as num).toDouble();

    return TrendsVenue(
      id: (json['venueId'] as num).toInt(),
      name: (json['name'] as String?) ?? '',
      region: (json['region'] as String?) ?? '',
      currYtdRevenue: numVal('currYtdRevenue'),
      prevYtdRevenue: numVal('prevYtdRevenue'),
      currYtdEbitda: numVal('currYtdEbitda'),
      prevYtdEbitda: numVal('prevYtdEbitda'),
      currYtdBudgetRevenue: numOpt('currYtdBudgetRevenue'),
      currYtdBudgetEbitda: numOpt('currYtdBudgetEbitda'),
    );
  }
}

class TrendsVenueWeeklySummary {
  final String venueName;
  final String weekEnd; // ISO
  final String? prevWeekEnd; // ISO
  final String? nextWeekEnd; // ISO

  final double currYtdRevenue;
  final double prevYtdRevenue;
  final double currYtdEbitda;
  final double prevYtdEbitda;

  final double? currYtdBudgetRevenue;
  final double? currYtdBudgetEbitda;

  TrendsVenueWeeklySummary({
    required this.venueName,
    required this.weekEnd,
    required this.prevWeekEnd,
    required this.nextWeekEnd,
    required this.currYtdRevenue,
    required this.prevYtdRevenue,
    required this.currYtdEbitda,
    required this.prevYtdEbitda,
    required this.currYtdBudgetRevenue,
    required this.currYtdBudgetEbitda,
  });

  factory TrendsVenueWeeklySummary.fromJson(Map<String, dynamic> json) {
    dynamic pick(String a, String b) => json.containsKey(a) ? json[a] : json[b];

    double numReq(String a, String b) => (pick(a, b) as num).toDouble();
    double? numOpt(String a, String b) {
      final v = pick(a, b);
      return v == null ? null : (v as num).toDouble();
    }

    return TrendsVenueWeeklySummary(
      venueName: (pick('venueName', 'venue_name') as String?) ?? '',
      weekEnd: (pick('weekEnd', 'week_end') as String?) ?? '',
      prevWeekEnd: pick('prevWeekEnd', 'prev_week_end') as String?,
      nextWeekEnd: pick('nextWeekEnd', 'next_week_end') as String?,
      currYtdRevenue: numReq('currYtdRevenue', 'curr_ytd_revenue'),
      prevYtdRevenue: numReq('prevYtdRevenue', 'prev_ytd_revenue'),
      currYtdEbitda: numReq('currYtdEbitda', 'curr_ytd_ebitda'),
      prevYtdEbitda: numReq('prevYtdEbitda', 'prev_ytd_ebitda'),
      currYtdBudgetRevenue: numOpt('currYtdBudgetRevenue', 'curr_ytd_budget_revenue'),
      currYtdBudgetEbitda: numOpt('currYtdBudgetEbitda', 'curr_ytd_budget_ebitda'),
    );
  }
}

/// GET /v1/notes/week?weekEndISO=YYYY-MM-DD&venueId=#
class WeekNotesResponse {
  final int? weekNoteId;
  final String category;
  final String? generalNote;
  final List<String> hashtags;

  WeekNotesResponse({
    required this.weekNoteId,
    required this.category,
    required this.generalNote,
    required this.hashtags,
  });

  factory WeekNotesResponse.fromJson(Map<String, dynamic> json) {
    return WeekNotesResponse(
      weekNoteId: (json['weekNoteId'] as num?)?.toInt(),
      category: (json['category'] as String?) ?? '',
      generalNote: json['generalNote'] as String?,
      hashtags: (json['hashtags'] as List?)?.map((e) => e.toString()).toList() ?? const [],
    );
  }
}
