import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/api/api_client.dart';
import '../../core/api/notes_api.dart';
import '../../core/data/default_templates.dart';
import '../../core/models/note.dart';
import '../../core/theme/app_theme.dart';
import '../templates/templates_controller.dart';
import 'notes_controller.dart';
import 'section_map.dart';

/// Mirrors frontend/src/pages/NoteEditorPage.tsx 1:1.

class NoteEditorScreen extends ConsumerStatefulWidget {
  final String noteId;
  const NoteEditorScreen({super.key, required this.noteId});

  @override
  ConsumerState<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends ConsumerState<NoteEditorScreen> {
  ClinicalNote? _note;
  NoteContent _content = NoteContent.empty();
  final Map<String, TextEditingController> _ctrls = {};
  bool _hasChanges = false;
  bool _saving = false;
  bool _signing = false;
  bool _deleting = false;
  Timer? _pollTimer;

  @override
  void dispose() {
    for (final c in _ctrls.values) {
      c.dispose();
    }
    _pollTimer?.cancel();
    super.dispose();
  }

  /// Hydrate state once the note arrives. Keeps any text the user has typed
  /// since the last successful load — so a /notes/:id refresh during polling
  /// doesn't blow away in-progress edits.
  void _hydrate(ClinicalNote note) {
    final firstLoad = _note == null;
    _note = note;
    if (firstLoad || !_hasChanges) {
      _content = note.content;
      for (final entry in _content.toJson().entries) {
        if (entry.value is String) {
          _ctrls.putIfAbsent(entry.key, () => TextEditingController())
            ..text = entry.value as String;
        }
      }
    }
  }

  /// Fields are demand-created the first time a section asks for them.
  TextEditingController _ctrlFor(String key) {
    final existing = _ctrls[key];
    if (existing != null) return existing;
    final c = TextEditingController(text: _content.getField(key));
    _ctrls[key] = c;
    return c;
  }

  void _onFieldChange(String key, String value) {
    setState(() {
      _content = _content.setField(key, value);
      _hasChanges = true;
    });
  }

  Future<void> _save() async {
    final n = _note;
    if (n == null) return;
    setState(() => _saving = true);
    try {
      final updated = await ref.read(notesApiProvider).update(
            n.id,
            content: _content.toJson(),
          );
      if (!mounted) return;
      setState(() {
        _note = updated;
        _content = updated.content;
        _hasChanges = false;
        _saving = false;
      });
      _toast('Note saved successfully', AppColors.emerald500);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      _toast(e.message, AppColors.danger);
    }
  }

  Future<void> _sign() async {
    final n = _note;
    if (n == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => _SignDialog(),
    );
    if (ok != true) return;

    setState(() => _signing = true);
    try {
      // Save first if there are unsaved edits, then sign on the server.
      if (_hasChanges) {
        await ref.read(notesApiProvider).update(n.id, content: _content.toJson());
      }
      final signed = await ref.read(notesApiProvider).sign(n.id);
      if (!mounted) return;
      setState(() {
        _note = signed;
        _hasChanges = false;
        _signing = false;
      });
      _toast('Note signed and finalised', AppColors.emerald500);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _signing = false);
      _toast(e.message, AppColors.danger);
    }
  }

