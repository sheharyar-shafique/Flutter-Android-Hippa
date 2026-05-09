/// Mirrors the web app's ClinicalNote + NoteContent shape (see backend
/// /notes endpoints and frontend/src/types/index.ts).
///
/// Backend returns `content` as either a JSON object (modern notes) or a
/// plain string (legacy notes / mock seeds). NoteContent.fromJson handles
/// both transparently.

class NoteContent {
  /// Short clinical title for the note ("4–8 words"). GPT emits this on
  /// the modern prompt; older notes don't have it. Editor falls back to
  /// the first sentence of chiefComplaint / assessment / etc.
  final String? topic;

  // ── Core SOAP ──────────────────────────────────────────────────────
  final String? subjective;
  final String? objective;
  final String? assessment;
  final String? plan;
  final String? instructions;

  // ── Multi-specialty extras ─────────────────────────────────────────
  final String? chiefComplaint;
  final String? historyOfPresentIllness;
  final String? reviewOfSystems;
  final String? physicalExam;
  final String? followUp;
  final String? medicalDecisionMaking;

  /// Anything the GPT pipeline emits that doesn't have a typed slot lands
  /// here. Editor renders these last as raw key/value sections.
  final Map<String, String> customSections;

  /// Plain-text fallback for legacy notes that came back as a single
  /// string. When this is non-empty, structured fields are likely empty.
  final String legacyText;

  const NoteContent({
    this.topic,
    this.subjective,
    this.objective,
    this.assessment,
    this.plan,
    this.instructions,
    this.chiefComplaint,
    this.historyOfPresentIllness,
    this.reviewOfSystems,
    this.physicalExam,
    this.followUp,
    this.medicalDecisionMaking,
    this.customSections = const {},
    this.legacyText = '',
  });

  bool get isEmpty =>
      (topic ?? '').isEmpty &&
      (subjective ?? '').isEmpty &&
      (objective ?? '').isEmpty &&
      (assessment ?? '').isEmpty &&
      (plan ?? '').isEmpty &&
      (instructions ?? '').isEmpty &&
      (chiefComplaint ?? '').isEmpty &&
      (historyOfPresentIllness ?? '').isEmpty &&
      (reviewOfSystems ?? '').isEmpty &&
      (physicalExam ?? '').isEmpty &&
      (followUp ?? '').isEmpty &&
      (medicalDecisionMaking ?? '').isEmpty &&
      customSections.isEmpty &&
      legacyText.isEmpty;

  factory NoteContent.empty() => const NoteContent();

  /// Accepts either a Map (modern structured note) or a String (legacy).
  factory NoteContent.from(dynamic raw) {
    if (raw is String) {
      return NoteContent(legacyText: raw);
    }
    if (raw is! Map) return NoteContent.empty();
    final json = Map<String, dynamic>.from(raw);

    String? s(String key) {
      final v = json[key];
      if (v is String) return v;
      return null;
    }

    final knownKeys = <String>{
      'topic',
      'subjective',
      'objective',
      'assessment',
      'plan',
      'instructions',
      'chiefComplaint',
      'historyOfPresentIllness',
      'reviewOfSystems',
      'physicalExam',
      'followUp',
      'medicalDecisionMaking',
      'customSections',
    };

    final customs = <String, String>{};
    final embeddedCustom = json['customSections'];
    if (embeddedCustom is Map) {
      for (final entry in embeddedCustom.entries) {
        if (entry.value is String) customs[entry.key.toString()] = entry.value as String;
      }
    }
    // Promote any unrecognised top-level string fields into customSections
    // so the editor still renders them.
    for (final entry in json.entries) {
      if (knownKeys.contains(entry.key)) continue;
      if (entry.value is String) customs[entry.key] = entry.value as String;
    }

    return NoteContent(
      topic: s('topic'),
      subjective: s('subjective'),
      objective: s('objective'),
      assessment: s('assessment'),
      plan: s('plan'),
      instructions: s('instructions'),
      chiefComplaint: s('chiefComplaint'),
      historyOfPresentIllness: s('historyOfPresentIllness'),
      reviewOfSystems: s('reviewOfSystems'),
      physicalExam: s('physicalExam'),
      followUp: s('followUp'),
      medicalDecisionMaking: s('medicalDecisionMaking'),
      customSections: customs,
      legacyText: '',
    );
  }

  Map<String, dynamic> toJson() {
    final out = <String, dynamic>{};
    void put(String key, String? v) {
      if (v != null) out[key] = v;
    }

    put('topic', topic);
    put('subjective', subjective);
    put('objective', objective);
    put('assessment', assessment);
    put('plan', plan);
    put('instructions', instructions);
    put('chiefComplaint', chiefComplaint);
    put('historyOfPresentIllness', historyOfPresentIllness);
    put('reviewOfSystems', reviewOfSystems);
    put('physicalExam', physicalExam);
    put('followUp', followUp);
    put('medicalDecisionMaking', medicalDecisionMaking);
    if (customSections.isNotEmpty) out['customSections'] = customSections;
    return out;
  }

