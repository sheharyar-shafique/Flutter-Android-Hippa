/// Mirrors the web app's ClinicalNote shape (see backend /notes endpoints).
class ClinicalNote {
  final String id;
  final String title;
  final String? patientName;
  final String? specialty;
  final String? templateId;
  final String? templateName;
  final String content;
  final String? transcript;
  final NoteStatus status;
  final int? durationSeconds;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? signedAt;
  final String? signedBy;

  ClinicalNote({
    required this.id,
    required this.title,
    required this.content,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.patientName,
    this.specialty,
    this.templateId,
    this.templateName,
    this.transcript,
    this.durationSeconds,
    this.signedAt,
    this.signedBy,
  });

  bool get isSigned => status == NoteStatus.signed;
  bool get isProcessing => status == NoteStatus.processing;
  bool get isFailed => status == NoteStatus.failed;
  bool get isDraft => status == NoteStatus.draft;

  factory ClinicalNote.fromJson(Map<String, dynamic> json) {
    return ClinicalNote(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      title: json['title'] as String? ?? 'Untitled note',
      patientName: json['patientName'] as String?,
      specialty: json['specialty'] as String?,
      templateId: json['templateId']?.toString(),
      templateName: json['templateName'] as String?,
      content: json['content'] as String? ?? '',
      transcript: json['transcript'] as String?,
      status: NoteStatus.fromString(json['status'] as String?),
      durationSeconds: (json['durationSeconds'] as num?)?.toInt(),
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ?? DateTime.now(),
      signedAt: json['signedAt'] != null
          ? DateTime.tryParse(json['signedAt'] as String)
          : null,
      signedBy: json['signedBy'] as String?,
    );
  }

  ClinicalNote copyWith({
    String? title,
    String? content,
    String? patientName,
    NoteStatus? status,
  }) {
    return ClinicalNote(
      id: id,
      title: title ?? this.title,
      content: content ?? this.content,
      patientName: patientName ?? this.patientName,
      specialty: specialty,
      templateId: templateId,
      templateName: templateName,
      transcript: transcript,
      status: status ?? this.status,
      durationSeconds: durationSeconds,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      signedAt: signedAt,
      signedBy: signedBy,
    );
  }
}

enum NoteStatus {
  draft,
  processing,
  ready,
  signed,
  failed;

  static NoteStatus fromString(String? raw) {
    switch (raw) {
      case 'processing':
        return NoteStatus.processing;
      case 'ready':
        return NoteStatus.ready;
      case 'signed':
        return NoteStatus.signed;
      case 'failed':
        return NoteStatus.failed;
      default:
        return NoteStatus.draft;
    }
  }

  String get label {
    switch (this) {
      case NoteStatus.draft:
        return 'Draft';
      case NoteStatus.processing:
        return 'Processing…';
      case NoteStatus.ready:
        return 'Ready';
      case NoteStatus.signed:
        return 'Signed';
      case NoteStatus.failed:
        return 'Failed';
    }
  }
}
