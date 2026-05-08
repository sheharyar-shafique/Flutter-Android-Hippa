import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/api/notes_api.dart';
import '../../core/api/patients_api.dart';
import '../../core/models/note.dart';
import '../../core/models/patient.dart';
import '../../core/theme/app_theme.dart';

final _patientProvider = FutureProvider.family.autoDispose<Patient, String>((ref, id) async {
  return ref.watch(patientsApiProvider).get(id);
});

final _patientNotesProvider = FutureProvider.family.autoDispose<List<ClinicalNote>, String>((ref, patientId) async {
  final page = await ref.watch(notesApiProvider).list(search: patientId);
  return page.notes
      .where((n) => n.patientName != null && n.patientName!.isNotEmpty)
      .toList();
});

class PatientDetailScreen extends ConsumerWidget {
  final String patientId;
  const PatientDetailScreen({super.key, required this.patientId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final patientAsync = ref.watch(_patientProvider(patientId));

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        title: const Text('Patient'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/patients'),
        ),
      ),
      body: SafeArea(
        child: patientAsync.when(
          loading: () => const Center(child: CircularProgressIndicator(color: AppColors.emerald400)),
          error: (e, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, color: AppColors.danger, size: 48),
                  const SizedBox(height: 12),
                  Text('Could not load patient:\n$e',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white)),
                ],
              ),
            ),
          ),
          data: (patient) => _PatientView(patient: patient),
        ),
      ),
    );
  }
}

class _PatientView extends ConsumerWidget {
  final Patient patient;
  const _PatientView({required this.patient});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notesAsync = ref.watch(_patientNotesProvider(patient.name));

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        _Header(patient: patient),
        const SizedBox(height: 20),
        _DemographicsCard(patient: patient),
        if (patient.allergies.isNotEmpty) ...[
          const SizedBox(height: 12),
          _ChipsCard(
            title: 'Allergies',
            icon: Icons.warning_amber_outlined,
            color: AppColors.danger,
            items: patient.allergies,
          ),
        ],
        if (patient.conditions.isNotEmpty) ...[
          const SizedBox(height: 12),
          _ChipsCard(
            title: 'Active conditions',
            icon: Icons.medical_information_outlined,
            color: AppColors.info,
            items: patient.conditions,
          ),
        ],
        const SizedBox(height: 24),
        const Text(
          'Visit notes',
          style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        notesAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator(color: AppColors.emerald400)),
          ),
          error: (e, _) => Text('Could not load notes: $e', style: const TextStyle(color: AppColors.danger)),
          data: (notes) => notes.isEmpty
              ? Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.description_outlined, color: AppColors.slate400, size: 32),
                      SizedBox(height: 8),
                      Text('No visits recorded yet for this patient.',
                          style: TextStyle(color: AppColors.slate400, fontSize: 13),
                          textAlign: TextAlign.center),
                    ],
                  ),
                )
              : Column(
                  children: notes.map((n) => _PatientNoteRow(note: n)).toList(),
                ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 52,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: kEmeraldGradient,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => context.go('/capture'),
                child: const Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.mic, color: Colors.white),
                      SizedBox(width: 8),
                      Text('Record a new visit',
                          style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
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
}

class _Header extends StatelessWidget {
  final Patient patient;
  const _Header({required this.patient});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            gradient: kEmeraldGradient,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Center(
            child: Text(
              patient.initials,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 22),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                patient.name,
                style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 6,
                children: [
                  if (patient.age != null)
                    _InfoBadge(label: '${patient.age} yrs', color: AppColors.info),
                  if (patient.gender != null)
                    _InfoBadge(label: patient.gender!, color: AppColors.emerald400),
                  if (patient.medicalRecordNumber != null)
                    _InfoBadge(label: 'MRN ${patient.medicalRecordNumber}', color: AppColors.warning),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _InfoBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 11.5, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _DemographicsCard extends StatelessWidget {
  final Patient patient;
  const _DemographicsCard({required this.patient});

  @override
  Widget build(BuildContext context) {
    final dob = patient.dateOfBirth;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.info_outline, size: 14, color: AppColors.slate400),
              SizedBox(width: 6),
              Text('Demographics',
                  style: TextStyle(color: AppColors.slate400, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
            ],
          ),
          const SizedBox(height: 8),
          if (dob != null)
            Row(
              children: [
                const Icon(Icons.cake_outlined, size: 14, color: AppColors.slate500),
                const SizedBox(width: 6),
                Text(
                  'Born ${DateFormat.yMMMd().format(dob)}',
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
              ],
            ),
          if (patient.notesCount > 0) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.description_outlined, size: 14, color: AppColors.slate500),
                const SizedBox(width: 6),
                Text(
                  '${patient.notesCount} note${patient.notesCount == 1 ? '' : 's'}',
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
              ],
            ),
          ],
          if (patient.lastVisit != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.event_outlined, size: 14, color: AppColors.slate500),
                const SizedBox(width: 6),
                Text(
                  'Last visit ${DateFormat.yMMMd().format(patient.lastVisit!)}',
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ChipsCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final List<String> items;

  const _ChipsCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
              Text(title.toUpperCase(),
                  style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: items
                .map((i) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(i, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _PatientNoteRow extends StatelessWidget {
  final ClinicalNote note;
  const _PatientNoteRow({required this.note});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: () => context.go('/notes/${note.id}'),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.cardBorder),
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
                  child: const Icon(Icons.description_outlined, size: 17, color: AppColors.emerald400),
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
                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        DateFormat('MMM d, h:mm a').format(note.updatedAt.toLocal()),
                        style: const TextStyle(color: AppColors.slate400, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.slate400, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
