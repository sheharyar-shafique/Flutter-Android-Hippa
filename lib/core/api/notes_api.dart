import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/note.dart';
import 'api_client.dart';

class NotesPage {
  final List<ClinicalNote> notes;
  final int total;
  final int page;
  final int pageSize;

  NotesPage({
    required this.notes,
    required this.total,
    required this.page,
    required this.pageSize,
  });

  factory NotesPage.fromJson(Map<String, dynamic> json) {
    final list = (json['notes'] as List? ?? json['data'] as List? ?? [])
        .cast<Map<String, dynamic>>()
        .map(ClinicalNote.fromJson)
        .toList();

    // Backend nests pagination in { pagination: { page, limit, total, totalPages } }
    final pag = json['pagination'] as Map<String, dynamic>?;

    return NotesPage(
      notes: list,
      total: (pag?['total'] as num?)?.toInt()
          ?? (json['total'] as num?)?.toInt()
          ?? list.length,
      page: (pag?['page'] as num?)?.toInt()
          ?? (json['page'] as num?)?.toInt()
          ?? 1,
      pageSize: (pag?['limit'] as num?)?.toInt()
          ?? (json['pageSize'] as num?)?.toInt()
          ?? list.length,
    );
  }
}

final notesApiProvider = Provider<NotesApi>((ref) {
  return NotesApi(ref.watch(apiClientProvider));
});

class NotesApi {
  final Dio _dio;
  NotesApi(this._dio);

  Future<NotesPage> list({String? search, int? limit, int? page}) async {
    try {
      final res = await _dio.get('/notes', queryParameters: {
        if (search != null && search.isNotEmpty) 'search': search,
        if (limit != null) 'limit': limit,
        if (page != null) 'page': page,
      });
      final data = res.data;
      if (data is List) {
        // Backend may return a bare array — wrap it.
        return NotesPage(
          notes: data
              .cast<Map<String, dynamic>>()
              .map(ClinicalNote.fromJson)
              .toList(),
          total: data.length,
          page: 1,
          pageSize: data.length,
        );
      }
      return NotesPage.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<List<ClinicalNote>> recent({int limit = 5}) async {
    try {
      final res = await _dio.get('/notes/recent', queryParameters: {'limit': limit});
      return (res.data as List)
          .cast<Map<String, dynamic>>()
          .map(ClinicalNote.fromJson)
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<ClinicalNote> get(String id) async {
    try {
      final res = await _dio.get('/notes/$id');
      return ClinicalNote.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<ClinicalNote> create({
    required String patientName,
    required String dateOfService,
    required String template,
    required Map<String, dynamic> content,
    String? transcription,
    int? processingTime,
  }) async {
    try {
      final res = await _dio.post('/notes', data: {
        'patientName': patientName,
        'dateOfService': dateOfService,
        'template': template,
        'content': content,
        if (transcription != null) 'transcription': transcription,
        if (processingTime != null) 'processingTime': processingTime,
      });
      final data = res.data;
      if (data is Map<String, dynamic> && data.containsKey('note')) {
        return ClinicalNote.fromJson(data['note'] as Map<String, dynamic>);
      }
      return ClinicalNote.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// Update the note. `content` accepts a structured `Map` (modern note shape
  /// matching the web's NoteContent JSON) or null to leave unchanged.
  Future<ClinicalNote> update(
    String id, {
    String? title,
    Map<String, dynamic>? content,
    String? patientName,
  }) async {
    try {
      final res = await _dio.put('/notes/$id', data: {
        if (title != null) 'title': title,
        if (content != null) 'content': content,
        if (patientName != null) 'patientName': patientName,
      });
      return ClinicalNote.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> delete(String id) async {
    try {
      await _dio.delete('/notes/$id');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<ClinicalNote> sign(String id) async {
    try {
      final res = await _dio.post('/notes/$id/sign');
      return ClinicalNote.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