  Future<void> _delete() async {
    final n = _note;
    if (n == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => _DeleteDialog(patientName: n.patientName ?? 'this patient'),
    );
    if (ok != true) return;

    setState(() => _deleting = true);
    try {
      await ref.read(notesApiProvider).delete(n.id);
      if (!mounted) return;
      _toast('Note deleted', AppColors.emerald500);
      context.go('/notes');
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _deleting = false);
      _toast(e.message, AppColors.danger);
    }
  }

  void _copy() {
    final json = _content.toJson();
    final text = json.entries
        .where((e) => e.value is String && (e.value as String).trim().isNotEmpty)
        .map((e) => '${e.key.toUpperCase()}:\n${e.value}')
        .join('\n\n');
    if (text.isEmpty) {
      _toast('Note is empty — nothing to copy.', AppColors.warning);
      return;
    }
    Clipboard.setData(ClipboardData(text: text));
    _toast('Note copied to clipboard', AppColors.emerald500);
  }

  void _toast(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: color,
        content: Text(msg, style: const TextStyle(color: Colors.white)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Same priority as the web's deriveNoteTopic() (NoteEditorPage.tsx:28-54):
  /// content.topic → customSections.topic → first sentence of one of the
  /// known content fields.
  String _deriveTopic() {
    if ((_content.topic ?? '').trim().isNotEmpty) return _content.topic!.trim();
    final ct = _content.customSections['topic'];
    if (ct != null && ct.trim().isNotEmpty) return ct.trim();

    final candidates = [
      _content.chiefComplaint,
      _content.assessment,
      _content.subjective,
      _content.historyOfPresentIllness,
      _content.plan,
    ];
    for (final raw in candidates) {
      if (raw == null) continue;
      final trimmed = raw.trim();
      if (trimmed.isEmpty) continue;
      final firstSentence = trimmed.split(RegExp(r'(?<=[.!?])\s+|\n')).first.trim();
      return firstSentence.length > 90 ? '${firstSentence.substring(0, 87)}…' : firstSentence;
    }
    return '';
  }

  /// Resolve a templateId → list of section names. Mirrors getSections() on
  /// the web (NoteEditorPage.tsx:196-214). Falls back to default SOAP.
  List<String> _resolveSections() {
    final templates = ref.read(templatesControllerProvider);
    final id = _note?.templateId;
    if (id != null && id.isNotEmpty) {
      final builtIn = kDefaultTemplates.where((t) => t.id == id).firstOrNull;
      if (builtIn != null && builtIn.sections.isNotEmpty) return builtIn.sections;
      final custom = templates.customTemplates.where((t) => t.id == id).firstOrNull;
      if (custom != null && custom.sections.isNotEmpty) return custom.sections;
    }
    return const ['Subjective', 'Objective', 'Assessment', 'Plan', 'Patient Instructions'];
  }

  String _resolveTemplateName() {
    final id = _note?.templateId;
    if (id == null || id.isEmpty) return 'SOAP';
    final templates = ref.read(templatesControllerProvider);
    final builtIn = kDefaultTemplates.where((t) => t.id == id).firstOrNull;
    if (builtIn != null) return builtIn.name;
    final custom = templates.customTemplates.where((t) => t.id == id).firstOrNull;
    if (custom != null) return custom.name;
    // Fall back to humanising the id.
    final humanized = id
        .replaceAll(RegExp(r'^custom-\d+$'), 'Custom')
        .split('-')
        .map((p) => p.isEmpty ? p : p[0].toUpperCase() + p.substring(1))
        .join(' ');
    return humanized;
  }

  void _maybeStartPolling(ClinicalNote note) {
    if (note.status != NoteStatus.processing) {
      _pollTimer?.cancel();
      return;
    }
    if (_pollTimer?.isActive ?? false) return;
    _pollTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      ref.invalidate(noteProvider(widget.noteId));
    });
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(noteProvider(widget.noteId));

    return async.when(
      loading: () => const _LoadingShell(),
      error: (e, _) => _ErrorShell(error: e.toString()),
      data: (note) {
        _hydrate(note);
        _maybeStartPolling(note);
        return _buildEditor(note);
      },
    );
  }

  Widget _buildEditor(ClinicalNote note) {
    final isLocked = note.isSigned;
    final sections = _resolveSections();
    final topic = _deriveTopic();

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back
              TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.slate400,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                onPressed: () => context.canPop() ? context.pop() : context.go('/notes'),
                icon: const Icon(Icons.arrow_back, size: 16),
                label: const Text('Back to Notes', style: TextStyle(fontSize: 13)),
              ),
              const SizedBox(height: 6),

              _Header(
                note: note,
                topic: topic,
                templateName: _resolveTemplateName(),
                hasChanges: _hasChanges,
                isSaving: _saving,
                isSigning: _signing,
                onSave: (_hasChanges && !isLocked && !_saving) ? _save : null,
                onSign: (!isLocked && !_signing) ? _sign : null,
                onMenu: (action) async {
                  switch (action) {
                    case 'patient':
                      // Patient route uses :id in this app, but the web uses
                      // :patientName. We don't have the id here, so fall back
                      // to the patients list filtered by name search.
                      context.push('/patients');
                      break;
                    case 'copy':
                      _copy();
                      break;
                    case 'export':
                      _toast(
                        'Export coming soon — the backend /notes/:id/export endpoint is wired on web only.',
                        AppColors.warning,
                      );
                      break;
                    case 'sign':
                      await _sign();
                      break;
                    case 'delete':
                      await _delete();
                      break;
                  }
                },
                isLocked: isLocked,
                deleting: _deleting,
              ),
              const SizedBox(height: 16),

              if (note.isProcessing) _ProcessingBanner(),

              if (note.isProcessing) const SizedBox(height: 14),

              // Section cards
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0x0AFFFFFF),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0x14FFFFFF)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (final section in sections)
                            _SectionField(
                              label: section,
                              fieldKey: sectionKeyFor(section),
                              controller: _ctrlFor(sectionKeyFor(section)),
                              isLocked: isLocked || note.isProcessing,
                              onChanged: (v) =>
                                  _onFieldChange(sectionKeyFor(section), v),
                            ),
                          if (_content.legacyText.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.warning.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.warning.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'LEGACY CONTENT',
                                    style: TextStyle(
                                      color: AppColors.warning,
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    _content.legacyText,
                                    style: const TextStyle(
                                      color: AppColors.slate200,
                                      fontSize: 13,
                                      height: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Footer
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                      decoration: const BoxDecoration(
                        color: Color(0x08FFFFFF),
                        border: Border(
                          top: BorderSide(color: Color(0x14FFFFFF)),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Last updated: ${DateFormat('MMM d, y h:mm a').format(note.updatedAt)}',
                              style: const TextStyle(color: AppColors.slate400, fontSize: 11.5),
                            ),
                          ),
                          if (_hasChanges)
                            Row(
                              children: [
                                Container(
                                  width: 7,
                                  height: 7,
                                  decoration: const BoxDecoration(
                                    color: AppColors.warning,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Text(
                                  'Unsaved changes',
                                  style: TextStyle(color: AppColors.warning, fontSize: 11.5, fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Header
// ─────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final ClinicalNote note;
  final String topic;
  final String templateName;
  final bool hasChanges;
  final bool isSaving;
  final bool isSigning;
  final bool isLocked;
  final bool deleting;
  final VoidCallback? onSave;
  final VoidCallback? onSign;
  final ValueChanged<String> onMenu;

  const _Header({
    required this.note,
    required this.topic,
    required this.templateName,
    required this.hasChanges,
    required this.isSaving,
    required this.isSigning,
    required this.isLocked,
    required this.deleting,
    required this.onSave,
    required this.onSign,
    required this.onMenu,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 4,
                children: [
                  Text(
                    note.patientName ?? 'Patient',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.4,
                    ),
                  ),
                  _StatusBadge(status: note.status),
                ],
              ),
            ),
          ],
        ),
        if (topic.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            topic,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),
        ],
        const SizedBox(height: 6),
        Wrap(
          spacing: 12,
          runSpacing: 4,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.access_time, size: 13, color: AppColors.slate400),
                const SizedBox(width: 5),
                Text(
                  DateFormat('MMMM d, y').format(note.createdAt),
                  style: const TextStyle(color: AppColors.slate400, fontSize: 12.5),
                ),
              ],
            ),
            Text(
              '$templateName Template',
              style: const TextStyle(color: AppColors.slate400, fontSize: 12.5),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Action row
        Row(
          children: [
            // Save button
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: onSave != null ? kEmeraldGradient : null,
                color: onSave == null ? const Color(0x1AFFFFFF) : null,
                borderRadius: BorderRadius.circular(11),
              ),
              child: TextButton.icon(
                onPressed: onSave,
                icon: isSaving
                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white))
                    : const Icon(Icons.save_outlined, size: 14, color: Colors.white),
                label: const Text('Save',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12.5)),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  disabledForegroundColor: Colors.white.withValues(alpha: 0.4),
                ),
              ),
            ),
            const SizedBox(width: 6),
            if (!isLocked)
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF2563EB), Color(0xFF3B82F6)]),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: TextButton.icon(
                  onPressed: onSign,
                  icon: isSigning
                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white))
                      : const Icon(Icons.check_circle_outline, size: 14, color: Colors.white),
                  label: const Text('Sign',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12.5)),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ),
            const Spacer(),
            // Three-dot menu
            PopupMenuButton<String>(
              onSelected: onMenu,
              color: AppColors.slate800,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: const BorderSide(color: Color(0x1FFFFFFF)),
              ),
              icon: const Icon(Icons.more_vert, color: AppColors.slate300),
              itemBuilder: (_) => [
                _menuItem('patient', Icons.person_outline, AppColors.info, 'View Patient'),
                _menuItem('copy', Icons.copy, AppColors.slate400, 'Copy Note'),
                _menuItem('export', Icons.download, AppColors.emerald400, 'Export PDF'),
                if (!isLocked)
                  _menuItem('sign', Icons.check_circle_outline, AppColors.info, 'Sign Note'),
                const PopupMenuDivider(),
                _menuItem('delete', Icons.delete_outline, AppColors.danger, 'Delete Note', isDestructive: true),
              ],
            ),
          ],
        ),
      ],
    );
  }

  PopupMenuItem<String> _menuItem(String value, IconData icon, Color color, String label, {bool isDestructive = false}) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              color: isDestructive ? AppColors.danger : Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Status badge
