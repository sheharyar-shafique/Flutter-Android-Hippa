class NoteTemplate {
  final String id;
  final String name;
  final String? specialty;
  final String? description;
  final String? structure;
  final bool isCustom;
  final DateTime? updatedAt;

  NoteTemplate({
    required this.id,
    required this.name,
    this.specialty,
    this.description,
    this.structure,
    this.isCustom = false,
    this.updatedAt,
  });

  factory NoteTemplate.fromJson(Map<String, dynamic> json) {
    return NoteTemplate(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      name: json['name'] as String? ?? 'Untitled template',
      specialty: json['specialty'] as String?,
      description: json['description'] as String?,
      structure: json['structure'] as String?,
      isCustom: json['isCustom'] == true || json['custom'] == true,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String)
          : null,
    );
  }
}
