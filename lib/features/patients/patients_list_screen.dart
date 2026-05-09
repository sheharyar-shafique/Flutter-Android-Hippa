import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/models/patient.dart';
import '../../core/theme/app_theme.dart';
import 'patients_controller.dart';

class PatientsListScreen extends ConsumerStatefulWidget {
  const PatientsListScreen({super.key});

  @override
  ConsumerState<PatientsListScreen> createState() => _PatientsListScreenState();
}

class _PatientsListScreenState extends ConsumerState<PatientsListScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _showAddPatient() async {
    final nameCtrl = TextEditingController();
    final mrnCtrl = TextEditingController();
    DateTime? dob;
    String? gender;

    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.slate800,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.person_add_alt, color: AppColors.emerald400),
                  const SizedBox(width: 10),
                  const Text('Add patient', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                  const Spacer(),
                  IconButton(icon: const Icon(Icons.close, color: AppColors.slate400), onPressed: () => Navigator.pop(ctx, false)),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: nameCtrl,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Full name',
                  prefixIcon: Icon(Icons.person_outline, color: AppColors.slate400),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: mrnCtrl,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Medical record # (optional)',
                  prefixIcon: Icon(Icons.tag, color: AppColors.slate400),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.calendar_today, size: 16),
                      label: Text(dob == null ? 'Date of birth' : DateFormat.yMMMd().format(dob!)),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: ctx,
                          initialDate: dob ?? DateTime(2000),
                          firstDate: DateTime(1900),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) setSt(() => dob = picked);
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: gender,
                      dropdownColor: AppColors.slate800,
                      decoration: const InputDecoration(labelText: 'Gender'),
                      items: const [
                        DropdownMenuItem(value: 'female', child: Text('Female')),
                        DropdownMenuItem(value: 'male', child: Text('Male')),
                        DropdownMenuItem(value: 'other', child: Text('Other')),
                      ],
                      onChanged: (v) => setSt(() => gender = v),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 50,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.check),
                  label: const Text('Add patient'),
                  onPressed: () => Navigator.pop(ctx, true),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (ok == true && nameCtrl.text.trim().isNotEmpty) {
      final created = await ref.read(patientsControllerProvider.notifier).create(
            name: nameCtrl.text.trim(),
            medicalRecordNumber: mrnCtrl.text.trim().isEmpty ? null : mrnCtrl.text.trim(),
            dateOfBirth: dob,
            gender: gender,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: created ? AppColors.emerald500 : AppColors.danger,
          content: Text(
            created ? 'Patient added.' : (ref.read(patientsControllerProvider).error ?? 'Could not add patient.'),
            style: const TextStyle(color: Colors.white),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(patientsControllerProvider);
    final controller = ref.read(patientsControllerProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        title: const Text('Patients'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop() ? context.pop() : context.go('/dashboard'),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.emerald500,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_alt),
        label: const Text('Add patient', style: TextStyle(fontWeight: FontWeight.w700)),
        onPressed: _showAddPatient,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: TextField(
                controller: _searchCtrl,
                onSubmitted: controller.setSearch,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Search patients…',
                  prefixIcon: const Icon(Icons.search, color: AppColors.slate400),
                  suffixIcon: _searchCtrl.text.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.clear, color: AppColors.slate400),
                          onPressed: () {
                            _searchCtrl.clear();
                            controller.setSearch('');
                          },
                        ),
                ),
              ),
            ),
            Expanded(child: _buildBody(state, controller)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(PatientsState state, PatientsController controller) {
    if (state.loading && state.patients.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: AppColors.emerald400));
    }

    if (state.error != null && state.patients.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off, color: AppColors.danger, size: 48),
              const SizedBox(height: 12),
              Text(state.error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white)),
              const SizedBox(height: 16),
              ElevatedButton.icon(onPressed: controller.refresh, icon: const Icon(Icons.refresh), label: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    if (state.patients.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.emerald500.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(Icons.people_outline, color: AppColors.emerald400, size: 40),
              ),
              const SizedBox(height: 16),
              const Text('No patients yet', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              const Text(
                'Add your first patient to start tracking longitudinal context.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.slate400, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.emerald400,
      backgroundColor: AppColors.slate800,
      onRefresh: controller.refresh,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
        itemCount: state.patients.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) => _PatientCard(
          patient: state.patients[i],
          onTap: () => context.push('/patients/${state.patients[i].id}'),
        ),
      ),
    );
  }
}

class _PatientCard extends StatelessWidget {
  final Patient patient;
  final VoidCallback onTap;

  const _PatientCard({required this.patient, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final age = patient.age;
    return Material(
      color: AppColors.cardBg,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: kEmeraldGradient,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    patient.initials,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16),
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
                      style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (age != null) ...[
                          Text('$age yrs', style: const TextStyle(color: AppColors.slate400, fontSize: 12)),
                          if (patient.gender != null) ...[
                            const SizedBox(width: 6),
                            Container(width: 3, height: 3, decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.slate500)),
                            const SizedBox(width: 6),
                            Text(patient.gender!, style: const TextStyle(color: AppColors.slate400, fontSize: 12)),
                          ],
                        ],
                        if (patient.medicalRecordNumber != null) ...[
                          if (age != null || patient.gender != null) ...[
                            const SizedBox(width: 6),
                            Container(width: 3, height: 3, decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.slate500)),
                            const SizedBox(width: 6),
                          ],
                          Flexible(
                            child: Text(
                              'MRN ${patient.medicalRecordNumber}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: AppColors.slate400, fontSize: 12),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.emerald500.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${patient.notesCount}',
                  style: const TextStyle(color: AppColors.emerald400, fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
