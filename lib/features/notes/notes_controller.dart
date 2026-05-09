import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/api/notes_api.dart';
import '../../core/models/note.dart';

class NotesListState {
  final List<ClinicalNote> notes;
  final bool loading;
  final String? error;
  final String search;

  const NotesListState({
    this.notes = const [],
    this.loading = false,
    this.error,
    this.search = '',
  });

  NotesListState copyWith({
    List<ClinicalNote>? notes,
    bool? loading,
    String? error,
    String? search,
    bool clearError = false,
  }) {
    return NotesListState(
      notes: notes ?? this.notes,
      loading: loading ?? this.loading,
      error: clearError ? null : (error ?? this.error),
      search: search ?? this.search,
    );
  }
}

final notesListControllerProvider =
    StateNotifierProvider<NotesListController, NotesListState>((ref) {
  return NotesListController(ref.watch(notesApiProvider));
});

class NotesListController extends StateNotifier<NotesListState> {
  NotesListController(this._api) : super(const NotesListState()) {
    refresh();
  }

  final NotesApi _api;

  Future<void> refresh() async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final page = await _api.list(search: state.search.isEmpty ? null : state.search);
      state = state.copyWith(notes: page.notes, loading: false);
    } on ApiException catch (e) {
      state = state.copyWith(loading: false, error: e.message);
    } catch (e) {
      state = state.copyWith(loading: false, error: 'Failed to load notes: $e');
    }
  }

  Future<void> setSearch(String search) async {
    state = state.copyWith(search: search);
    await refresh();
  }

  Future<void> delete(String id) async {
    final previous = state.notes;
    state = state.copyWith(notes: previous.where((n) => n.id != id).toList());
    try {
      await _api.delete(id);
    } on ApiException catch (e) {
      state = state.copyWith(notes: previous, error: e.message);
    }
  }
}

/// Provider for an individual note (used by the editor screen).
final noteProvider = FutureProvider.family.autoDispose<ClinicalNote, String>((ref, id) async {
  return ref.watch(notesApiProvider).get(id);
});
