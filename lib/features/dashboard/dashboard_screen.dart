import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/models/dashboard_stats.dart';
import '../../core/models/note.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/app_drawer.dart';
import '../auth/auth_controller.dart';
import 'dashboard_controller.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;
    final data = ref.watch(dashboardControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      drawer: const AppDrawer(),
      appBar: AppBar(
        backgroundColor: AppColors.slate900.withValues(alpha: 0.95),
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: kEmeraldGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.auto_awesome, size: 16, color: Colors.white),
            ),
            const SizedBox(width: 10),
            const Text('Pronote', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh, color: Colors.white70),
            onPressed: () => ref.read(dashboardControllerProvider.notifier).refresh(),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.emerald400,
          backgroundColor: AppColors.slate800,
          onRefresh: () => ref.read(dashboardControllerProvider.notifier).refresh(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Welcome header + New Note ──
                _WelcomeHeader(name: user?.name ?? 'Doctor'),
                const SizedBox(height: 20),

                // ── Stats grid (2×2) ──
                _StatsGrid(stats: data.stats, loading: data.loading),
                const SizedBox(height: 24),

                // ── Quick Actions ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Quick Actions',
                        style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
                    Text('Launch any workflow instantly',
                        style: TextStyle(color: AppColors.slate500, fontSize: 11)),
                  ],
                ),
                const SizedBox(height: 12),
                const _QuickActionsRow(),
                const SizedBox(height: 24),

                // ── Recent Clinical Notes ──
                Row(
                  children: [
                    const Expanded(
                      child: Text('Recent Clinical Notes',
                          style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
                    ),
                    TextButton(
                      onPressed: () => context.push('/notes'),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('View All', style: TextStyle(color: AppColors.emerald400, fontSize: 13, fontWeight: FontWeight.w700)),
                          SizedBox(width: 2),
                          Icon(Icons.chevron_right, size: 16, color: AppColors.emerald400),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _RecentNotesTable(notes: data.recentNotes, loading: data.loading),
                const SizedBox(height: 24),

                // ── Upcoming Today ──
                Row(
                  children: [
                    const Expanded(
                      child: Text('Upcoming Today',
                          style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.emerald400.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(50),
                        border: Border.all(color: AppColors.emerald400.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        '${data.appointments.length} scheduled',
                        style: const TextStyle(color: AppColors.emerald400, fontSize: 11, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _UpcomingCard(appointments: data.appointments),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Welcome Header ──────────────────────────────────────────────
class _WelcomeHeader extends StatelessWidget {
  final String name;
  const _WelcomeHeader({required this.name});

  @override
  Widget build(BuildContext context) {
    final firstName = name.split(' ').first;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            gradient: kEmeraldGradient,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: AppColors.emerald500.withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: TextSpan(
                  style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800),
                  children: [
                    const TextSpan(text: 'Welcome back, '),
                    TextSpan(text: firstName, style: const TextStyle(color: AppColors.emerald400)),
                    const TextSpan(text: '! '),
                    const TextSpan(text: '👋', style: TextStyle(fontSize: 18)),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                "Here's your clinical documentation overview for today.",
                style: TextStyle(color: AppColors.slate400, fontSize: 12.5),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        // + New Note button
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: kEmeraldGradient,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(color: AppColors.emerald500.withValues(alpha: 0.35), blurRadius: 14, offset: const Offset(0, 4)),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => context.push('/capture'),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add, size: 16, color: Colors.white),
                    SizedBox(width: 4),
                    Text('New Note', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Stats Grid ──────────────────────────────────────────────────
class _StatsGrid extends StatelessWidget {
  final DashboardStats stats;
  final bool loading;
  const _StatsGrid({required this.stats, required this.loading});

  String _fmtTime(double s) {
    if (s <= 0) return 'N/A';
    if (s < 60) return '${s.toStringAsFixed(0)} sec';
    final m = s ~/ 60;
    final r = (s - m * 60).toInt();
    return r == 0 ? '${m} min' : '${m}m ${r}s';
  }

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.55,
      children: [
        _StatCard(
          icon: Icons.description_outlined,
          color: AppColors.emerald400,
          value: loading ? '—' : '${stats.totalNotes}',
          label: 'TOTAL NOTES',
          trend: stats.notesTrendPct,
        ),
        _StatCard(
          icon: Icons.calendar_today_outlined,
          color: const Color(0xFF818CF8),
          value: loading ? '—' : '${stats.notesThisWeek}',
          label: 'THIS WEEK',
          trend: stats.weekTrendPct,
        ),
        _StatCard(
          icon: Icons.access_time,
          color: const Color(0xFFA78BFA),
          value: loading ? '—' : _fmtTime(stats.avgNoteSeconds),
          label: 'AVG. TIME',
          trend: stats.timeTrendPct,
        ),
        _StatCard(
          icon: Icons.trending_up,
          color: AppColors.warning,
          value: loading || stats.accuracyPct <= 0 ? '—' : '${stats.accuracyPct.toStringAsFixed(1)}%',
          label: 'ACCURACY',
          trend: stats.accuracyTrendPct,
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value;
  final String label;
  final double trend;

  const _StatCard({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
    required this.trend,
  });

  @override
  Widget build(BuildContext context) {
    final show = trend != 0;
    final up = trend >= 0;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 17),
              ),
              if (show)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: (up ? AppColors.emerald400 : AppColors.danger).withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(up ? Icons.trending_up : Icons.trending_down, size: 10,
                          color: up ? AppColors.emerald400 : AppColors.danger),
                      const SizedBox(width: 2),
                      Text('${up ? "+" : ""}${trend.toStringAsFixed(0)}%',
                          style: TextStyle(
                              color: up ? AppColors.emerald400 : AppColors.danger,
                              fontSize: 10, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800)),
              const SizedBox(height: 1),
              Text(label,
                  style: const TextStyle(color: AppColors.slate400, fontSize: 10.5, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Quick Actions Row (horizontal scroll) ───────────────────────
class _QuickActionsRow extends StatelessWidget {
  const _QuickActionsRow();

  @override
  Widget build(BuildContext context) {
    const actions = [
      _QA(Icons.mic, 'Capture', 'Record visit', Color(0xFF34D399), '/capture'),
      _QA(Icons.chat_bubble_outline, 'Dictation', 'Dictate notes', Color(0xFF818CF8), '/dictation'),
      _QA(Icons.upload_outlined, 'Upload', 'Upload audio', Color(0xFF60A5FA), '/upload'),
      _QA(Icons.description_outlined, 'Notes', 'Browse all', Color(0xFFFB7185), '/notes'),
      _QA(Icons.dashboard_customize_outlined, 'Templates', 'Manage templates', Color(0xFFF59E0B), '/templates'),
    ];

    return SizedBox(
      height: 110,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: actions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final a = actions[i];
          return SizedBox(
            width: 100,
            child: Material(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => context.push(a.route),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: a.color.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(a.icon, color: a.color, size: 20),
                      ),
                      const SizedBox(height: 8),
                      Text(a.label, style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 1),
                      Text(a.sub, style: const TextStyle(color: AppColors.slate500, fontSize: 10)),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _QA {
  final IconData icon;
  final String label;
  final String sub;
  final Color color;
  final String route;
  const _QA(this.icon, this.label, this.sub, this.color, this.route);
}

// ── Recent Clinical Notes Table ─────────────────────────────────
class _RecentNotesTable extends StatelessWidget {
  final List<ClinicalNote> notes;
  final bool loading;
  const _RecentNotesTable({required this.notes, required this.loading});

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 40),
        decoration: _tableDeco(),
        child: const Center(child: CircularProgressIndicator(color: AppColors.emerald400)),
      );
    }

    if (notes.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 40),
        decoration: _tableDeco(),
        child: const Center(
          child: Column(
            children: [
              Icon(Icons.description_outlined, color: AppColors.slate500, size: 32),
              SizedBox(height: 8),
              Text('No notes yet', style: TextStyle(color: AppColors.slate400, fontSize: 13)),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: _tableDeco(),
      child: Column(
        children: [
          // Header row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                _headerCell('PATIENT', flex: 3),
                _headerCell('DATE', flex: 3),
                _headerCell('TYPE', flex: 3),
                _headerCell('STATUS', flex: 2),
                const SizedBox(width: 32),
              ],
            ),
          ),
          Container(height: 1, color: const Color(0x10FFFFFF)),
          // Rows
          ...notes.map((n) => _NoteRow(note: n)),
        ],
      ),
    );
  }

  Widget _headerCell(String text, {required int flex}) {
    return Expanded(
      flex: flex,
      child: Text(text,
          style: const TextStyle(color: AppColors.slate500, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.8)),
    );
  }

  BoxDecoration _tableDeco() => BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      );
}

class _NoteRow extends StatelessWidget {
  final ClinicalNote note;
  const _NoteRow({required this.note});

  Color _statusColor(NoteStatus s) {
    switch (s) {
      case NoteStatus.draft:
        return AppColors.warning;
      case NoteStatus.completed:
        return AppColors.emerald400;
      case NoteStatus.signed:
        return const Color(0xFF60A5FA);
      case NoteStatus.processing:
        return const Color(0xFFA78BFA);
      case NoteStatus.ready:
        return const Color(0xFF34D399);
      default:
        return AppColors.slate400;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('MMM d, y').format(note.createdAt);
    final status = note.status;
    final patient = note.patientName ?? 'Unknown';
    final initial = patient.isNotEmpty ? patient[0].toUpperCase() : '?';
    final type = note.templateId ?? 'Note';

    return InkWell(
      onTap: () => context.push('/notes/${note.id}'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0x0AFFFFFF))),
        ),
        child: Row(
          children: [
            // Patient
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      gradient: kEmeraldGradient,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(initial,
                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(patient,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
            // Date
            Expanded(
              flex: 3,
              child: Text(dateStr,
                  style: const TextStyle(color: AppColors.slate400, fontSize: 12)),
            ),
            // Type
            Expanded(
              flex: 3,
              child: Text(type,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.slate400, fontSize: 12)),
            ),
            // Status badge
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _statusColor(status).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(50),
                      border: Border.all(color: _statusColor(status).withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                            color: _statusColor(status),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(status.name,
                            style: TextStyle(color: _statusColor(status), fontSize: 10, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Arrow
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: const Color(0x0DFFFFFF),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0x14FFFFFF)),
              ),
              child: const Icon(Icons.open_in_new, size: 12, color: AppColors.slate400),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Upcoming Today ──────────────────────────────────────────────
class _UpcomingCard extends StatelessWidget {
  final List<Appointment> appointments;
  const _UpcomingCard({required this.appointments});

  @override
  Widget build(BuildContext context) {
    if (appointments.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 36),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: const Center(
          child: Column(
            children: [
              Icon(Icons.calendar_today_outlined, color: AppColors.slate500, size: 34),
              SizedBox(height: 10),
              Text('No appointments today', style: TextStyle(color: AppColors.slate400, fontSize: 14)),
              SizedBox(height: 4),
              Text('Enjoy a lighter schedule!', style: TextStyle(color: AppColors.slate500, fontSize: 12)),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: appointments.map((a) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.info.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.event, color: AppColors.info, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(a.patientName,
                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text(
                        DateFormat('h:mm a').format(a.startsAt.toLocal()) +
                            (a.durationMinutes != null ? ' · ${a.durationMinutes} min' : ''),
                        style: const TextStyle(color: AppColors.slate400, fontSize: 11.5),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.slate500, size: 18),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
