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
      if (v is String) {
        // Parse strings like "98.5%" or "2.5"
        final cleaned = v.replaceAll('%', '').trim();
        return double.tryParse(cleaned) ?? 0;
      }
      return 0;
    }

    int _i(dynamic v) {
      if (v is num) return v.toInt();
      return 0;
    }

    /// Parse time strings like "2m 30s", "45s", "1m" into seconds.
    double _parseTimeString(dynamic v) {
      if (v is num) return v.toDouble();
      if (v is String) {
        final s = v.trim();
        // Try "Xm Ys" pattern
        final match = RegExp(r'(\d+)m\s*(\d+)?s?').firstMatch(s);
        if (match != null) {
          final mins = int.tryParse(match.group(1) ?? '0') ?? 0;
          final secs = int.tryParse(match.group(2) ?? '0') ?? 0;
          return (mins * 60 + secs).toDouble();
        }
        // Try "Xs" pattern
        final secMatch = RegExp(r'(\d+)s').firstMatch(s);
        if (secMatch != null) {
          return double.tryParse(secMatch.group(1) ?? '0') ?? 0;
        }
        // Plain number
        return double.tryParse(s) ?? 0;
      }
      return 0;
    }

    return DashboardStats(
      totalNotes: _i(json['totalNotes']),
      notesThisWeek: _i(json['notesThisWeek']),
      avgNoteSeconds: _parseTimeString(json['avgNoteSeconds'] ?? json['avgTimeSeconds'] ?? json['averageTime']),
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
    // Backend returns 'patient' (web shape) or 'patientName' (legacy)
    final pName = json['patient'] as String?
        ?? json['patientName'] as String?
        ?? json['name'] as String?
        ?? 'Patient';

    // Backend returns 'time' (ISO string) or 'startsAt'
    final timeStr = json['time'] as String?
        ?? json['startsAt'] as String?
        ?? '';

    return Appointment(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      patientName: pName,
      notes: json['notes'] as String?,
      startsAt: DateTime.tryParse(timeStr) ?? DateTime.now(),
      durationMinutes: (json['durationMinutes'] as num?)?.toInt(),
      status: json['status'] as String?,
    );
  }
}
