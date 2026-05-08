import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/api/templates_api.dart';
import '../../core/models/template.dart';

class TemplatesState {
  final List<NoteTemplate> templates;
  final bool loading;
  final String? error;

  const TemplatesState({this.templates = const [], this.loading = false, this.error});

  TemplatesState copyWith({
    List<NoteTemplate>? templates,
    bool? loading,
    String? error,
    bool clearError = false,
  }) =>
      TemplatesState(
        templates: templates ?? this.templates,
        loading: loading ?? this.loading,
        error: clearError ? null : (error ?? this.error),
      );
}

final templatesControllerProvider =
    StateNotifierProvider<TemplatesController, TemplatesState>((ref) {
  return TemplatesController(ref.watch(templatesApiProvider));
});

class TemplatesController extends StateNotifier<TemplatesState> {
  TemplatesController(this._api) : super(const TemplatesState()) {
    refresh();
  }

  final TemplatesApi _api;

  Future<void> refresh() async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final list = await _api.list();
      state = state.copyWith(templates: list, loading: false);
    } on ApiException catch (e) {
      state = state.copyWith(loading: false, error: e.message);
    }
  }
}