// ─────────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final NoteStatus status;
  const _StatusBadge({required this.status});

  Color get _color {
    switch (status) {
      case NoteStatus.signed:
        return AppColors.emerald400;
      case NoteStatus.completed:
      case NoteStatus.ready:
        return AppColors.info;
      case NoteStatus.processing:
      case NoteStatus.draft:
        return AppColors.warning;
      case NoteStatus.failed:
        return AppColors.danger;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: _color.withValues(alpha: 0.4)),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: _color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Section field
// ─────────────────────────────────────────────────────────────────

class _SectionField extends StatelessWidget {
  final String label;
  final String fieldKey;
  final TextEditingController controller;
  final bool isLocked;
  final ValueChanged<String> onChanged;

  const _SectionField({
    required this.label,
    required this.fieldKey,
    required this.controller,
    required this.isLocked,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.edit_outlined, size: 13, color: AppColors.emerald400),
              const SizedBox(width: 6),
              Text(
                label.toUpperCase(),
                style: const TextStyle(
                  color: AppColors.emerald400,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.7,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            enabled: !isLocked,
            onChanged: onChanged,
            maxLines: null,
            minLines: 4,
            style: const TextStyle(color: Colors.white, fontSize: 13.5, height: 1.55),
            decoration: InputDecoration(
              hintText: 'Enter ${label.toLowerCase()} details…',
              hintStyle: const TextStyle(color: Color(0x40FFFFFF)),
              filled: true,
              fillColor: isLocked ? const Color(0x05FFFFFF) : const Color(0x0DFFFFFF),
              contentPadding: const EdgeInsets.all(14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0x1FFFFFFF)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0x1FFFFFFF)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.emerald400.withValues(alpha: 0.5), width: 1.5),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0x14FFFFFF)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Banners + dialogs
// ─────────────────────────────────────────────────────────────────

class _ProcessingBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
      ),
      child: const Row(
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2.2, color: AppColors.warning),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Processing your audio… Generating clinical notes with AI. This usually takes 30–60 seconds.',
              style: TextStyle(color: Colors.white, fontSize: 13, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _SignDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.slate900,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text(
        'Sign Clinical Note',
        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
      ),
      content: const Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'By signing this note, you confirm that:',
            style: TextStyle(color: AppColors.slate400, fontSize: 13.5, height: 1.5),
          ),
          SizedBox(height: 14),
          _SignBullet(text: 'The information in this note is accurate and complete'),
          _SignBullet(text: 'You have reviewed and verified all sections'),
          _SignBullet(text: 'The note will be locked and cannot be edited after signing'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          style: TextButton.styleFrom(foregroundColor: AppColors.slate300),
          child: const Text('Cancel'),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: kEmeraldGradient,
            borderRadius: BorderRadius.circular(11),
          ),
          child: TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            child: const Text('Sign Note', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ),
      ],
    );
  }
}

