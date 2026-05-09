import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/api/audio_api.dart';
import '../../core/api/notes_api.dart';
import '../../core/api/patients_api.dart';
import '../../core/models/note.dart';
import '../../core/models/patient.dart';
import '../../core/theme/app_theme.dart';
import 'patient_storage.dart';

/// Mirrors frontend/src/pages/PatientPage.tsx — header + 5 tabs (Overview,
/// Notes, Context, Treatment Plan, Reports). Mobile concession: notes/reports
/// render as cards instead of tables; tab strip is horizontally scrollable.

final _patientProvider = FutureProvider.family.autoDispose<Patient, String>((ref, id) async {
  return ref.watch(patientsApiProvider).get(id);
});

final _patientNotesProvider = FutureProvider.family.autoDispose<List<ClinicalNote>, String>((ref, name) async {
  final page = await ref.watch(notesApiProvider).list(search: name);
  return page.notes
      .where((n) =>
          n.patientName != null &&
          n.patientName!.toLowerCase() == name.toLowerCase())
      .toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
});

class PatientDetailScreen extends ConsumerWidget {
  final String patientId;
  const PatientDetailScreen({super.key, required this.patientId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final patientAsync = ref.watch(_patientProvider(patientId));

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SafeArea(
        child: patientAsync.when(
          loading: () => const Center(child: CircularProgressIndicator(color: AppColors.emerald400)),
          error: (e, _) => _ErrorView(error: e.toString()),
          data: (patient) => _PatientView(patient: patient),
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String error;
  const _ErrorView({required this.error});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppColors.danger, size: 48),
            const SizedBox(height: 12),
            Text('Could not load patient:\n$error',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => context.canPop() ? context.pop() : context.go('/patients'),
              icon: const Icon(Icons.arrow_back, size: 16),
              label: const Text('Back to patients'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Main view
// ─────────────────────────────────────────────────────────────────

class _PatientView extends ConsumerStatefulWidget {
  final Patient patient;
  const _PatientView({required this.patient});

  @override
  ConsumerState<_PatientView> createState() => _PatientViewState();
}

class _PatientViewState extends ConsumerState<_PatientView> {
  static const _tabs = [
    ('overview', 'Overview', Icons.person_outline),
    ('notes', 'Patient Notes', Icons.description_outlined),
    ('context', 'Patient Context', Icons.psychology_outlined),
    ('treatment', 'Treatment Plan', Icons.medical_services_outlined),
    ('reports', 'Reports', Icons.bar_chart),
  ];

  String _activeTab = 'overview';
  PatientProfile? _profile;
  bool _profileDirty = false;

  @override
  void initState() {
    super.initState();
    PatientStorage.loadProfile(widget.patient.name).then((p) {
      if (mounted) setState(() => _profile = p);
    });
  }

  void _onProfileChanged(PatientProfile updated) {
    setState(() {
      _profile = updated;
      _profileDirty = true;
    });
  }

  Future<void> _saveProfile() async {
    if (_profile == null) return;
    await PatientStorage.saveProfile(_profile!);
    if (!mounted) return;
    setState(() => _profileDirty = false);
    _toast('Patient profile saved', AppColors.emerald500);
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
    final p = widget.patient;
    final profile = _profile;
    final notesAsync = ref.watch(_patientNotesProvider(p.name));
    final noteCount = notesAsync.maybeWhen(data: (l) => l.length, orElse: () => 0);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back button
          TextButton.icon(
            style: TextButton.styleFrom(
              foregroundColor: AppColors.slate400,
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            onPressed: () => context.canPop() ? context.pop() : context.go('/patients'),
            icon: const Icon(Icons.arrow_back, size: 16),
            label: const Text('Back', style: TextStyle(fontSize: 13)),
          ),
          const SizedBox(height: 6),

          // Header
          _PatientHeader(
            patient: p,
            profile: profile,
            noteCount: noteCount,
            isDirty: _profileDirty,
            onSave: _saveProfile,
            onNewConversation: () => context.push('/capture'),
          ),

          const SizedBox(height: 16),

          // Tab strip
          _TabStrip(
            active: _activeTab,
            tabs: _tabs,
            onChanged: (t) => setState(() => _activeTab = t),
          ),

          const SizedBox(height: 16),

          // Tab content
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: KeyedSubtree(
              key: ValueKey(_activeTab),
              child: _buildTab(p, profile, notesAsync),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(Patient p, PatientProfile? profile, AsyncValue<List<ClinicalNote>> notesAsync) {
    switch (_activeTab) {
      case 'overview':
        if (profile == null) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(child: CircularProgressIndicator(color: AppColors.emerald400)),
          );
        }
        return _OverviewTab(
          profile: profile,
          notesAsync: notesAsync,
          onChanged: _onProfileChanged,
          onNewConversation: () => context.push('/capture'),
        );
      case 'notes':
        return _NotesTab(notesAsync: notesAsync);
      case 'context':
        return _ContextTab(patientName: p.name);
      case 'treatment':
        return _TreatmentTab(patientName: p.name, notesAsync: notesAsync);
      case 'reports':
        return _ReportsTab(patientName: p.name, notesAsync: notesAsync);
      default:
        return const SizedBox.shrink();
    }
  }
}

// ─────────────────────────────────────────────────────────────────
// Header (avatar + name + pronoun + count + Save / New Conversation)
// ─────────────────────────────────────────────────────────────────

class _PatientHeader extends StatelessWidget {
  final Patient patient;
  final PatientProfile? profile;
  final int noteCount;
  final bool isDirty;
  final VoidCallback onSave;
  final VoidCallback onNewConversation;

  const _PatientHeader({
    required this.patient,
    required this.profile,
    required this.noteCount,
    required this.isDirty,
    required this.onSave,
    required this.onNewConversation,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: kEmeraldGradient,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.emerald500.withValues(alpha: 0.35),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Center(
            child: Text(
              patient.name.isEmpty ? '?' : patient.name[0].toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                patient.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.4,
                ),
              ),
              Text(
                '${profile?.pronoun ?? ""} · $noteCount note${noteCount == 1 ? '' : 's'}',
                style: const TextStyle(color: AppColors.slate400, fontSize: 12.5),
              ),
            ],
          ),
        ),
        if (isDirty) ...[
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.emerald500,
              borderRadius: BorderRadius.circular(11),
            ),
            child: TextButton.icon(
              onPressed: onSave,
              icon: const Icon(Icons.save_outlined, size: 14, color: Colors.white),
              label: const Text('Save',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12.5)),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              ),
            ),
          ),
          const SizedBox(width: 6),
        ],
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF2563EB), Color(0xFF3B82F6)],
            ),
            borderRadius: BorderRadius.circular(11),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2563EB).withValues(alpha: 0.4),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextButton.icon(
            onPressed: onNewConversation,
            icon: const Icon(Icons.mic, size: 14, color: Colors.white),
            label: const Text(
              'New Conversation',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12.5),
            ),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Tab strip
