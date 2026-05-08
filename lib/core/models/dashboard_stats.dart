class DashboardStats {
  final int totalNotes;
  final int notesThisWeek;
  final double avgNoteSeconds;
  final double accuracyPct;
  final double notesTrendPct;
  final double weekTrendPct;
  final double timeTrendPct;
  final double accuracyTrendPct;

  DashboardStats({
    required this.totalNotes,
    required this.notesThisWeek,
    required this.avgNoteSeconds,
    required this.accuracyPct,
    this.notesTrendPct = 0,
    this.weekTrendPct = 0,
    this.timeTrendPct = 0,
    this.accuracyTrendPct = 0,
  });

  factory DashboardStats.empty() => DashboardStats(
        totalNotes: 0,
        notesThisWeek: 0,
        avgNoteSeconds: 0,
        accuracyPct: 0,
      );

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    double _d(dynamic v) {
      if (v is num) return v.toDouble();
      return 0;
    }

    int _i(dynamic v) {
      if (v is num) return v.toInt();
      return 0;
    }

    return DashboardStats(
      totalNotes: _i(json['totalNotes']),
      notesThisWeek: _i(json['notesThisWeek']),
      avgNoteSeconds: _d(json['avgNoteSeconds'] ?? json['avgTimeSeconds']),
      accuracyPct: _d(json['accuracyPct'] ?? json['accuracy']),
      notesTrendPct: _d(json['notesTrendPct']),
      weekTrendPct: _d(json['weekTrendPct']),
      timeTrendPct: _d(json['timeTrendPct']),
      accuracyTrendPct: _d(json['accuracyTrendPct']),
    );
  }
}

class Appointment {
  final String id;
  final String patientName;
  final String? notes;
  final DateTime startsAt;
  final int? durationMinutes;
  final String? status;

  Appointment({
    required this.id,
    required this.patientName,
    required this.startsAt,
    this.notes,
    this.durationMinutes,
    this.status,
  });

  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      patientName: json['patientName'] as String? ?? json['name'] as String? ?? 'Patient',
      notes: json['notes'] as String?,
      startsAt: DateTime.tryParse(json['startsAt'] as String? ?? '') ?? DateTime.now(),
      durationMinutes: (json['durationMinutes'] as num?)?.toInt(),
      status: json['status'] as String?,
    );
  }
}
