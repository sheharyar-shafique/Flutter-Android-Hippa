import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/note.dart';
import 'api_client.dart';

final audioApiProvider = Provider<AudioApi>((ref) {
  return AudioApi(ref.watch(apiClientProvider));
});

class AudioApi {
  final Dio _dio;
  AudioApi(this._dio);

  /// Uploads a recorded/local audio file and kicks off transcription +
  /// note generation. Returns the freshly-created note (in `processing`
  /// state at first — poll `/notes/:id` until status flips to `ready`).
  Future<ClinicalNote> upload({
    required String filePath,
    required String filename,
    String? patientName,
    String? templateId,
    String? title,
    void Function(int sent, int total)? onProgress,
  }) async {
    try {
      final form = FormData.fromMap({
        'audio': await MultipartFile.fromFile(filePath, filename: filename),
        if (patientName != null) 'patientName': patientName,
        if (templateId != null) 'templateId': templateId,
        if (title != null) 'title': title,
      });

      final res = await _dio.post(
        '/audio/upload',
        data: form,
        onSendProgress: onProgress,
        options: Options(
          // Long uploads — let the server drive the timeout.
          sendTimeout: const Duration(minutes: 10),
          receiveTimeout: const Duration(minutes: 5),
        ),
      );

      final data = res.data;
      if (data is Map<String, dynamic>) {
        if (data['note'] is Map<String, dynamic>) {
          return ClinicalNote.fromJson(data['note'] as Map<String, dynamic>);
        }
        return ClinicalNote.fromJson(data);
      }
      throw ApiException('Unexpected upload response shape.');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// Asks the backend to summarise the patient's selected notes into a
  /// structured treatment plan (called from the Treatment Plan tab on the
  /// patient page). Mirrors `audioApi.generateTreatmentPlan` from the web.
  Future<String> generateTreatmentPlan({
    required List<String> noteIds,
    required String patientName,
  }) async {
    try {
      final res = await _dio.post('/audio/generate-treatment-plan', data: {
        'noteIds': noteIds,
        'patientName': patientName,
      });
      final data = res.data;
      if (data is Map<String, dynamic>) {
        return (data['plan'] ?? data['content'] ?? '') as String;
      }
      return '';
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// Asks the backend to write a clinical report covering one diagnosis
  /// across a date range. Mirrors `audioApi.generateReport` from the web.
  Future<String> generateReport({
    required List<String> noteIds,
    required String diagnosis,
    required String patientName,
    required String startDate,
    required String endDate,
  }) async {
    try {
      final res = await _dio.post('/audio/generate-report', data: {
        'noteIds': noteIds,
        'diagnosis': diagnosis,
        'patientName': patientName,
        'startDate': startDate,
        'endDate': endDate,
      });
      final data = res.data;
      if (data is Map<String, dynamic>) {
        return (data['content'] ?? data['report'] ?? '') as String;
      }
      return '';
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
