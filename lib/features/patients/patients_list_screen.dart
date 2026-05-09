import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/models/patient.dart';
import '../../core/theme/app_theme.dart';
import 'patients_controller.dart';

// Pink/magenta gradient used for the header icon and buttons
const _kPinkGradient = LinearGradient(
  colors: [Color(0xFFE879F9), Color(0xFFEC4899)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

class PatientsListScreen extends ConsumerStatefulWidget {
  const PatientsListScreen({super.key});

  @override
  ConsumerState<PatientsListScreen> createState() => _PatientsListScreenState();
}

class _PatientsListScreenState extends ConsumerState<PatientsListScreen> {
  final _searchCtrl = TextEditingController();
  final Set<String> _selected = {};
  bool _sortAsc = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── New Patient dialog (matches web modal) ──
  Future<void> _showNewPatient() async {
    final nameCtrl = TextEditingController();

    final created = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) => Dialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0x1AFFFFFF)),
        ),
        insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('New Patient',
                      style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                  GestureDetector(
                    onTap: () => Navigator.pop(ctx, false),
                    child: const Icon(Icons.close, color: AppColors.slate400, size: 20),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text('You can flesh out the profile after creating.',
                  style: TextStyle(color: AppColors.slate400, fontSize: 13)),
              const SizedBox(height: 24),

              // Label
              const Text('PATIENT NAME',
                  style: TextStyle(color: AppColors.slate300, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
              const SizedBox(height: 8),
              TextField(
                controller: nameCtrl,
                autofocus: true,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'e.g., Alex Johnson',
                  hintStyle: const TextStyle(color: AppColors.slate500),
                  filled: true,
                  fillColor: const Color(0x0DFFFFFF),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: const Color(0xFFE879F9).withValues(alpha: 0.5)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: const Color(0xFFE879F9).withValues(alpha: 0.4)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE879F9), width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Buttons row
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.slate400,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    child: const Text('Cancel', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () {
                      if (nameCtrl.text.trim().isNotEmpty) Navigator.pop(ctx, true);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                      decoration: BoxDecoration(
                        gradient: _kPinkGradient,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add, color: Colors.white, size: 16),
                          SizedBox(width: 6),
                          Text('Create',
                              style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (created == true && nameCtrl.text.trim().isNotEmpty) {
      final ok = await ref.read(patientsControllerProvider.notifier).create(
            name: nameCtrl.text.trim(),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: ok ? AppColors.emerald500 : AppColors.danger,
          content: Text(
            ok ? 'Patient added.' : (ref.read(patientsControllerProvider).error ?? 'Could not add patient.'),
            style: const TextStyle(color: Colors.white),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _deleteSelected() async {
    if (_selected.isEmpty) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.slate800,
        title: const Text('Delete patients?', style: TextStyle(color: Colors.white)),
        content: Text('Delete ${_selected.length} patient(s)? This cannot be undone.',
            style: const TextStyle(color: AppColors.slate400)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    for (final id in _selected.toList()) {
      await ref.read(patientsControllerProvider.notifier).delete(id);
    }
    setState(() => _selected.clear());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(patientsControllerProvider);
    final controller = ref.read(patientsControllerProvider.notifier);
    final patients = state.patients;

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () => context.canPop() ? context.pop() : context.go('/dashboard'),
                    child: Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0x0DFFFFFF),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0x1AFFFFFF)),
                      ),
                      child: const Icon(Icons.arrow_back, color: Colors.white, size: 18),
                    ),
                  ),
                  const SizedBox(width: 14),
                  // Icon + Title
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      gradient: _kPinkGradient,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.people_alt_outlined, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text('Patients',
                                style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0x1AFFFFFF),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: const Color(0x1AFFFFFF)),
                              ),
                              child: Text('${patients.length} total',
                                  style: const TextStyle(color: AppColors.slate300, fontSize: 11, fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        const Text('Everyone who has been documented in your account.',
                            style: TextStyle(color: AppColors.slate400, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Search + New Patient + Delete ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  // Search
                  Expanded(
                    child: Container(
                      height: 42,
                      decoration: BoxDecoration(
                        color: const Color(0x0DFFFFFF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0x1AFFFFFF)),
                      ),
                      child: TextField(
                        controller: _searchCtrl,
                        onSubmitted: controller.setSearch,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        decoration: const InputDecoration(
                          hintText: 'Search Patient',
                          hintStyle: TextStyle(color: AppColors.slate500, fontSize: 13),
                          prefixIcon: Icon(Icons.search, color: AppColors.slate500, size: 18),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // + New Patient button (pink gradient)
                  GestureDetector(
                    onTap: _showNewPatient,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: _kPinkGradient,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add, color: Colors.white, size: 15),
                          SizedBox(width: 4),
                          Text('New Patient',
                              style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ),
                  // Delete button
                  if (_selected.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _deleteSelected,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0x0DFFFFFF),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0x1AFFFFFF)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.delete_outline, color: AppColors.slate400, size: 15),
                            const SizedBox(width: 4),
                            Text('Delete (${_selected.length})',
                                style: const TextStyle(color: AppColors.slate400, fontSize: 12, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),

            // ── Table header ──
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: Color(0x14FFFFFF)),
                  bottom: BorderSide(color: Color(0x14FFFFFF)),
                ),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 24,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          if (_selected.length == patients.length) {
                            _selected.clear();
                          } else {
                            _selected.addAll(patients.map((p) => p.id));
                          }
                        });
                      },
                      child: Icon(
                        _selected.length == patients.length && patients.isNotEmpty
                            ? Icons.check_box
                            : Icons.check_box_outline_blank,
                        color: AppColors.slate500, size: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    flex: 4,
                    child: Text('Patient',
                        style: TextStyle(color: AppColors.slate400, fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                  const Expanded(
                    flex: 2,
                    child: Text('Number of notes',
                        style: TextStyle(color: AppColors.slate400, fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                  Expanded(
                    flex: 3,
                    child: GestureDetector(
                      onTap: () => setState(() => _sortAsc = !_sortAsc),
                      child: Row(
                        children: [
                          Icon(_sortAsc ? Icons.arrow_upward : Icons.arrow_downward,
                              color: AppColors.slate400, size: 12),
                          const SizedBox(width: 4),
                          const Text('Last note',
                              style: TextStyle(color: AppColors.slate400, fontSize: 12, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── List ──
            Expanded(child: _buildBody(state, controller, patients)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(PatientsState state, PatientsController controller, List<Patient> patients) {
    if (state.loading && patients.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: AppColors.emerald400));
    }
    if (state.error != null && patients.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off, color: AppColors.danger, size: 48),
              const SizedBox(height: 12),
              Text(state.error!, textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 14)),
              const SizedBox(height: 16),
              ElevatedButton.icon(onPressed: controller.refresh, icon: const Icon(Icons.refresh), label: const Text('Retry')),
            ],
          ),
        ),
      );
    }
    if (patients.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  gradient: _kPinkGradient.scale(0.2),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(Icons.people_alt_outlined, color: Color(0xFFE879F9), size: 40),
              ),
              const SizedBox(height: 16),
              const Text('No patients yet',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              const Text('Tap "+ New Patient" to add your first patient.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.slate400, fontSize: 13)),
            ],
          ),
        ),
      );
    }

    // Sort by last visit
    final sorted = patients.toList()
      ..sort((a, b) {
        final aDate = a.lastVisit ?? a.createdAt;
        final bDate = b.lastVisit ?? b.createdAt;
        return _sortAsc ? aDate.compareTo(bDate) : bDate.compareTo(aDate);
      });

    return RefreshIndicator(
      color: AppColors.emerald400,
      backgroundColor: AppColors.slate800,
      onRefresh: controller.refresh,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
        itemCount: sorted.length,
        itemBuilder: (_, i) => _PatientRow(
          patient: sorted[i],
          isSelected: _selected.contains(sorted[i].id),
          onCheck: (v) {
            setState(() {
              if (v) {
                _selected.add(sorted[i].id);
              } else {
                _selected.remove(sorted[i].id);
              }
            });
          },
          onTap: () => context.push('/patients/${sorted[i].id}'),
        ),
      ),
    );
  }
}

/// Each patient row — matches the web's table layout.
class _PatientRow extends StatelessWidget {
  final Patient patient;
  final bool isSelected;
  final ValueChanged<bool> onCheck;
  final VoidCallback onTap;
  const _PatientRow({required this.patient, required this.isSelected, required this.onCheck, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final lastNote = patient.lastVisit != null
        ? DateFormat('MMM d, yyyy, h:mm a').format(patient.lastVisit!.toLocal())
        : '—';

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0x0FFFFFFF))),
        ),
        child: Row(
          children: [
            // Checkbox
            SizedBox(
              width: 24,
              child: GestureDetector(
                onTap: () => onCheck(!isSelected),
                child: Icon(
                  isSelected ? Icons.check_box : Icons.check_box_outline_blank,
                  color: isSelected ? const Color(0xFFE879F9) : AppColors.slate500,
                  size: 18,
                ),
              ),
            ),
            const SizedBox(width: 14),
            // Patient name
            Expanded(
              flex: 4,
              child: Text(
                patient.name,
                maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700),
              ),
            ),
            // Note count
            Expanded(
              flex: 2,
              child: Text(
                '${patient.notesCount}',
                style: const TextStyle(color: AppColors.slate300, fontSize: 14),
              ),
            ),
            // Last note date
            Expanded(
              flex: 3,
              child: Text(
                lastNote,
                maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.slate400, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
