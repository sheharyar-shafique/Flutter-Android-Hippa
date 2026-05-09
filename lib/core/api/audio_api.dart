import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_client.dart';

final audioApiProvider = Provider<AudioApi>((ref) {
  return AudioApi(ref.watch(apiClientProvider));
});

/// Response from /audio/upload — just the audio file record, NOT a note.
class AudioUploadResult {
  final String id;
  final String fileName;
  AudioUploadResult({required this.id, required this.fileName});

  factory AudioUploadResult.fromJson(Map<String, dynamic> json) {
    return AudioUploadResult(
      id: json['id']?.toString() ?? '',
      fileName: (json['fileName'] ?? json['file_name'] ?? '') as String,
    );
  }
}

/// Response from /audio/transcribe
class TranscriptionResult {
  final String audioFileId;
  final String transcription;
  TranscriptionResult({required this.audioFileId, required this.transcription});

  factory TranscriptionResult.fromJson(Map<String, dynamic> json) {
    return TranscriptionResult(
      audioFileId: json['audioFileId']?.toString() ?? '',
      transcription: (json['transcription'] ?? '') as String,
    );
  }
}

/// Response from /audio/generate-note
class GenerateNoteResult {
  final Map<String, dynamic> content;
  final String template;
  final String source; // 'ai' or 'mock'
  GenerateNoteResult({required this.content, required this.template, required this.source});

  factory GenerateNoteResult.fromJson(Map<String, dynamic> json) {
    return GenerateNoteResult(
      content: (json['content'] as Map<String, dynamic>?) ?? {},
      template: (json['template'] ?? '') as String,
      source: (json['source'] ?? 'ai') as String,
    );
  }
}

class AudioApi {
  final Dio _dio;
  AudioApi(this._dio);

  /// Step 1: Upload audio file → returns audio file ID (NOT a note).
  Future<AudioUploadResult> upload({
    required String filePath,
    required String filename,
    void Function(int sent, int total)? onProgress,
  }) async {
    try {
      final form = FormData.fromMap({
        'audio': await MultipartFile.fromFile(filePath, filename: filename),
      });

      final res = await _dio.post(
        '/audio/upload',
        data: form,
        onSendProgress: onProgress,
        options: Options(
          sendTimeout: const Duration(minutes: 10),
          receiveTimeout: const Duration(minutes: 5),
        ),
      );

      return AudioUploadResult.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// Step 2: Transcribe uploaded audio → returns transcription text.
  Future<TranscriptionResult> transcribe(String audioFileId) async {
    try {
      final res = await _dio.post(
        '/audio/transcribe',
        data: {'audioFileId': audioFileId},
        options: Options(
          receiveTimeout: const Duration(minutes: 5),
        ),
      );
      return TranscriptionResult.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// Step 3: Generate clinical note content from transcription.
  Future<GenerateNoteResult> generateNote({
    required String transcription,
    required String template,
    String? patientName,
  }) async {
    try {
      final res = await _dio.post(
        '/audio/generate-note',
        data: {
          'transcription': transcription,
          'template': template,
          if (patientName != null) 'patientName': patientName,
        },
        options: Options(
          receiveTimeout: const Duration(minutes: 5),
        ),
      );
      return GenerateNoteResult.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// Generate treatment plan from multiple notes.
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

  /// Generate a clinical report.
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
