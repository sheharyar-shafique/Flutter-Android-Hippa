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
}
