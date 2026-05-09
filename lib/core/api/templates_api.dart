import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/template.dart';
import 'api_client.dart';

final templatesApiProvider = Provider<TemplatesApi>((ref) {
  return TemplatesApi(ref.watch(apiClientProvider));
});

class TemplatesApi {
  final Dio _dio;
  TemplatesApi(this._dio);

  Future<List<NoteTemplate>> list() async {
    try {
      final res = await _dio.get('/templates');
      final data = res.data;
      final list = data is List
          ? data.cast<Map<String, dynamic>>()
          : (data['templates'] as List? ?? data['data'] as List? ?? [])
              .cast<Map<String, dynamic>>();
      return list.map(NoteTemplate.fromJson).toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<NoteTemplate> get(String id) async {
    try {
      final res = await _dio.get('/templates/$id');
      return NoteTemplate.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// Fetch the user's My Templates preferences from the server.
  /// Returns { addedIds: [...], customTemplates: [...] } or null.
  Future<Map<String, dynamic>?> getPreferences() async {
    try {
      final res = await _dio.get('/templates/preferences');
      final data = res.data as Map<String, dynamic>?;
      if (data == null) return null;
      // The server wraps the payload in a `preferences` key
      final prefs = data['preferences'] as Map<String, dynamic>?;
      return prefs;
    } on DioException catch (e) {
      // 404 = no preferences saved yet (new user)
      if (e.response?.statusCode == 404) return null;
      throw ApiException.fromDio(e);
    }
  }

  /// Persist the user's My Templates selections to the server.
  Future<void> savePreferences(
      List<String> addedIds, List<Map<String, dynamic>> customTemplates) async {
    try {
      await _dio.put('/templates/preferences', data: {
        'addedIds': addedIds,
        'customTemplates': customTemplates,
      });
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
