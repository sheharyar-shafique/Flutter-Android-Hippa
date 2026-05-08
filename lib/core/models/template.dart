/// Mirrors `frontend/src/types/index.ts:Template`. The Flutter app deals
/// with both server-stored custom templates and the bundled default library
/// in `core/data/default_templates.dart`.
class NoteTemplate {
  final String id;
  final String name;
  final String description;
  final String specialty;
  final List<String> sections;
  final bool isCustom;
  final bool isDefault;
  final DateTime? updatedAt;

  /// Server primary key for custom templates (null for built-ins).
  final String? dbId;

  const NoteTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.specialty,
    this.sections = const [],
    this.isCustom = false,
    this.isDefault = false,
    this.updatedAt,
    this.dbId,
  });

  factory NoteTemplate.fromJson(Map<String, dynamic> json) {
    final raw = json['sections'];
    final sections = raw is List
        ? raw.map((e) => e.toString()).toList()
        : <String>[];
    return NoteTemplate(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      name: json['name'] as String? ?? 'Untitled template',
      description: json['description'] as String? ?? '',
      specialty: json['specialty'] as String? ?? 'General',
      sections: sections,
      isCustom: json['isCustom'] == true || json['custom'] == true,
      isDefault: json['isDefault'] == true,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String)
          : null,
      dbId: json['dbId'] as String? ?? json['_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'specialty': specialty,
        'sections': sections,
        if (isCustom) 'isCustom': isCustom,
        if (isDefault) 'isDefault': isDefault,
        if (dbId != null) 'dbId': dbId,
        if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
      };

  NoteTemplate copyWith({
    String? id,
    String? name,
    String? description,
    String? specialty,
    List<String>? sections,
    bool? isCustom,
    bool? isDefault,
    String? dbId,
    DateTime? updatedAt,
  }) =>
      NoteTemplate(
        id: id ?? this.id,
        name: name ?? this.name,
        description: description ?? this.description,
        specialty: specialty ?? this.specialty,
        sections: sections ?? this.sections,
        isCustom: isCustom ?? this.isCustom,
        isDefault: isDefault ?? this.isDefault,
        dbId: dbId ?? this.dbId,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}