  /// Used by the editor to immutably update a single field while the
  /// user is typing.
  NoteContent setField(String key, String value) {
    switch (key) {
      case 'topic':
        return copyWith(topic: value);
      case 'subjective':
        return copyWith(subjective: value);
      case 'objective':
        return copyWith(objective: value);
      case 'assessment':
        return copyWith(assessment: value);
      case 'plan':
        return copyWith(plan: value);
      case 'instructions':
        return copyWith(instructions: value);
      case 'chiefComplaint':
        return copyWith(chiefComplaint: value);
      case 'historyOfPresentIllness':
        return copyWith(historyOfPresentIllness: value);
      case 'reviewOfSystems':
        return copyWith(reviewOfSystems: value);
      case 'physicalExam':
        return copyWith(physicalExam: value);
      case 'followUp':
        return copyWith(followUp: value);
      case 'medicalDecisionMaking':
        return copyWith(medicalDecisionMaking: value);
      default:
        // Custom section
        final next = Map<String, String>.from(customSections);
        next[key] = value;
        return copyWith(customSections: next);
    }
  }

  /// Get the value for any field name (typed or custom).
  String getField(String key) {
    switch (key) {
      case 'topic':
        return topic ?? '';
      case 'subjective':
        return subjective ?? '';
      case 'objective':
        return objective ?? '';
      case 'assessment':
        return assessment ?? '';
      case 'plan':
        return plan ?? '';
      case 'instructions':
        return instructions ?? '';
      case 'chiefComplaint':
        return chiefComplaint ?? '';
      case 'historyOfPresentIllness':
        return historyOfPresentIllness ?? '';
      case 'reviewOfSystems':
        return reviewOfSystems ?? '';
      case 'physicalExam':
        return physicalExam ?? '';
      case 'followUp':
        return followUp ?? '';
      case 'medicalDecisionMaking':
        return medicalDecisionMaking ?? '';
      default:
        return customSections[key] ?? '';
    }
  }

  NoteContent copyWith({
    String? topic,
    String? subjective,
    String? objective,
    String? assessment,
    String? plan,
    String? instructions,
    String? chiefComplaint,
    String? historyOfPresentIllness,
    String? reviewOfSystems,
    String? physicalExam,
    String? followUp,
    String? medicalDecisionMaking,
    Map<String, String>? customSections,
    String? legacyText,
  }) =>
      NoteContent(
        topic: topic ?? this.topic,
        subjective: subjective ?? this.subjective,
        objective: objective ?? this.objective,
        assessment: assessment ?? this.assessment,
        plan: plan ?? this.plan,
        instructions: instructions ?? this.instructions,
        chiefComplaint: chiefComplaint ?? this.chiefComplaint,
        historyOfPresentIllness: historyOfPresentIllness ?? this.historyOfPresentIllness,
        reviewOfSystems: reviewOfSystems ?? this.reviewOfSystems,
        physicalExam: physicalExam ?? this.physicalExam,
        followUp: followUp ?? this.followUp,
        medicalDecisionMaking: medicalDecisionMaking ?? this.medicalDecisionMaking,
        customSections: customSections ?? this.customSections,
        legacyText: legacyText ?? this.legacyText,
      );
}

class ClinicalNote {
  final String id;
  final String title;
  final String? patientName;
  final String? specialty;
  final String? templateId;
  final String? templateName;
  final NoteContent content;
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
      templateId: (json['template'] ?? json['templateId'])?.toString(),
      templateName: json['templateName'] as String?,
      content: NoteContent.from(json['content']),
      transcript: (json['transcription'] ?? json['transcript']) as String?,
      status: NoteStatus.fromString(json['status'] as String?),
      durationSeconds: (json['durationSeconds'] ?? json['processingTime']) is num
          ? (json['durationSeconds'] ?? json['processingTime'] as num).toInt()
          : null,
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
    NoteContent? content,
    String? patientName,
    NoteStatus? status,
    DateTime? updatedAt,
    DateTime? signedAt,
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
      updatedAt: updatedAt ?? DateTime.now(),
      signedAt: signedAt ?? this.signedAt,
      signedBy: signedBy,
    );
  }
}

enum NoteStatus {
  draft,
  processing,
  ready,
  completed,
  signed,
  failed;

  static NoteStatus fromString(String? raw) {
    switch (raw) {
      case 'processing':
        return NoteStatus.processing;
      case 'ready':
        return NoteStatus.ready;
      case 'completed':
        return NoteStatus.completed;
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
      case NoteStatus.completed:
        return 'Completed';
      case NoteStatus.signed:
        return 'Signed';
      case NoteStatus.failed:
        return 'Failed';
    }
  }
}
