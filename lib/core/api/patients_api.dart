import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/patient.dart';
import 'api_client.dart';

final patientsApiProvider = Provider<PatientsApi>((ref) {
  return PatientsApi(ref.watch(apiClientProvider));
});

class PatientsApi {
  final Dio _dio;
  PatientsApi(this._dio);

  Future<List<Patient>> list({String? search}) async {
    try {
      final res = await _dio.get('/patients', queryParameters: {
        if (search != null && search.isNotEmpty) 'search': search,
      });
      final data = res.data;
      final list = data is List
          ? data.cast<Map<String, dynamic>>()
          : (data['patients'] as List? ?? data['data'] as List? ?? [])
              .cast<Map<String, dynamic>>();
      return list.map(Patient.fromJson).toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<Patient> get(String id) async {
    try {
      final res = await _dio.get('/patients/$id');
      return Patient.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<Patient> create({
    required String name,
    String? medicalRecordNumber,
    DateTime? dateOfBirth,
    String? gender,
  }) async {
    try {
      final res = await _dio.post('/patients', data: {
        'name': name,
        if (medicalRecordNumber != null) 'medicalRecordNumber': medicalRecordNumber,
        if (dateOfBirth != null) 'dateOfBirth': dateOfBirth.toIso8601String(),
        if (gender != null) 'gender': gender,
      });
      return Patient.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> delete(String id) async {
    try {
      await _dio.delete('/patients/$id');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
