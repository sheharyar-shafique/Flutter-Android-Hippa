import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/dashboard_stats.dart';
import 'api_client.dart';

final dashboardApiProvider = Provider<DashboardApi>((ref) {
  return DashboardApi(ref.watch(apiClientProvider));
});

class DashboardApi {
  final Dio _dio;
  DashboardApi(this._dio);

  Future<DashboardStats> getStats() async {
    try {
      final res = await _dio.get('/dashboard/stats');
      return DashboardStats.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<List<Appointment>> getAppointments() async {
    try {
      final res = await _dio.get('/dashboard/appointments');
      final data = res.data;
      final list = data is List
          ? data.cast<Map<String, dynamic>>()
          : (data['appointments'] as List? ?? data['data'] as List? ?? [])
              .cast<Map<String, dynamic>>();
      return list.map(Appointment.fromJson).toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
