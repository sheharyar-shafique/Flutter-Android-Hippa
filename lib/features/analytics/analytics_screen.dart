import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../dashboard/dashboard_controller.dart';

/// Lightweight analytics view — pulls the same /dashboard/stats payload the
/// home screen uses and lays it out as larger insight cards. When the
/// backend exposes a /dashboard/analytics?days=N endpoint we will swap to
/// it and render proper time-series charts.
class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(dashboardControllerProvider);
    final stats = data.stats;

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        title: const Text('Analytics'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/dashboard'),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(dashboardControllerProvider.notifier).refresh(),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            const Text(
              'Your impact',
              style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            const Text(
              'Practice efficiency since you joined Pronote.',
              style: TextStyle(color: AppColors.slate400, fontSize: 13),
            ),
            const SizedBox(height: 20),
            _BigInsight(
              label: 'TIME SAVED THIS WEEK',
              value: _formatHours(stats.notesThisWeek * stats.avgNoteSeconds),
              sub: '${stats.notesThisWeek} note${stats.notesThisWeek == 1 ? '' : 's'} this week, average ${_formatSeconds(stats.avgNoteSeconds)} each',
              color: AppColors.emerald400,
              icon: Icons.access_time,
            ),
            const SizedBox(height: 12),
            _BigInsight(
              label: 'NOTES GENERATED',
              value: stats.totalNotes.toString(),
              sub: 'lifetime since signup',
              color: AppColors.info,
              icon: Icons.description_outlined,
            ),
            const SizedBox(height: 12),
            _BigInsight(
              label: 'TRANSCRIPTION ACCURACY',
              value: stats.accuracyPct > 0 ? '${stats.accuracyPct.toStringAsFixed(1)}%' : '—',
              sub: 'on clinical vocabulary',
              color: AppColors.warning,
              icon: Icons.trending_up,
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  AppColors.emerald500.withValues(alpha: 0.14),
                  AppColors.teal500.withValues(alpha: 0.06),
                ]),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.emerald500.withValues(alpha: 0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.bar_chart, color: AppColors.emerald400, size: 22),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Time-series charts (notes per day, accuracy trend, average duration over time) ship in the next backend release.',
                      style: TextStyle(color: Colors.white, fontSize: 13, height: 1.5),
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

  static String _formatHours(double seconds) {
    if (seconds <= 0) return '—';
    final hours = seconds / 3600;
    if (hours < 1) {
      final mins = (seconds / 60).round();
      return '${mins}m';
    }
    return '${hours.toStringAsFixed(1)}h';
  }

  static String _formatSeconds(double seconds) {
    if (seconds <= 0) return '—';
    if (seconds < 60) return '${seconds.toStringAsFixed(0)}s';
    final m = seconds ~/ 60;
    final s = (seconds - m * 60).toInt();
    return s == 0 ? '${m}m' : '${m}m ${s}s';
  }
}

class _BigInsight extends StatelessWidget {
  final String label;
  final String value;
  final String sub;
  final Color color;
  final IconData icon;

  const _BigInsight({
    required this.label,
    required this.value,
    required this.sub,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
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
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(color: AppColors.slate400, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.6)),
                const SizedBox(height: 4),
                Text(value,
                    style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                const SizedBox(height: 2),
                Text(sub, style: const TextStyle(color: AppColors.slate400, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