// ─────────────────────────────────────────────────────────────────

class _TabStrip extends StatelessWidget {
  final String active;
  final List<(String, String, IconData)> tabs;
  final ValueChanged<String> onChanged;

  const _TabStrip({required this.active, required this.tabs, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0x1AFFFFFF), width: 1)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: tabs.map((t) {
            final isActive = active == t.$1;
            return Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => onChanged(t.$1),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: isActive ? Colors.white : Colors.transparent,
                        width: 2,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(t.$3, size: 14, color: isActive ? Colors.white : AppColors.slate400),
                      const SizedBox(width: 6),
                      Text(
                        t.$2,
                        style: TextStyle(
                          color: isActive ? Colors.white : AppColors.slate400,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Overview tab
// ─────────────────────────────────────────────────────────────────

class _OverviewTab extends StatefulWidget {
  final PatientProfile profile;
  final AsyncValue<List<ClinicalNote>> notesAsync;
  final ValueChanged<PatientProfile> onChanged;
  final VoidCallback onNewConversation;

  const _OverviewTab({
    required this.profile,
    required this.notesAsync,
    required this.onChanged,
    required this.onNewConversation,
  });

  @override
  State<_OverviewTab> createState() => _OverviewTabState();
}

class _OverviewTabState extends State<_OverviewTab> {
  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _dobCtrl;

  static const _pronouns = ['He/Him', 'She/Her', 'They/Them', 'Ze/Zir', 'Other'];

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.profile.name);
    _phoneCtrl = TextEditingController(text: widget.profile.phone);
    _emailCtrl = TextEditingController(text: widget.profile.email);
    _dobCtrl = TextEditingController(text: widget.profile.dob);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _dobCtrl.dispose();
    super.dispose();
  }

  void _emit() {
    widget.onChanged(widget.profile.copyWith(
      name: _nameCtrl.text,
      phone: _phoneCtrl.text,
      email: _emailCtrl.text,
      dob: _dobCtrl.text,
    ));
  }

  Future<void> _pickDob() async {
    final initial = DateTime.tryParse(_dobCtrl.text) ?? DateTime(2000);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(primary: AppColors.emerald400),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      _dobCtrl.text = picked.toIso8601String().split('T').first;
      _emit();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _FieldLabel(text: 'Pronoun and Name'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0x0DFFFFFF),
                      borderRadius: BorderRadius.circular(11),
                      border: Border.all(color: const Color(0x1AFFFFFF)),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: widget.profile.pronoun,
                        dropdownColor: AppColors.slate800,
                        iconEnabledColor: AppColors.slate400,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        items: _pronouns
                            .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                            .toList(),
                        onChanged: (v) {
                          if (v != null) widget.onChanged(widget.profile.copyWith(pronoun: v));
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StyledField(
                      controller: _nameCtrl,
                      hint: 'Patient name',
                      onChanged: (_) => _emit(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const _FieldLabel(text: 'Patient Phone Number', icon: Icons.phone_outlined),
              const SizedBox(height: 8),
              _StyledField(
                controller: _phoneCtrl,
                hint: 'Phone number',
                keyboardType: TextInputType.phone,
                onChanged: (_) => _emit(),
              ),
              const SizedBox(height: 18),
              const _FieldLabel(text: 'Patient Email', icon: Icons.mail_outlined),
              const SizedBox(height: 8),
              _StyledField(
                controller: _emailCtrl,
                hint: 'patient@email.com',
                keyboardType: TextInputType.emailAddress,
                onChanged: (_) => _emit(),
              ),
              const SizedBox(height: 18),
              const _FieldLabel(text: 'Date of Birth', icon: Icons.calendar_today_outlined),
              const SizedBox(height: 4),
              const Text(
                'You can tap to pick from the calendar or type as YYYY-MM-DD',
                style: TextStyle(color: AppColors.slate500, fontSize: 11.5),
              ),
              const SizedBox(height: 8),
              _StyledField(
                controller: _dobCtrl,
                hint: 'YYYY-MM-DD',
                onChanged: (_) => _emit(),
                readOnly: true,
                onTap: _pickDob,
                prefixIcon: const Icon(Icons.calendar_today, size: 14, color: AppColors.slate500),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Last Note Summary
        widget.notesAsync.when(
          loading: () => const _Card(
            child: Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 28),
                child: CircularProgressIndicator(color: AppColors.emerald400),
              ),
            ),
          ),
          error: (_, __) => const SizedBox.shrink(),
          data: (notes) {
            if (notes.isEmpty) {
              return _Card(
                child: Column(
                  children: [
                    const Icon(Icons.error_outline, color: AppColors.slate500, size: 30),
                    const SizedBox(height: 8),
                    const Text(
                      'No notes found for this patient yet.',
                      style: TextStyle(color: AppColors.slate400, fontSize: 13),
                    ),
                    const SizedBox(height: 14),
                    ElevatedButton(
                      onPressed: widget.onNewConversation,
                      child: const Text('Start New Conversation'),
                    ),
                  ],
                ),
              );
            }
            final last = notes.first;
            final summary = _buildSummary(last);
            return _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Last Note Summary',
                    style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 12),
                  ...summary.map(
                    (line) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        line,
                        style: const TextStyle(color: AppColors.slate300, fontSize: 13, height: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(height: 1, color: const Color(0x14FFFFFF)),
                  const SizedBox(height: 10),
                  Text(
                    DateFormat('MMM d, y, h:mm a').format(last.updatedAt),
                    style: const TextStyle(color: AppColors.slate500, fontSize: 11),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  /// Same priority as the web's buildSummary() (PatientPage.tsx:175-202).
  List<String> _buildSummary(ClinicalNote n) {
    final lines = <String>[];
    final c = n.content;
    String _clip(String s) => s.length > 180 ? '${s.substring(0, 180)}…' : s;

    if ((c.subjective ?? '').isNotEmpty) lines.add(_clip(c.subjective!.trim()));
    if ((c.objective ?? '').isNotEmpty) lines.add(_clip(c.objective!.trim()));
    if ((c.assessment ?? '').isNotEmpty) {
      final patient = n.patientName ?? 'The patient';
      lines.add('$patient was assessed: ${_clip(c.assessment!.trim())}');
    }
    if ((c.instructions ?? '').isNotEmpty) {
      final patient = n.patientName ?? 'The patient';
      lines.add('$patient was instructed to ${_clip(c.instructions!.trim())}');
    } else if ((c.plan ?? '').isNotEmpty) {
      lines.add('Plan: ${_clip(c.plan!.trim())}');
    }
    // Legacy / unstructured content fallback.
    if (lines.isEmpty && c.legacyText.isNotEmpty) {
      lines.add(_clip(c.legacyText));
    }
    if (lines.isEmpty) {
      lines.add('No summary content available from the last note.');
    }
    return lines;
  }
}

// ─────────────────────────────────────────────────────────────────
// Notes tab
// ─────────────────────────────────────────────────────────────────

class _NotesTab extends StatelessWidget {
  final AsyncValue<List<ClinicalNote>> notesAsync;
  const _NotesTab({required this.notesAsync});

  @override
  Widget build(BuildContext context) {
    return notesAsync.when(
      loading: () => const _Card(
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: CircularProgressIndicator(color: AppColors.emerald400),
          ),
        ),
      ),
      error: (e, _) => _Card(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(
              'Could not load notes:\n$e',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.danger),
            ),
          ),
        ),
      ),
      data: (notes) {
        if (notes.isEmpty) {
          return const _Card(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 28),
              child: Column(
                children: [
                  Icon(Icons.description_outlined, color: AppColors.slate500, size: 32),
                  SizedBox(height: 10),
                  Text('No notes yet for this patient.',
                      style: TextStyle(color: AppColors.slate400, fontSize: 13)),
                ],
              ),
            ),
          );
        }
        return Column(
          children: notes.map((n) => _NoteRow(note: n)).toList(),
        );
      },
    );
  }
}

class _NoteRow extends StatelessWidget {
  final ClinicalNote note;
  const _NoteRow({required this.note});

  String _formatDuration(int? s) {
    if (s == null || s <= 0) return '—';
    if (s < 60) return '$s sec';
    final m = s ~/ 60;
    final r = s % 60;
    return r == 0 ? '$m min' : '$m min $r sec';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: const Color(0x0AFFFFFF),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => context.push('/notes/${note.id}'),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0x14FFFFFF)),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.emerald500.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.description_outlined, color: AppColors.emerald400, size: 17),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        note.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${_formatDuration(note.durationSeconds)} · ${DateFormat("MMM d, y, h:mm a").format(note.updatedAt)}',
                        style: const TextStyle(color: AppColors.slate400, fontSize: 11.5),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, size: 18, color: AppColors.slate500),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Context tab
