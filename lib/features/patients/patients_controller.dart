import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/api/patients_api.dart';
import '../../core/models/patient.dart';

class PatientsState {
  final List<Patient> patients;
  final bool loading;
  final String? error;
  final String search;

  const PatientsState({
    this.patients = const [],
    this.loading = false,
    this.error,
    this.search = '',
  });

  PatientsState copyWith({
    List<Patient>? patients,
    bool? loading,
    String? error,
    String? search,
    bool clearError = false,
  }) =>
      PatientsState(
        patients: patients ?? this.patients,
        loading: loading ?? this.loading,
        error: clearError ? null : (error ?? this.error),
        search: search ?? this.search,
      );
}

final patientsControllerProvider =
    StateNotifierProvider<PatientsController, PatientsState>((ref) {
  return PatientsController(ref.watch(patientsApiProvider));
});

class PatientsController extends StateNotifier<PatientsState> {
  PatientsController(this._api) : super(const PatientsState()) {
    refresh();
  }

  final PatientsApi _api;

  Future<void> refresh() async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final list = await _api.list(search: state.search.isEmpty ? null : state.search);
      state = state.copyWith(patients: list, loading: false);
    } on ApiException catch (e) {
      state = state.copyWith(loading: false, error: e.message);
    } catch (e) {
      state = state.copyWith(loading: false, error: 'Failed to load patients: $e');
    }
  }

  Future<void> setSearch(String search) async {
    state = state.copyWith(search: search);
    await refresh();
  }

  Future<bool> create({
    required String name,
    String? medicalRecordNumber,
    DateTime? dateOfBirth,
    String? gender,
  }) async {
    try {
      final created = await _api.create(
        name: name,
        medicalRecordNumber: medicalRecordNumber,
        dateOfBirth: dateOfBirth,
        gender: gender,
      );
      state = state.copyWith(patients: [created, ...state.patients]);
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(error: e.message);
      return false;
    }
  }

  Future<void> delete(String id) async {
    // Patients are derived from notes — remove from local state.
    // A full delete would require deleting all notes for this patient.
    state = state.copyWith(
      patients: state.patients.where((p) => p.id != id).toList(),
    );
  }
}
