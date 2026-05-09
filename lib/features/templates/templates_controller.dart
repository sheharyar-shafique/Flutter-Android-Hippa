import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/data/default_templates.dart';
import '../../core/models/template.dart';

/// Local-storage equivalents of the web's `pronote_added_ids` and
/// `pronote_custom_templates` keys (TemplatesPage.tsx:51, :62).
const _kAddedIdsKey = 'pronote_added_ids';
const _kCustomTemplatesKey = 'pronote_custom_templates';

class TemplatesState {
  /// Set of template IDs the user has added to "My Templates".
  /// On first launch we seed with every default template ID, so a fresh
  /// account starts with the full library — same bootstrap behaviour as
  /// the web (line 49-58).
  final List<String> addedIds;

  /// User-created templates. Built-ins live in `kDefaultTemplates` and
  /// are never duplicated here.
  final List<NoteTemplate> customTemplates;

  /// Currently-selected template ID for the Capture screen ("Use this").
  /// Mirrors web's `useSettingsStore.selectedTemplate`.
  final String? selectedTemplateId;

  /// Loading flag for the initial localStorage read.
  final bool initialising;

  const TemplatesState({
    this.addedIds = const [],
    this.customTemplates = const [],
    this.selectedTemplateId,
    this.initialising = true,
  });

  /// Built-ins + customs, filtered to only those the user has added.
  /// Used by the "My Templates" tab.
  List<NoteTemplate> get myTemplates {
    final all = [...kDefaultTemplates, ...customTemplates];
    return all.where((t) => addedIds.contains(t.id)).toList();
  }

  /// Built-ins + customs. Used by the "All Templates" tab.
  List<NoteTemplate> get allTemplates => [...kDefaultTemplates, ...customTemplates];

  bool isAdded(String id) => addedIds.contains(id);
  bool isSelected(String id) => selectedTemplateId == id;

  TemplatesState copyWith({
    List<String>? addedIds,
    List<NoteTemplate>? customTemplates,
    String? selectedTemplateId,
    bool? initialising,
    bool clearSelected = false,
  }) =>
      TemplatesState(
        addedIds: addedIds ?? this.addedIds,
        customTemplates: customTemplates ?? this.customTemplates,
        selectedTemplateId:
            clearSelected ? null : (selectedTemplateId ?? this.selectedTemplateId),
        initialising: initialising ?? this.initialising,
      );
}

final templatesControllerProvider =
    StateNotifierProvider<TemplatesController, TemplatesState>((ref) {
  return TemplatesController();
});

class TemplatesController extends StateNotifier<TemplatesState> {
  TemplatesController() : super(const TemplatesState()) {
    _bootstrap();
  }

  /// Loads from shared_preferences. On first launch (no key yet), seeds
  /// addedIds with every default template ID — matching the web's
  /// "every new account starts with the full library" behaviour.
  Future<void> _bootstrap() async {
    final prefs = await SharedPreferences.getInstance();
    final rawIds = prefs.getString(_kAddedIdsKey);
    final rawCustom = prefs.getString(_kCustomTemplatesKey);

    List<String> ids;
    List<NoteTemplate> customs;

    if (rawIds != null) {
      try {
        ids = (jsonDecode(rawIds) as List).cast<String>();
      } catch (_) {
        ids = kDefaultTemplates.map((t) => t.id).toList();
      }
    } else {
      // First-launch seed → save AND surface so UI shows full library.
      ids = kDefaultTemplates.map((t) => t.id).toList();
      await prefs.setString(_kAddedIdsKey, jsonEncode(ids));
    }

    if (rawCustom != null) {
      try {
        customs = (jsonDecode(rawCustom) as List)
            .cast<Map<String, dynamic>>()
            .map(NoteTemplate.fromJson)
            .toList();
      } catch (_) {
        customs = const [];
      }
    } else {
      customs = const [];
    }

    state = state.copyWith(
      addedIds: ids,
      customTemplates: customs,
      initialising: false,
    );
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kAddedIdsKey, jsonEncode(state.addedIds));
    await prefs.setString(
      _kCustomTemplatesKey,
      jsonEncode(state.customTemplates.map((t) => t.toJson()).toList()),
    );
  }

  /// Add a template to "My Templates". Idempotent.
  Future<void> add(NoteTemplate t) async {
    if (state.addedIds.contains(t.id)) return;
    state = state.copyWith(addedIds: [...state.addedIds, t.id]);
    await _persist();
  }

  /// Remove a template from "My Templates". Does NOT delete the underlying
  /// custom template (use [delete] for that).
  Future<void> remove(NoteTemplate t) async {
    state = state.copyWith(
      addedIds: state.addedIds.where((id) => id != t.id).toList(),
    );
    await _persist();
  }

  Future<void> toggleAdd(NoteTemplate t) async {
    if (state.addedIds.contains(t.id)) {
      await remove(t);
    } else {
      await add(t);
    }
  }

  /// Permanently delete a custom template from the library. No-op on built-ins.
  Future<void> delete(NoteTemplate t) async {
    if (!t.isCustom) return;
    state = state.copyWith(
      customTemplates: state.customTemplates.where((c) => c.id != t.id).toList(),
      addedIds: state.addedIds.where((id) => id != t.id).toList(),
    );
    await _persist();
  }

  /// Save / replace a custom template. If a template with the same id
  /// already exists we replace it (edit flow); otherwise we append it
  /// AND auto-add it to My Templates.
  Future<void> upsertCustom(NoteTemplate t) async {
    final existing = state.customTemplates.indexWhere((c) => c.id == t.id);
    final next = [...state.customTemplates];
    if (existing >= 0) {
      next[existing] = t;
    } else {
      next.add(t);
    }
    final addedIds = state.addedIds.contains(t.id)
        ? state.addedIds
        : [...state.addedIds, t.id];
    state = state.copyWith(customTemplates: next, addedIds: addedIds);
    await _persist();
  }

  /// Mark a template as "currently selected" (for the Capture screen).
  void select(String id) {
    state = state.copyWith(selectedTemplateId: id);
  }

  void clearSelection() {
    state = state.copyWith(clearSelected: true);
  }

  /// Reset to default state — adds all built-ins, drops custom edits.
  /// Useful for a "Restore defaults" action.
  Future<void> resetToDefaults() async {
    state = state.copyWith(
      addedIds: kDefaultTemplates.map((t) => t.id).toList(),
      customTemplates: const [],
    );
    await _persist();
  }
}