// ─────────────────────────────────────────────────────────────────

class _ContextTab extends StatefulWidget {
  final String patientName;
  const _ContextTab({required this.patientName});

  @override
  State<_ContextTab> createState() => _ContextTabState();
}

class _ContextTabState extends State<_ContextTab> {
  final _ctrl = TextEditingController();
  bool _dirty = false;
  bool _saving = false;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    PatientStorage.loadContext(widget.patientName).then((c) {
      if (mounted) {
        setState(() {
          _ctrl.text = c;
          _loaded = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await PatientStorage.saveContext(widget.patientName, _ctrl.text);
    if (!mounted) return;
    setState(() {
      _saving = false;
      _dirty = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: AppColors.emerald500,
        content: Text('Patient context saved', style: TextStyle(color: Colors.white)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const _Card(
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: CircularProgressIndicator(color: AppColors.emerald400),
          ),
        ),
      );
    }
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Patient Context',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          const Text(
            'This context will be used by the system when generating notes. It will apply to all notes for this patient.',
            style: TextStyle(color: AppColors.slate400, fontSize: 12.5, height: 1.5),
          ),
          const SizedBox(height: 4),
          const Text(
            'Context may include known conditions, goals or details which do not come up in a conversation but may affect the note.',
            style: TextStyle(color: AppColors.slate400, fontSize: 12.5, height: 1.5),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _ctrl,
            onChanged: (_) => setState(() => _dirty = true),
            maxLines: 12,
            minLines: 8,
            style: const TextStyle(color: Colors.white, fontSize: 13.5, height: 1.5),
            decoration: InputDecoration(
              hintText:
                  'e.g., Patient has type 2 diabetes (HbA1c 7.4 last quarter), is on metformin 500mg BID, allergic to penicillin, and is working toward losing 10 lb by end of year.',
              hintStyle: const TextStyle(color: Color(0x55FFFFFF), fontSize: 12.5, height: 1.5),
              filled: true,
              fillColor: const Color(0x0DFFFFFF),
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
            ),
          ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerRight,
            child: SizedBox(
              height: 42,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: kEmeraldGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextButton.icon(
                  onPressed: (_dirty && !_saving) ? _save : null,
                  icon: _saving
                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white))
                      : const Icon(Icons.save_outlined, color: Colors.white, size: 14),
                  label: Text(
                    _saving ? 'Saving…' : 'Save Context',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    disabledForegroundColor: Colors.white.withValues(alpha: 0.4),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Treatment Plan tab
// ─────────────────────────────────────────────────────────────────

enum _PlanMode { choose, manual, autoSelect, view }

class _TreatmentTab extends ConsumerStatefulWidget {
  final String patientName;
  final AsyncValue<List<ClinicalNote>> notesAsync;
  const _TreatmentTab({required this.patientName, required this.notesAsync});

  @override
  ConsumerState<_TreatmentTab> createState() => _TreatmentTabState();
}

class _TreatmentTabState extends ConsumerState<_TreatmentTab> {
  String _saved = '';
  _PlanMode _mode = _PlanMode.choose;
  final _draftCtrl = TextEditingController();
  bool _isSaving = false;
  bool _isGenerating = false;
  bool _loaded = false;
  final Set<String> _selectedNoteIds = {};

  @override
  void initState() {
    super.initState();
    PatientStorage.loadTreatmentPlan(widget.patientName).then((p) {
      if (mounted) {
        setState(() {
          _saved = p;
          _mode = p.isEmpty ? _PlanMode.choose : _PlanMode.view;
          _loaded = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _draftCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveManual() async {
    if (_draftCtrl.text.trim().isEmpty) {
      _toast('Treatment plan is empty.', AppColors.danger);
      return;
    }
    setState(() => _isSaving = true);
    await PatientStorage.saveTreatmentPlan(widget.patientName, _draftCtrl.text.trim());
    if (!mounted) return;
    setState(() {
      _saved = _draftCtrl.text.trim();
      _isSaving = false;
      _mode = _PlanMode.view;
    });
    _toast('Treatment plan saved', AppColors.emerald500);
  }

  Future<void> _generateFromNotes() async {
    if (_selectedNoteIds.isEmpty) {
      _toast('Select at least 1 note.', AppColors.danger);
      return;
    }
    setState(() => _isGenerating = true);
    try {
      final plan = await ref.read(audioApiProvider).generateTreatmentPlan(
            noteIds: _selectedNoteIds.toList(),
            patientName: widget.patientName,
          );
      await PatientStorage.saveTreatmentPlan(widget.patientName, plan);
      if (!mounted) return;
      setState(() {
        _saved = plan;
        _isGenerating = false;
        _mode = _PlanMode.view;
        _selectedNoteIds.clear();
      });
      _toast('Treatment plan generated', AppColors.emerald500);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isGenerating = false);
      _toast('Failed to generate treatment plan', AppColors.danger);
    }
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.slate800,
        title: const Text('Delete this treatment plan?', style: TextStyle(color: Colors.white)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await PatientStorage.saveTreatmentPlan(widget.patientName, '');
    if (!mounted) return;
    setState(() {
      _saved = '';
      _mode = _PlanMode.choose;
      _draftCtrl.clear();
      _selectedNoteIds.clear();
    });
    _toast('Treatment plan deleted', AppColors.emerald500);
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
    if (!_loaded) {
      return const _Card(
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: CircularProgressIndicator(color: AppColors.emerald400),
          ),
        ),
      );
    }

    final isView = _mode == _PlanMode.view;
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isView
                ? 'Treatment plan for ${widget.patientName}'
                : 'Create a treatment plan for ${widget.patientName}',
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
          ),
          if (!isView) ...[
            const SizedBox(height: 6),
            const Text(
              'Generate a treatment plan from previous notes or write it manually.',
              style: TextStyle(color: AppColors.slate400, fontSize: 12.5, height: 1.5),
            ),
            const Text(
              'Future notes for this patient will take this treatment plan into consideration.',
              style: TextStyle(color: AppColors.slate400, fontSize: 12.5, height: 1.5),
            ),
          ],
          const SizedBox(height: 18),
          _buildBody(),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (_mode) {
      case _PlanMode.choose:
        return _buildChoose();
      case _PlanMode.manual:
        return _buildManual();
      case _PlanMode.autoSelect:
        return _buildAutoSelect();
      case _PlanMode.view:
        return _buildView();
    }
  }

  Widget _buildChoose() {
    return Column(
      children: [
        _ChoiceCard(
          badgeColor: AppColors.info,
          badgeIcon: Icons.auto_awesome,
          badgeLabel: 'Automatic',
          title: 'Generate from notes',
          desc: 'Choose 1–3 notes associated with this patient to generate a treatment plan.',
          onTap: () {
            widget.notesAsync.whenData((notes) {
              if (notes.isEmpty) {
                _toast('No notes available for this patient yet.', AppColors.danger);
                return;
              }
              setState(() {
                _selectedNoteIds.clear();
                _mode = _PlanMode.autoSelect;
              });
            });
          },
        ),
        const SizedBox(height: 10),
        _ChoiceCard(
          badgeColor: AppColors.slate400,
          badgeIcon: Icons.edit_outlined,
          badgeLabel: 'Manual',
          title: 'Write your own',
          desc: 'Write your own treatment plan. You can paste an existing treatment plan.',
          onTap: () {
            _draftCtrl.text = '';
            setState(() => _mode = _PlanMode.manual);
          },
        ),
      ],
    );
  }

  Widget _buildManual() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _FieldLabel(text: 'Write treatment plan'),
        const SizedBox(height: 8),
        TextField(
          controller: _draftCtrl,
          maxLines: 12,
          minLines: 10,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontFamily: 'monospace',
            height: 1.5,
          ),
          decoration: InputDecoration(
            hintText:
                '1. Lifestyle: low-sodium diet, 30-min walk daily…\n2. Medication: continue lisinopril 10mg QD…\n3. Monitoring: home BP log twice weekly…\n4. Goals: HbA1c < 7.0; LDL < 100.',
            hintStyle: const TextStyle(color: Color(0x4DFFFFFF), fontFamily: 'monospace', fontSize: 12.5, height: 1.5),
            filled: true,
            fillColor: const Color(0x0DFFFFFF),
            contentPadding: const EdgeInsets.all(14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0x1FFFFFFF)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0x1FFFFFFF)),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: _isSaving
                  ? null
                  : () => setState(() => _mode = _saved.isEmpty ? _PlanMode.choose : _PlanMode.view),
              style: TextButton.styleFrom(foregroundColor: AppColors.slate400),
              child: const Text('Cancel'),
            ),
            const SizedBox(width: 8),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: kEmeraldGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextButton.icon(
                onPressed: _isSaving ? null : _saveManual,
                icon: _isSaving
                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white))
                    : const Icon(Icons.save_outlined, size: 14, color: Colors.white),
                label: Text(
                  _isSaving ? 'Saving…' : 'Save Plan',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAutoSelect() {
    return widget.notesAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator(color: AppColors.emerald400)),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (notes) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select 1–3 notes to base the plan on. Selected: ${_selectedNoteIds.length}/3',
            style: const TextStyle(color: AppColors.slate300, fontSize: 12.5),
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: const Color(0x05FFFFFF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0x14FFFFFF)),
            ),
            constraints: const BoxConstraints(maxHeight: 320),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: notes.length,
              separatorBuilder: (_, __) =>
                  Container(height: 1, color: const Color(0x0DFFFFFF)),
              itemBuilder: (_, i) {
                final n = notes[i];
                final checked = _selectedNoteIds.contains(n.id);
                return InkWell(
                  onTap: () {
                    setState(() {
                      if (checked) {
                        _selectedNoteIds.remove(n.id);
                      } else if (_selectedNoteIds.length < 3) {
                        _selectedNoteIds.add(n.id);
                      } else {
                        _toast('Choose up to 3 notes.', AppColors.danger);
                      }
                    });
                  },
                  child: Container(
                    color: checked ? AppColors.emerald500.withValues(alpha: 0.08) : null,
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Checkbox(
                          value: checked,
                          activeColor: AppColors.emerald500,
                          onChanged: (_) {
                            setState(() {
                              if (checked) {
                                _selectedNoteIds.remove(n.id);
                              } else if (_selectedNoteIds.length < 3) {
                                _selectedNoteIds.add(n.id);
                              }
                            });
                          },
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                n.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                DateFormat('MMM d, y, h:mm a').format(n.updatedAt),
                                style: const TextStyle(color: AppColors.slate400, fontSize: 11.5),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: _isGenerating ? null : () => setState(() => _mode = _PlanMode.choose),
                style: TextButton.styleFrom(foregroundColor: AppColors.slate400),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 8),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF6366F1)]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextButton.icon(
                  onPressed: (_isGenerating || _selectedNoteIds.isEmpty) ? null : _generateFromNotes,
                  icon: _isGenerating
                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white))
                      : const Icon(Icons.auto_awesome, size: 14, color: Colors.white),
                  label: Text(
                    _isGenerating ? 'Generating…' : 'Generate Plan',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Future notes for this patient will take this treatment plan into consideration.',
          style: TextStyle(color: AppColors.slate400, fontSize: 12.5, height: 1.5),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxHeight: 360),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0x08FFFFFF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0x14FFFFFF)),
          ),
          child: SingleChildScrollView(
            child: Text(
              _saved,
              style: const TextStyle(color: AppColors.slate200, fontSize: 13, height: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          alignment: WrapAlignment.end,
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: _delete,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.danger,
                side: BorderSide(color: AppColors.danger.withValues(alpha: 0.4)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
              ),
              icon: const Icon(Icons.delete_outline, size: 14),
              label: const Text('Delete', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
            OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  _selectedNoteIds.clear();
                  _mode = _PlanMode.autoSelect;
                });
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.info,
                side: BorderSide(color: AppColors.info.withValues(alpha: 0.4)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
              ),
              icon: const Icon(Icons.refresh, size: 14),
              label: const Text('Regenerate', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: kEmeraldGradient,
                borderRadius: BorderRadius.circular(11),
              ),
              child: TextButton.icon(
                onPressed: () {
                  _draftCtrl.text = _saved;
                  setState(() => _mode = _PlanMode.manual);
                },
                icon: const Icon(Icons.edit_outlined, size: 14, color: Colors.white),
                label: const Text(
                  'Edit',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13),
                ),
                style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8)),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  final Color badgeColor;
  final IconData badgeIcon;
  final String badgeLabel;
  final String title;
  final String desc;
  final VoidCallback onTap;

  const _ChoiceCard({
    required this.badgeColor,
    required this.badgeIcon,
    required this.badgeLabel,
    required this.title,
    required this.desc,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0x0AFFFFFF),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0x14FFFFFF)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(50),
                  border: Border.all(color: badgeColor.withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(badgeIcon, size: 11, color: badgeColor),
                    const SizedBox(width: 4),
                    Text(badgeLabel,
                        style: TextStyle(
                          color: badgeColor,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        )),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Text(title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  )),
              const SizedBox(height: 4),
              Text(desc,
                  style: const TextStyle(color: AppColors.slate400, fontSize: 12.5, height: 1.45)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Reports tab
// ─────────────────────────────────────────────────────────────────

class _ReportsTab extends ConsumerStatefulWidget {
  final String patientName;
  final AsyncValue<List<ClinicalNote>> notesAsync;
  const _ReportsTab({required this.patientName, required this.notesAsync});

  @override
  ConsumerState<_ReportsTab> createState() => _ReportsTabState();
}

class _ReportsTabState extends ConsumerState<_ReportsTab> {
  List<PatientReport> _reports = [];
  bool _loaded = false;
  bool _showForm = false;
  bool _generating = false;
  PatientReport? _viewing;

  final _diagnosisCtrl = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _diagnosisCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final list = await PatientStorage.loadReports(widget.patientName);
    if (mounted) {
      setState(() {
        _reports = list;
        _loaded = true;
      });
    }
  }

  void _openForm() {
    final now = DateTime.now();
    setState(() {
      _showForm = true;
      _diagnosisCtrl.text = '';
      _startDate = now.subtract(const Duration(days: 30));
      _endDate = now;
    });
  }

  Future<void> _generate(List<ClinicalNote> notes) async {
    if (_diagnosisCtrl.text.trim().isEmpty) {
      _toast('Diagnosis is required.', AppColors.danger);
      return;
    }
    if (_startDate == null || _endDate == null) {
      _toast('Pick a report period.', AppColors.danger);
      return;
    }
    if (_startDate!.isAfter(_endDate!)) {
      _toast('Start date must be before end date.', AppColors.danger);
      return;
    }

    final inRange = notes.where((n) {
      final d = n.updatedAt;
      return !d.isBefore(_startDate!) && !d.isAfter(_endDate!.add(const Duration(days: 1)));
    }).toList();

    if (inRange.isEmpty) {
      _toast('No notes for this patient in the selected period.', AppColors.danger);
      return;
    }

    setState(() => _generating = true);
    try {
      final content = await ref.read(audioApiProvider).generateReport(
            noteIds: inRange.map((n) => n.id).toList(),
            diagnosis: _diagnosisCtrl.text.trim(),
            patientName: widget.patientName,
            startDate: _startDate!.toIso8601String().split('T').first,
            endDate: _endDate!.toIso8601String().split('T').first,
          );
      final report = PatientReport(
        id: 'report-${DateTime.now().millisecondsSinceEpoch}',
        diagnosis: _diagnosisCtrl.text.trim(),
        startDate: _startDate!.toIso8601String().split('T').first,
        endDate: _endDate!.toIso8601String().split('T').first,
        createdAt: DateTime.now().toIso8601String(),
        content: content,
      );
      final next = [report, ..._reports];
      await PatientStorage.saveReports(widget.patientName, next);
      if (!mounted) return;
      setState(() {
        _reports = next;
        _showForm = false;
        _generating = false;
        _viewing = report;
      });
      _toast('Report generated', AppColors.emerald500);
    } catch (e) {
      if (!mounted) return;
      setState(() => _generating = false);
      _toast('Failed to generate report', AppColors.danger);
    }
  }

  Future<void> _delete(PatientReport r) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.slate800,
        title: const Text('Delete this report?', style: TextStyle(color: Colors.white)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final next = _reports.where((x) => x.id != r.id).toList();
    await PatientStorage.saveReports(widget.patientName, next);
    if (!mounted) return;
    setState(() {
      _reports = next;
      if (_viewing?.id == r.id) _viewing = null;
    });
    _toast('Report deleted', AppColors.emerald500);
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

  String _periodStr(String s, String e) {
    final ds = DateTime.tryParse(s);
    final de = DateTime.tryParse(e);
    if (ds == null || de == null) return '$s – $e';
    final fmt = DateFormat('MMM d, y');
    return '${fmt.format(ds)} – ${fmt.format(de)}';
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const _Card(
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: CircularProgressIndicator(color: AppColors.emerald400),
          ),
        ),
      );
    }

    final viewing = _viewing;
    if (viewing != null) return _buildViewing(viewing);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Reports',
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
              ),
            ),
            OutlinedButton.icon(
              onPressed: _openForm,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Color(0x1FFFFFFF)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
              ),
              icon: const Icon(Icons.add, size: 14),
              label: const Text('New Report', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (_showForm) ...[
          _buildForm(),
          const SizedBox(height: 14),
        ],
        if (_reports.isEmpty)
          const _Card(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 22),
              child: Center(
                child: Text('No results.', style: TextStyle(color: AppColors.slate500)),
              ),
            ),
          )
        else
          ..._reports.map(
            (r) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Material(
                color: const Color(0x0AFFFFFF),
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => setState(() => _viewing = r),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0x14FFFFFF)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(r.diagnosis,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                  )),
                              const SizedBox(height: 4),
                              Text(_periodStr(r.startDate, r.endDate),
                                  style: const TextStyle(color: AppColors.slate400, fontSize: 11.5)),
                              Text(
                                'Created ${DateFormat("MMM d, y, h:mm a").format(DateTime.parse(r.createdAt))}',
                                style: const TextStyle(color: AppColors.slate500, fontSize: 11.5),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Delete',
                          onPressed: () => _delete(r),
                          icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.slate500),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildViewing(PatientReport r) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextButton.icon(
            onPressed: () => setState(() => _viewing = null),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.slate400,
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            icon: const Icon(Icons.arrow_back, size: 14),
            label: const Text('Back to Reports', style: TextStyle(fontSize: 12.5)),
          ),
          const SizedBox(height: 10),
          Text(
            r.diagnosis,
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            '${_periodStr(r.startDate, r.endDate)} · created ${DateFormat("MMM d, y, h:mm a").format(DateTime.parse(r.createdAt))}',
            style: const TextStyle(color: AppColors.slate400, fontSize: 11.5),
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxHeight: 460),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0x08FFFFFF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0x14FFFFFF)),
            ),
            child: SingleChildScrollView(
              child: Text(r.content,
                  style: const TextStyle(color: AppColors.slate200, fontSize: 13, height: 1.5)),
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              onPressed: () => _delete(r),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.danger,
                side: BorderSide(color: AppColors.danger.withValues(alpha: 0.4)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
              ),
              icon: const Icon(Icons.delete_outline, size: 14),
              label: const Text('Delete Report', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text('New Report',
                    style: TextStyle(color: Colors.white, fontSize: 14.5, fontWeight: FontWeight.w800)),
              ),
              IconButton(
                onPressed: () => setState(() => _showForm = false),
                icon: const Icon(Icons.close, color: AppColors.slate400, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const _FieldLabel(text: 'Diagnosis'),
          const SizedBox(height: 6),
          _StyledField(
            controller: _diagnosisCtrl,
            hint: 'e.g., Hypertension, Type 2 Diabetes',
            onChanged: (_) {},
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _DateField(label: 'Period start', value: _startDate, onPicked: (d) => setState(() => _startDate = d))),
              const SizedBox(width: 10),
              Expanded(child: _DateField(label: 'Period end', value: _endDate, onPicked: (d) => setState(() => _endDate = d))),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: _generating ? null : () => setState(() => _showForm = false),
                style: TextButton.styleFrom(foregroundColor: AppColors.slate400),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 8),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: kEmeraldGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextButton.icon(
                  onPressed: _generating
                      ? null
                      : () => widget.notesAsync.whenData((notes) => _generate(notes)),
                  icon: _generating
                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white))
                      : const Icon(Icons.auto_awesome, size: 14, color: Colors.white),
                  label: Text(
                    _generating ? 'Generating…' : 'Generate Report',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final ValueChanged<DateTime> onPicked;

  const _DateField({required this.label, required this.value, required this.onPicked});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(text: label),
        const SizedBox(height: 6),
        Material(
          color: const Color(0x0DFFFFFF),
          borderRadius: BorderRadius.circular(11),
          child: InkWell(
            borderRadius: BorderRadius.circular(11),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: value ?? DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime.now(),
              );
              if (picked != null) onPicked(picked);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(11),
                border: Border.all(color: const Color(0x1FFFFFFF)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, size: 13, color: AppColors.slate500),
                  const SizedBox(width: 8),
                  Text(
                    value != null ? DateFormat('MMM d, y').format(value!) : 'Pick date',
                    style: TextStyle(
                      color: value != null ? Colors.white : AppColors.slate500,
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Shared sub-widgets
// ─────────────────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0x0AFFFFFF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0x14FFFFFF)),
      ),
      child: child,
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  final IconData? icon;
  const _FieldLabel({required this.text, this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 12, color: AppColors.slate400),
          const SizedBox(width: 5),
        ],
        Text(
          text,
          style: const TextStyle(
            color: AppColors.slate300,
            fontSize: 11.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.4,
          ),
        ),
      ],
    );
  }
}

class _StyledField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final bool readOnly;
  final VoidCallback? onTap;
  final Widget? prefixIcon;

  const _StyledField({
    required this.controller,
    required this.hint,
    this.keyboardType,
    this.onChanged,
    this.readOnly = false,
    this.onTap,
    this.prefixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      onChanged: onChanged,
      readOnly: readOnly,
      onTap: onTap,
      style: const TextStyle(color: Colors.white, fontSize: 13.5),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.slate500, fontSize: 13),
        prefixIcon: prefixIcon,
        filled: true,
        fillColor: const Color(0x0DFFFFFF),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: const BorderSide(color: Color(0x1FFFFFFF)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: const BorderSide(color: Color(0x1FFFFFFF)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: BorderSide(color: AppColors.emerald400.withValues(alpha: 0.5), width: 1.5),
        ),
      ),
    );
  }
}
