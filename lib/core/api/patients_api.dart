import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/patient.dart';
import 'api_client.dart';

final patientsApiProvider = Provider<PatientsApi>((ref) {
  return PatientsApi(ref.watch(apiClientProvider));
});

/// The backend has NO dedicated /patients endpoint.
/// Patients are derived from notes — we fetch all notes and extract unique
/// patient names, mirroring how the web frontend works.
class PatientsApi {
  final Dio _dio;
  PatientsApi(this._dio);

  Future<List<Patient>> list({String? search}) async {
    try {
      // Fetch all notes (large limit) to extract patient names
      final res = await _dio.get('/notes', queryParameters: {
        'limit': 500,
      });
      final data = res.data;
      List<Map<String, dynamic>> notesList;
      if (data is List) {
        notesList = data.cast<Map<String, dynamic>>();
      } else if (data is Map<String, dynamic>) {
        notesList = (data['notes'] as List? ?? data['data'] as List? ?? [])
            .cast<Map<String, dynamic>>();
      } else {
        notesList = [];
      }

      // Group notes by patientName to build Patient objects
      final Map<String, List<Map<String, dynamic>>> grouped = {};
      for (final note in notesList) {
        final name = note['patientName'] as String?;
        if (name == null || name.trim().isEmpty) continue;
        grouped.putIfAbsent(name.trim(), () => []).add(note);
      }

      final patients = <Patient>[];
      for (final entry in grouped.entries) {
        final notes = entry.value;
        // Sort notes by createdAt descending to find last visit
        notes.sort((a, b) {
          final aDate = DateTime.tryParse(a['createdAt'] as String? ?? '') ?? DateTime(2000);
          final bDate = DateTime.tryParse(b['createdAt'] as String? ?? '') ?? DateTime(2000);
          return bDate.compareTo(aDate);
        });

        final firstNote = notes.first;
        final lastCreated = DateTime.tryParse(firstNote['createdAt'] as String? ?? '');
        // Use the oldest note's createdAt as the patient's createdAt
        final oldestNote = notes.last;
        final patientCreated = DateTime.tryParse(oldestNote['createdAt'] as String? ?? '') ?? DateTime.now();

        patients.add(Patient(
          id: entry.key, // Use patient name as the ID since there's no patient table
          name: entry.key,
          notesCount: notes.length,
          lastVisit: lastCreated,
          createdAt: patientCreated,
        ));
      }

      // Apply search filter locally if provided
      if (search != null && search.isNotEmpty) {
        final q = search.toLowerCase();
        patients.retainWhere((p) => p.name.toLowerCase().contains(q));
      }

      // Sort by most recent visit
      patients.sort((a, b) => (b.lastVisit ?? DateTime(2000)).compareTo(a.lastVisit ?? DateTime(2000)));

      return patients;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// "Get" a patient by name — fetches their notes.
  Future<Patient> get(String patientName) async {
    try {
      final res = await _dio.get('/notes', queryParameters: {
        'search': patientName,
        'limit': 500,
      });
      final data = res.data;
      List<Map<String, dynamic>> notesList;
      if (data is List) {
        notesList = data.cast<Map<String, dynamic>>();
      } else if (data is Map<String, dynamic>) {
        notesList = (data['notes'] as List? ?? data['data'] as List? ?? [])
            .cast<Map<String, dynamic>>();
      } else {
        notesList = [];
      }

      // Filter to exact patient name match
      notesList = notesList.where((n) {
        final name = (n['patientName'] as String?)?.trim() ?? '';
        return name.toLowerCase() == patientName.toLowerCase();
      }).toList();

      if (notesList.isEmpty) {
        return Patient(
          id: patientName,
          name: patientName,
          notesCount: 0,
          createdAt: DateTime.now(),
        );
      }

      notesList.sort((a, b) {
        final aDate = DateTime.tryParse(a['createdAt'] as String? ?? '') ?? DateTime(2000);
        final bDate = DateTime.tryParse(b['createdAt'] as String? ?? '') ?? DateTime(2000);
        return bDate.compareTo(aDate);
      });

      final lastVisit = DateTime.tryParse(notesList.first['createdAt'] as String? ?? '');
      final created = DateTime.tryParse(notesList.last['createdAt'] as String? ?? '') ?? DateTime.now();

      return Patient(
        id: patientName,
        name: patientName,
        notesCount: notesList.length,
        lastVisit: lastVisit,
        createdAt: created,
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// Creating a patient is not supported by the backend — patients are
  /// created implicitly when a note is saved with a patientName.
  Future<Patient> create({
    required String name,
    String? medicalRecordNumber,
    DateTime? dateOfBirth,
    String? gender,
  }) async {
    // Return a synthetic patient — it will appear once a note is created
    return Patient(
      id: name,
      name: name,
      medicalRecordNumber: medicalRecordNumber,
      dateOfBirth: dateOfBirth,
      gender: gender,
      notesCount: 0,
      createdAt: DateTime.now(),
    );
  }

  /// Deleting a patient is not directly supported — would need to delete all
  /// their notes. For now this is a no-op.
  Future<void> delete(String id) async {
    // No-op: backend has no patient deletion endpoint
  }
}
