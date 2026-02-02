class ProjectListItemDto {
  final int projectId;
  final String projectName;
  final String venueName;
  final DateTime updatedUtc;

  ProjectListItemDto({
    required this.projectId,
    required this.projectName,
    required this.venueName,
    required this.updatedUtc,
  });

  factory ProjectListItemDto.fromJson(Map<String, dynamic> j) => ProjectListItemDto(
        projectId: _asInt(j['projectId']),
        projectName: (j['projectName'] ?? '').toString(),
        venueName: (j['venueName'] ?? '').toString(),
        updatedUtc: _asDate(j['updatedUtc']),
      );
}

class ProjectDetailDto {
  final int projectId;
  final String projectName;
  final String venueName;
  final String? description;
  final DateTime updatedUtc;

  final List<ProjectCapexItemDto> capex;
  final List<ProjectPlanFileDto> plans;

  ProjectDetailDto({
    required this.projectId,
    required this.projectName,
    required this.venueName,
    required this.description,
    required this.updatedUtc,
    required this.capex,
    required this.plans,
  });

  factory ProjectDetailDto.fromJson(Map<String, dynamic> j) => ProjectDetailDto(
        projectId: _asInt(j['projectId']),
        projectName: (j['projectName'] ?? '').toString(),
        venueName: (j['venueName'] ?? '').toString(),
        description: _asStringOrNull(j['description']),
        updatedUtc: _asDate(j['updatedUtc']),
        capex: (j['capex'] as List? ?? const [])
            .whereType<Map>()
            .map((e) => ProjectCapexItemDto.fromJson(e.cast<String, dynamic>()))
            .toList(),
        plans: (j['plans'] as List? ?? const [])
            .whereType<Map>()
            .map((e) => ProjectPlanFileDto.fromJson(e.cast<String, dynamic>()))
            .toList(),
      );
}

class ProjectCapexItemDto {
  final int capexId;
  final String itemName;
  final double cost;
  final String costType;
  final String? notes;
  final String? quoteUrl;

  ProjectCapexItemDto({
    required this.capexId,
    required this.itemName,
    required this.cost,
    required this.costType,
    required this.notes,
    required this.quoteUrl,
  });

  factory ProjectCapexItemDto.fromJson(Map<String, dynamic> j) => ProjectCapexItemDto(
        capexId: _asInt(j['capexId']),
        itemName: (j['itemName'] ?? '').toString(),
        cost: _asDouble(j['cost']),
        costType: (j['costType'] ?? '').toString(),
        notes: _asStringOrNull(j['notes']),
        quoteUrl: _asStringOrNull(j['quoteUrl']),
      );
}

class ProjectPlanFileDto {
  final int planFileId;
  final String fileName;
  final String? notes;
  final String? blobUrl;
  final DateTime uploadedAt;

  ProjectPlanFileDto({
    required this.planFileId,
    required this.fileName,
    required this.notes,
    required this.blobUrl,
    required this.uploadedAt,
  });

  factory ProjectPlanFileDto.fromJson(Map<String, dynamic> j) => ProjectPlanFileDto(
        planFileId: _asInt(j['planFileId']),
        fileName: (j['fileName'] ?? '').toString(),
        notes: _asStringOrNull(j['notes']),
        blobUrl: _asStringOrNull(j['blobUrl']),
        uploadedAt: _asDate(j['uploadedAt']),
      );
}

/// ---- helpers (copied from after_action_models.dart pattern) ----
int _asInt(dynamic v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? 0;
  return 0;
}

double _asDouble(dynamic v) {
  if (v is double) return v;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? 0.0;
  return 0.0;
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
    return DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
  }
  return DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
}
