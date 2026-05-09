import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/api/dashboard_api.dart';
import '../../core/api/notes_api.dart';
import '../../core/models/dashboard_stats.dart';
import '../../core/models/note.dart';

class DashboardData {
  final DashboardStats stats;
  final List<Appointment> appointments;
  final List<ClinicalNote> recentNotes;
  final bool loading;
  final String? error;

  const DashboardData({
    required this.stats,
    this.appointments = const [],
    this.recentNotes = const [],
    this.loading = false,
    this.error,
  });

  DashboardData copyWith({
    DashboardStats? stats,
    List<Appointment>? appointments,
    List<ClinicalNote>? recentNotes,
    bool? loading,
    String? error,
    bool clearError = false,
  }) =>
      DashboardData(
        stats: stats ?? this.stats,
        appointments: appointments ?? this.appointments,
        recentNotes: recentNotes ?? this.recentNotes,
        loading: loading ?? this.loading,
        error: clearError ? null : (error ?? this.error),
      );
}

final dashboardControllerProvider =
    StateNotifierProvider<DashboardController, DashboardData>((ref) {
  return DashboardController(
    ref.watch(dashboardApiProvider),
    ref.watch(notesApiProvider),
  );
});

class DashboardController extends StateNotifier<DashboardData> {
  DashboardController(this._api, this._notesApi)
      : super(DashboardData(stats: DashboardStats.empty(), loading: true)) {
    refresh();
  }

  final DashboardApi _api;
  final NotesApi _notesApi;

  Future<void> refresh() async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final results = await Future.wait([
        _api.getStats(),
        _api.getAppointments(),
        _notesApi.list(limit: 5),
      ]);
      state = state.copyWith(
        stats: results[0] as DashboardStats,
        appointments: results[1] as List<Appointment>,
        recentNotes: (results[2] as NotesPage).notes,
        loading: false,
      );
    } on ApiException catch (e) {
      state = state.copyWith(loading: false, error: e.message);
    } catch (e) {
      state = state.copyWith(loading: false, error: 'Failed to load dashboard: $e');
    }
  }
}
