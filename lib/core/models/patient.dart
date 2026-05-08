class Patient {
  final String id;
  final String name;
  final String? medicalRecordNumber;
  final DateTime? dateOfBirth;
  final String? gender;
  final List<String> allergies;
  final List<String> conditions;
  final int notesCount;
  final DateTime? lastVisit;
  final DateTime createdAt;

  Patient({
    required this.id,
    required this.name,
    this.medicalRecordNumber,
    this.dateOfBirth,
    this.gender,
    this.allergies = const [],
    this.conditions = const [],
    this.notesCount = 0,
    this.lastVisit,
    required this.createdAt,
  });

  String get initials {
    final parts = name.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  int? get age {
    if (dateOfBirth == null) return null;
    final now = DateTime.now();
    var years = now.year - dateOfBirth!.year;
    if (now.month < dateOfBirth!.month ||
        (now.month == dateOfBirth!.month && now.day < dateOfBirth!.day)) {
      years -= 1;
    }
    return years;
  }

  factory Patient.fromJson(Map<String, dynamic> json) {
    List<String> _strList(dynamic raw) {
      if (raw is List) return raw.map((e) => e.toString()).toList();
      return const [];
    }

    return Patient(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      name: json['name'] as String? ?? 'Unnamed patient',
      medicalRecordNumber: json['mrn'] as String? ?? json['medicalRecordNumber'] as String?,
      dateOfBirth: json['dateOfBirth'] != null
          ? DateTime.tryParse(json['dateOfBirth'] as String)
          : null,
      gender: json['gender'] as String?,
      allergies: _strList(json['allergies']),
      conditions: _strList(json['conditions']),
      notesCount: (json['notesCount'] as num?)?.toInt() ?? 0,
      lastVisit: json['lastVisit'] != null
          ? DateTime.tryParse(json['lastVisit'] as String)
          : null,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
