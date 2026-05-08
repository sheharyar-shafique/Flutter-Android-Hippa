import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/api/dashboard_api.dart';
import '../../core/models/dashboard_stats.dart';

class DashboardData {
  final DashboardStats stats;
  final List<Appointment> appointments;
  final bool loading;
  final String? error;

  const DashboardData({
    required this.stats,
    this.appointments = const [],
    this.loading = false,
    this.error,
  });

  DashboardData copyWith({
    DashboardStats? stats,
    List<Appointment>? appointments,
    bool? loading,
    String? error,
    bool clearError = false,
  }) =>
      DashboardData(
        stats: stats ?? this.stats,
        appointments: appointments ?? this.appointments,
        loading: loading ?? this.loading,
        error: clearError ? null : (error ?? this.error),
      );
}

final dashboardControllerProvider =
    StateNotifierProvider<DashboardController, DashboardData>((ref) {
  return DashboardController(ref.watch(dashboardApiProvider));
});

class DashboardController extends StateNotifier<DashboardData> {
  DashboardController(this._api)
      : super(DashboardData(stats: DashboardStats.empty(), loading: true)) {
    refresh();
  }

  final DashboardApi _api;

  Future<void> refresh() async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final results = await Future.wait([
        _api.getStats(),
        _api.getAppointments(),
      ]);
      state = state.copyWith(
        stats: results[0] as DashboardStats,
        appointments: results[1] as List<Appointment>,
        loading: false,
      );
    } on ApiException catch (e) {
      state = state.copyWith(loading: false, error: e.message);
    }
  }
}
