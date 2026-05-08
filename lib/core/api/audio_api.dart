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
}
