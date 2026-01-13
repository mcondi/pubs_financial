class AfterActionTaskDto {
  final String taskType;
  final int afterActionId;
  final int venueId;
  final String venueName;
  final String eventName;
  final DateTime startDate;
  final DateTime endDate;
  final DateTime updatedUtc;
  final int priority;

  AfterActionTaskDto({
    required this.taskType,
    required this.afterActionId,
    required this.venueId,
    required this.venueName,
    required this.eventName,
    required this.startDate,
    required this.endDate,
    required this.updatedUtc,
    required this.priority,
  });

  factory AfterActionTaskDto.fromJson(Map<String, dynamic> j) => AfterActionTaskDto(
        taskType: (j['taskType'] ?? '').toString(),
        afterActionId: _asInt(j['afterActionId']),
        venueId: _asInt(j['venueId']),
        venueName: (j['venueName'] ?? '').toString(),
        eventName: (j['eventName'] ?? '').toString(),
        startDate: _asDate(j['startDate']),
        endDate: _asDate(j['endDate']),
        updatedUtc: _asDate(j['updatedUtc']),
        priority: _asInt(j['priority']),
      );

  String get taskTypeLabel {
    switch (taskType.toLowerCase()) {
      case 'respond':
        return 'Respond required';
      case 'owner_complete':
        return 'Owner completion required';
      case 'read':
        return 'Read required';
      default:
        return taskType;
    }
  }

  // Colors match intent (orange/blue/purple)
  int get taskTypeColorArgb {
    switch (taskType.toLowerCase()) {
      case 'respond':
        return 0xFFFF9800; // orange
      case 'owner_complete':
        return 0xFF2196F3; // blue
      case 'read':
        return 0xFF9C27B0; // purple
      default:
        return 0xFFB0BEC5; // grey-ish
    }
  }
}

class AfterActionListItemDto {
  final int afterActionId;
  final int venueId;
  final String venueName;
  final String eventName;
  final DateTime startDate;
  final DateTime endDate;
  final String ownerUserName;
  final DateTime updatedUtc;

  final int responseCount;
  final double? avgRating;
  final int pendingCount;
  final bool isCompleted;

  AfterActionListItemDto({
    required this.afterActionId,
    required this.venueId,
    required this.venueName,
    required this.eventName,
    required this.startDate,
    required this.endDate,
    required this.ownerUserName,
    required this.updatedUtc,
    required this.responseCount,
    required this.avgRating,
    required this.pendingCount,
    required this.isCompleted,
  });

  factory AfterActionListItemDto.fromJson(Map<String, dynamic> j) => AfterActionListItemDto(
        afterActionId: _asInt(j['afterActionId']),
        venueId: _asInt(j['venueId']),
        venueName: (j['venueName'] ?? '').toString(),
        eventName: (j['eventName'] ?? '').toString(),
        startDate: _asDate(j['startDate']),
        endDate: _asDate(j['endDate']),
        ownerUserName: (j['ownerUserName'] ?? '').toString(),
        updatedUtc: _asDate(j['updatedUtc']),
        responseCount: _asInt(j['responseCount']),
        avgRating: _asDoubleOrNull(j['avgRating']),
        pendingCount: _asInt(j['pendingCount']),
        isCompleted: (j['isCompleted'] as bool?) ?? false,
      );
}

class AfterActionDetailDto {
  final int afterActionId;
  final int venueId;
  final String venueName;
  final String eventName;
  final DateTime startDate;
  final DateTime endDate;
  final String ownerUserName;
  final DateTime updatedUtc;

  final int responseCount;
  final double? avgRating;
  final int pendingCount;
  final bool isCompleted;

  final String? overallSummary;
  final String? whatWorked;
  final String? whatDidnt;
  final String? top3Lessons;
  final String? top3ActionsNextTime;

  final String? allWorked;
  final String? allDidnt;
  final String? allNotes;

  final List<String> actionBullets;

  AfterActionDetailDto({
    required this.afterActionId,
    required this.venueId,
    required this.venueName,
    required this.eventName,
    required this.startDate,
    required this.endDate,
    required this.ownerUserName,
    required this.updatedUtc,
    required this.responseCount,
    required this.avgRating,
    required this.pendingCount,
    required this.isCompleted,
    required this.overallSummary,
    required this.whatWorked,
    required this.whatDidnt,
    required this.top3Lessons,
    required this.top3ActionsNextTime,
    required this.allWorked,
    required this.allDidnt,
    required this.allNotes,
    required this.actionBullets,
  });

  factory AfterActionDetailDto.fromJson(Map<String, dynamic> j) => AfterActionDetailDto(
        afterActionId: _asInt(j['afterActionId']),
        venueId: _asInt(j['venueId']),
        venueName: (j['venueName'] ?? '').toString(),
        eventName: (j['eventName'] ?? '').toString(),
        startDate: _asDate(j['startDate']),
        endDate: _asDate(j['endDate']),
        ownerUserName: (j['ownerUserName'] ?? '').toString(),
        updatedUtc: _asDate(j['updatedUtc']),
        responseCount: _asInt(j['responseCount']),
        avgRating: _asDoubleOrNull(j['avgRating']),
        pendingCount: _asInt(j['pendingCount']),
        isCompleted: (j['isCompleted'] as bool?) ?? false,
        overallSummary: _asStringOrNull(j['overallSummary']),
        whatWorked: _asStringOrNull(j['whatWorked']),
        whatDidnt: _asStringOrNull(j['whatDidnt']),
        top3Lessons: _asStringOrNull(j['top3Lessons']),
        top3ActionsNextTime: _asStringOrNull(j['top3ActionsNextTime']),
        allWorked: _asStringOrNull(j['allWorked']),
        allDidnt: _asStringOrNull(j['allDidnt']),
        allNotes: _asStringOrNull(j['allNotes']),
        actionBullets: (j['actionBullets'] as List? ?? const [])
            .map((e) => e.toString())
            .where((s) => s.trim().isNotEmpty)
            .toList(),
      );
}

/// ---- helpers ----
int _asInt(dynamic v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? 0;
  return 0;
}

double? _asDoubleOrNull(dynamic v) {
  if (v == null) return null;
  if (v is double) return v;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v);
  return null;
}

String? _asStringOrNull(dynamic v) {
  if (v == null) return null;
  final s = v.toString();
  return s.trim().isEmpty ? null : s;
}

DateTime _asDate(dynamic v) {
  if (v is DateTime) return v;
  if (v is String) {
    final dt = DateTime.tryParse(v);
    if (dt != null) return dt;
    // if it comes without timezone, treat as UTC-ish
    return DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
  }
  return DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
}
