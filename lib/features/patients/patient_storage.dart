import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Per-patient profile + context + treatment plan + reports persistence.
/// Uses the EXACT same shared_preferences keys as the web's localStorage
/// keys (frontend/src/pages/PatientPage.tsx:82-156) so a future cross-
/// platform migration of these prefs server-side can read either side's
/// data without conversion.

/// Slug to use in storage keys: lowercase, spaces → underscores.
String _slug(String name) => name.toLowerCase().replaceAll(RegExp(r'\s+'), '_');

String _profileKey(String name) => 'pronote_patient_${_slug(name)}';
String _contextKey(String name) => 'pronote_patient_context_${_slug(name)}';
String _treatmentPlanKey(String name) => 'pronote_patient_treatment_plan_${_slug(name)}';
String _reportsKey(String name) => 'pronote_patient_reports_${_slug(name)}';

class PatientProfile {
  final String pronoun;
  final String name;
  final String phone;
  final String email;
  final String dob;

  const PatientProfile({
    required this.pronoun,
    required this.name,
    required this.phone,
    required this.email,
    required this.dob,
  });

  factory PatientProfile.empty(String name) =>
      PatientProfile(pronoun: 'He/Him', name: name, phone: '', email: '', dob: '');

  factory PatientProfile.fromJson(Map<String, dynamic> json, {String? fallbackName}) {
    return PatientProfile(
      pronoun: json['pronoun'] as String? ?? 'He/Him',
      name: json['name'] as String? ?? (fallbackName ?? ''),
      phone: json['phone'] as String? ?? '',
      email: json['email'] as String? ?? '',
      dob: json['dob'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'pronoun': pronoun,
        'name': name,
        'phone': phone,
        'email': email,
        'dob': dob,
      };

  PatientProfile copyWith({
    String? pronoun,
    String? name,
    String? phone,
    String? email,
    String? dob,
  }) =>
      PatientProfile(
        pronoun: pronoun ?? this.pronoun,
        name: name ?? this.name,
        phone: phone ?? this.phone,
        email: email ?? this.email,
        dob: dob ?? this.dob,
      );
}

class PatientReport {
  final String id;
  final String diagnosis;
  final String startDate;
  final String endDate;
  final String createdAt;
  final String content;

  const PatientReport({
    required this.id,
    required this.diagnosis,
    required this.startDate,
    required this.endDate,
    required this.createdAt,
    required this.content,
  });

  factory PatientReport.fromJson(Map<String, dynamic> json) => PatientReport(
        id: json['id'] as String,
        diagnosis: json['diagnosis'] as String,
        startDate: json['startDate'] as String,
        endDate: json['endDate'] as String,
        createdAt: json['createdAt'] as String,
        content: json['content'] as String,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'diagnosis': diagnosis,
        'startDate': startDate,
        'endDate': endDate,
        'createdAt': createdAt,
        'content': content,
      };
}

class PatientStorage {
  // ── Profile ──────────────────────────────────────────────────────────
  static Future<PatientProfile> loadProfile(String name) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_profileKey(name));
    if (raw != null) {
      try {
        return PatientProfile.fromJson(
          jsonDecode(raw) as Map<String, dynamic>,
          fallbackName: name,
        );
      } catch (_) {}
    }
    return PatientProfile.empty(name);
  }

  static Future<void> saveProfile(PatientProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_profileKey(profile.name), jsonEncode(profile.toJson()));
  }

  // ── Patient context (free-text used during note generation) ──────────
  static Future<String> loadContext(String name) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_contextKey(name)) ?? '';
  }

  static Future<void> saveContext(String name, String context) async {
    final prefs = await SharedPreferences.getInstance();
    if (context.trim().isEmpty) {
      await prefs.remove(_contextKey(name));
    } else {
      await prefs.setString(_contextKey(name), context);
    }
  }

  // ── Treatment plan ───────────────────────────────────────────────────
  static Future<String> loadTreatmentPlan(String name) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_treatmentPlanKey(name)) ?? '';
  }

  static Future<void> saveTreatmentPlan(String name, String plan) async {
    final prefs = await SharedPreferences.getInstance();
    if (plan.trim().isEmpty) {
      await prefs.remove(_treatmentPlanKey(name));
    } else {
      await prefs.setString(_treatmentPlanKey(name), plan);
    }
  }

  // ── Reports ──────────────────────────────────────────────────────────
  static Future<List<PatientReport>> loadReports(String name) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_reportsKey(name));
    if (raw == null) return const [];
    try {
      final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
      return list.map(PatientReport.fromJson).toList();
    } catch (_) {
      return const [];
    }
  }

  static Future<void> saveReports(String name, List<PatientReport> reports) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _reportsKey(name),
      jsonEncode(reports.map((r) => r.toJson()).toList()),
    );
  }
}
