import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/api/api_client.dart';
import '../../core/api/notes_api.dart';
import '../../core/models/note.dart';
import '../../core/theme/app_theme.dart';
import 'notes_controller.dart';

class NoteEditorScreen extends ConsumerStatefulWidget {
  final String noteId;
  const NoteEditorScreen({super.key, required this.noteId});

  @override
  ConsumerState<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends ConsumerState<NoteEditorScreen> {
  final _titleCtrl = TextEditingController();
  final _patientCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  bool _hydrated = false;
  bool _saving = false;
  bool _signing = false;
  Timer? _pollTimer;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _patientCtrl.dispose();
    _contentCtrl.dispose();
    _pollTimer?.cancel();
    super.dispose();
  }

  void _hydrateFrom(ClinicalNote note) {
    if (_hydrated) return;
    _titleCtrl.text = note.title;
    _patientCtrl.text = note.patientName ?? '';
    _contentCtrl.text = note.content;
    _hydrated = true;
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

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref.read(notesApiProvider).update(
            widget.noteId,
            title: _titleCtrl.text.trim(),
            content: _contentCtrl.text,
            patientName: _patientCtrl.text.trim().isEmpty ? null : _patientCtrl.text.trim(),
          );
      ref.invalidate(noteProvider(widget.noteId));
      if (!mounted) return;
      _toast('Saved.', AppColors.emerald500);
    } on ApiException catch (e) {
      if (!mounted) return;
      _toast(e.message, AppColors.danger);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _sign() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.slate800,
        title: const Text('Sign this note?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Once signed, the note becomes part of the patient record and cannot be edited.',
          style: TextStyle(color: AppColors.slate400),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sign', style: TextStyle(color: AppColors.emerald400, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (ok != true) return;

    setState(() => _signing = true);
    try {
      await _save();
      await ref.read(notesApiProvider).sign(widget.noteId);
      ref.invalidate(noteProvider(widget.noteId));
      if (!mounted) return;
      _toast('Note signed.', AppColors.emerald500);
    } on ApiException catch (e) {
      if (!mounted) return;
      _toast(e.message, AppColors.danger);
    } finally {
      if (mounted) setState(() => _signing = false);
    }
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

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(noteProvider(widget.noteId));

    return async.when(
      loading: () => Scaffold(
        backgroundColor: AppColors.bgPrimary,
        appBar: AppBar(leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/notes'))),
        body: const Center(child: CircularProgressIndicator(color: AppColors.emerald400)),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: AppColors.bgPrimary,
        appBar: AppBar(leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/notes'))),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Could not load this note:\n$e',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
          ),
        ),
      ),
      data: (note) {
        _hydrateFrom(note);
        _maybeStartPolling(note);
        return _buildEditor(note);
      },
    );
  }

  Widget _buildEditor(ClinicalNote note) {
    final isLocked = note.isSigned;

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/notes'),
        ),
        title: const Text('Note'),
        actions: [
          if (!isLocked)
            IconButton(
              tooltip: 'Save',
              icon: _saving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white))
                  : const Icon(Icons.save_outlined),
              onPressed: _saving ? null : _save,
            ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            _StatusBadge(status: note.status),
            const SizedBox(height: 12),
            if (note.isProcessing)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.12),
                  border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.2, color: AppColors.warning)),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Generating note from your audio… this usually takes 30–60 seconds.',
                        style: TextStyle(color: Colors.white, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            TextField(
              controller: _titleCtrl,
              enabled: !isLocked,
              style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700),
              decoration: const InputDecoration(
                labelText: 'Title',
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _patientCtrl,
              enabled: !isLocked,
              decoration: const InputDecoration(
                labelText: 'Patient',
                prefixIcon: Icon(Icons.person_outline, color: AppColors.slate400),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Row(
                children: [
                  const Icon(Icons.history, color: AppColors.slate400, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Updated ${DateFormat('MMM d, y · h:mm a').format(note.updatedAt.toLocal())}',
                      style: const TextStyle(color: AppColors.slate400, fontSize: 12),
                    ),
                  ),
                  if (note.durationSeconds != null) ...[
                    const Icon(Icons.access_time, color: AppColors.slate400, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      _formatSeconds(note.durationSeconds!),
                      style: const TextStyle(color: AppColors.slate400, fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Note',
              style: TextStyle(color: AppColors.slate400, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.5),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _contentCtrl,
              enabled: !isLocked && !note.isProcessing,
              maxLines: null,
              minLines: 12,
              style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.5),
              decoration: InputDecoration(
                hintText: note.isProcessing
                    ? 'AI is drafting this note…'
                    : 'Edit the generated clinical note here.',
                alignLabelWithHint: true,
              ),
            ),
            if (note.transcript != null && note.transcript!.isNotEmpty) ...[
              const SizedBox(height: 24),
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                iconColor: AppColors.slate400,
                collapsedIconColor: AppColors.slate400,
                title: const Text(
                  'Transcript',
                  style: TextStyle(color: AppColors.slate400, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.5),
                ),
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.cardBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: SelectableText(
                      note.transcript!,
                      style: const TextStyle(color: AppColors.slate400, fontSize: 13, height: 1.5),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 24),
            if (!isLocked)
              SizedBox(
                width: double.infinity,
                height: 52,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: kEmeraldGradient,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _signing || note.isProcessing ? null : _sign,
                      borderRadius: BorderRadius.circular(14),
                      child: Center(
                        child: _signing
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.verified_outlined, color: Colors.white, size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    'Save & sign note',
                                    style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.emerald500.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.emerald500.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.lock_outline, color: AppColors.emerald400),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Signed ${note.signedAt != null ? DateFormat('MMM d, y · h:mm a').format(note.signedAt!.toLocal()) : ''}',
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  static String _formatSeconds(int s) {
    final h = s ~/ 3600;
    final m = (s % 3600) ~/ 60;
    final sec = s % 60;
    if (h > 0) return '${h}h ${m}m';
    if (m > 0) return '${m}m ${sec}s';
    return '${sec}s';
  }
}

class _StatusBadge extends StatelessWidget {
  final NoteStatus status;
  const _StatusBadge({required this.status});

  Color get _color {
    switch (status) {
      case NoteStatus.signed:
        return AppColors.emerald400;
      case NoteStatus.processing:
        return AppColors.warning;
      case NoteStatus.failed:
        return AppColors.danger;
      case NoteStatus.ready:
        return AppColors.info;
      case NoteStatus.draft:
        return AppColors.slate400;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: _color.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          status.label,
          style: TextStyle(color: _color, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.4),
        ),
      ),
    );
  }
}
