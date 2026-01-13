class Venue {
  final int id;
  final String name;

  const Venue({required this.id, required this.name});

  static int _int(dynamic v, {int fallback = 0}) {
    if (v == null) return fallback;
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? fallback;
    return fallback;
  }

  factory Venue.fromJson(Map<String, dynamic> json) {
    // Support common shapes:
    //  - { id: 26, name: "Group" }
    //  - { venueId: 26, venueName: "Group" }
    //  - { code: "26", name: "Group" }
    final id = _int(json['id'],
        fallback: _int(json['venueId'],
            fallback: _int(json['code'], fallback: 0)));

    final name = (json['name'] as String?) ??
        (json['venueName'] as String?) ??
        'Venue';

    // If API ever returns an empty/null id, still keep it stable
    return Venue(id: id, name: name);
  }
}
