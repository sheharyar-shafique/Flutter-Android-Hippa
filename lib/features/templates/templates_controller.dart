import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/api/templates_api.dart';
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
  final api = ref.watch(templatesApiProvider);
  return TemplatesController(api);
});

class TemplatesController extends StateNotifier<TemplatesState> {
  final TemplatesApi _api;

  TemplatesController(this._api) : super(const TemplatesState()) {
    _bootstrap();
  }

  /// Loads from server first (authoritative), falls back to local storage.
  /// Matches TemplatesPage.tsx: useEffect → templatesApi.getPreferences()
  Future<void> _bootstrap() async {
    final prefs = await SharedPreferences.getInstance();

    // Try server first (cross-device sync)
    try {
      final serverPrefs = await _api.getPreferences();
      if (serverPrefs != null) {
        // Server has data → authoritative, use it
        final serverIds = (serverPrefs['addedIds'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            [];
        final serverCustomRaw = serverPrefs['customTemplates'] as List? ?? [];
        final serverCustom = serverCustomRaw
            .map((e) => NoteTemplate.fromJson(e as Map<String, dynamic>))
            .toList();

        // Cache to local storage
        await prefs.setString(_kAddedIdsKey, jsonEncode(serverIds));
        await prefs.setString(
          _kCustomTemplatesKey,
          jsonEncode(serverCustom.map((t) => t.toJson()).toList()),
        );

        state = state.copyWith(
          addedIds: serverIds,
          customTemplates: serverCustom,
          initialising: false,
        );
        return;
      } else {
        // No server data yet (new user) → check local storage first before
        // seeding defaults, so we don't overwrite another device's preferences.
        final rawIds = prefs.getString(_kAddedIdsKey);
        if (rawIds != null) {
          // Local storage has data (maybe from a previous session) → use it
          // but DON'T overwrite the server since we don't know what's there.
          try {
            final ids = (jsonDecode(rawIds) as List).cast<String>();
            final rawCustom = prefs.getString(_kCustomTemplatesKey);
            List<NoteTemplate> customs = const [];
            if (rawCustom != null) {
              try {
                customs = (jsonDecode(rawCustom) as List)
                    .cast<Map<String, dynamic>>()
                    .map(NoteTemplate.fromJson)
                    .toList();
              } catch (_) {}
            }
            state = state.copyWith(
              addedIds: ids,
              customTemplates: customs,
              initialising: false,
            );
            return;
          } catch (_) {
            // Corrupted local data — fall through to seed defaults
          }
        }

        // Truly new user (no server data AND no local data) → seed with defaults
        final defaultIds = kDefaultTemplates.map((t) => t.id).toList();
        state = state.copyWith(
          addedIds: defaultIds,
          customTemplates: const [],
          initialising: false,
        );
        // Bootstrap server so other devices stay in sync
        _api.savePreferences(defaultIds, []).catchError((_) {});
        await prefs.setString(_kAddedIdsKey, jsonEncode(defaultIds));
        return;
      }
    } catch (_) {
      // Server unavailable → fall back to local storage
    }

    // Fallback: load from SharedPreferences (server was unreachable)
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
      // First-launch seed — but do NOT save to server (we're offline)
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

  /// Persist to both localStorage (fast) and server (cross-device).
  /// Mirrors web's persistPreferences() function.
  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kAddedIdsKey, jsonEncode(state.addedIds));
    await prefs.setString(
      _kCustomTemplatesKey,
      jsonEncode(state.customTemplates.map((t) => t.toJson()).toList()),
    );
    // Sync to server (fire and forget)
    _api
        .savePreferences(
          state.addedIds,
          state.customTemplates.map((t) => t.toJson()).toList(),
        )
        .catchError((_) {});
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
