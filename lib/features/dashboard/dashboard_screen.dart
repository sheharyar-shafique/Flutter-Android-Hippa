import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/models/dashboard_stats.dart';
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
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _WelcomeHeader(name: user?.name ?? 'Doctor'),
                const SizedBox(height: 24),
                _StatsGrid(stats: data.stats, loading: data.loading),
                const SizedBox(height: 28),
                if (data.appointments.isNotEmpty) ...[
                  const _SectionHeader(title: "Today's appointments"),
                  const SizedBox(height: 12),
                  ...data.appointments.take(3).map((a) => _AppointmentCard(appointment: a)),
                  const SizedBox(height: 20),
                ],
                const _SectionHeader(title: 'Quick Actions', sub: 'Launch any workflow instantly'),
                const SizedBox(height: 16),
                const _QuickActionsGrid(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

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
                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800),
                  children: [
                    const TextSpan(text: 'Welcome back, '),
                    TextSpan(text: firstName, style: const TextStyle(color: AppColors.emerald400)),
                    const TextSpan(text: '! '),
                    const TextSpan(text: '👋', style: TextStyle(fontSize: 20)),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                "Here's your clinical documentation overview for today.",
                style: TextStyle(color: AppColors.slate400, fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatsGrid extends StatelessWidget {
  final DashboardStats stats;
  final bool loading;
  const _StatsGrid({required this.stats, required this.loading});

  String _formatAvgTime(double seconds) {
    if (seconds <= 0) return '—';
    if (seconds < 60) return '${seconds.toStringAsFixed(0)}s';
    final m = seconds ~/ 60;
    final s = (seconds - m * 60).toInt();
    return s == 0 ? '${m}m' : '${m}m ${s}s';
  }

  String _value(num n) => loading ? '—' : n.toString();

  @override
  Widget build(BuildContext context) {
    final tiles = [
      _StatTile(
        value: _value(stats.totalNotes),
        label: 'TOTAL NOTES',
        trend: stats.notesTrendPct,
        icon: Icons.description_outlined,
        color: AppColors.emerald400,
      ),
      _StatTile(
        value: _value(stats.notesThisWeek),
        label: 'THIS WEEK',
        trend: stats.weekTrendPct,
        icon: Icons.calendar_today_outlined,
        color: AppColors.info,
      ),
      _StatTile(
        value: loading ? '—' : _formatAvgTime(stats.avgNoteSeconds),
        label: 'AVG. TIME',
        trend: stats.timeTrendPct,
        icon: Icons.access_time,
        color: const Color(0xFFA78BFA),
      ),
      _StatTile(
        value: loading || stats.accuracyPct <= 0 ? '—' : '${stats.accuracyPct.toStringAsFixed(1)}%',
        label: 'ACCURACY',
        trend: stats.accuracyTrendPct,
        icon: Icons.trending_up,
        color: AppColors.warning,
      ),
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.2,
      children: tiles,
    );
  }
}

class _StatTile extends StatelessWidget {
  final String value;
  final String label;
  final double trend;
  final IconData icon;
  final Color color;
  const _StatTile({
    required this.value,
    required this.label,
    required this.trend,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final showTrend = trend != 0;
    final isUp = trend >= 0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(20),
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
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              if (showTrend)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: (isUp ? AppColors.emerald400 : AppColors.danger).withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isUp ? Icons.trending_up : Icons.trending_down,
                        size: 11,
                        color: isUp ? AppColors.emerald400 : AppColors.danger,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${trend.abs().toStringAsFixed(0)}%',
                        style: TextStyle(
                          color: isUp ? AppColors.emerald400 : AppColors.danger,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: const TextStyle(color: AppColors.slate400, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.5),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? sub;
  const _SectionHeader({required this.title, this.sub});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
        if (sub != null) ...[
          const SizedBox(height: 4),
          Text(sub!, style: const TextStyle(color: AppColors.slate400, fontSize: 13)),
        ],
      ],
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  final Appointment appointment;
  const _AppointmentCard({required this.appointment});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.event, color: AppColors.info),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    appointment.patientName,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    DateFormat('h:mm a').format(appointment.startsAt.toLocal()) +
                        (appointment.durationMinutes != null ? ' · ${appointment.durationMinutes} min' : ''),
                    style: const TextStyle(color: AppColors.slate400, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.slate400),
          ],
        ),
      ),
    );
  }
}

class _QuickActionsGrid extends StatelessWidget {
  const _QuickActionsGrid();

  @override
  Widget build(BuildContext context) {
    final actions = [
      const _ActionTile(icon: Icons.mic, label: 'Capture', sub: 'Record visit', color: AppColors.emerald500, route: '/capture'),
      const _ActionTile(icon: Icons.chat_bubble_outline, label: 'Dictation', sub: 'Live speech-to-text', color: Color(0xFFA78BFA), route: '/dictation'),
      const _ActionTile(icon: Icons.upload_outlined, label: 'Upload', sub: 'Upload audio', color: AppColors.info, route: '/upload'),
      const _ActionTile(icon: Icons.description_outlined, label: 'Notes', sub: 'Browse all', color: Color(0xFFFB7185), route: '/notes'),
      const _ActionTile(icon: Icons.people_outline, label: 'Patients', sub: 'Manage list', color: Color(0xFF60A5FA), route: '/patients'),
      const _ActionTile(icon: Icons.layers_outlined, label: 'Templates', sub: 'Customize notes', color: Color(0xFF22D3EE), route: '/templates'),
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.05,
      children: actions,
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sub;
  final Color color;
  final String? route;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.sub,
    required this.color,
    required this.route,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = route != null;
    return Material(
      color: AppColors.cardBg,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: enabled ? () => context.go(route!) : null,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Opacity(
            opacity: enabled ? 1 : 0.55,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: color, size: 26),
                ),
                const SizedBox(height: 12),
                Text(
                  label,
                  style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  sub,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.slate400, fontSize: 11),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