class _SignBullet extends StatelessWidget {
  final String text;
  const _SignBullet({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, size: 16, color: AppColors.emerald400),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: AppColors.slate200, fontSize: 13, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _DeleteDialog extends StatelessWidget {
  final String patientName;
  const _DeleteDialog({required this.patientName});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.slate900,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text(
        'Delete Note',
        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
      ),
      content: Text.rich(
        TextSpan(
          style: const TextStyle(color: AppColors.slate400, fontSize: 13.5, height: 1.5),
          children: [
            const TextSpan(text: 'Are you sure you want to delete this note for '),
            TextSpan(
              text: patientName,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
            ),
            const TextSpan(text: '? This action cannot be undone.'),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          style: TextButton.styleFrom(foregroundColor: AppColors.slate300),
          child: const Text('Cancel'),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.danger,
            borderRadius: BorderRadius.circular(11),
          ),
          child: TextButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.delete_outline, size: 14, color: Colors.white),
            label: const Text(
              'Delete Note',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
            ),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Loading / error shells
// ─────────────────────────────────────────────────────────────────

class _LoadingShell extends StatelessWidget {
  const _LoadingShell();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: const SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AppColors.emerald400),
              SizedBox(height: 14),
              Text(
                'Loading note…',
                style: TextStyle(color: AppColors.slate400, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorShell extends StatelessWidget {
  final String error;
  const _ErrorShell({required this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: AppColors.danger, size: 48),
                const SizedBox(height: 12),
                Text('Could not load note:\n$error',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white)),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => context.canPop() ? context.pop() : context.go('/notes'),
                  icon: const Icon(Icons.arrow_back, size: 16),
                  label: const Text('Back to Notes'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
