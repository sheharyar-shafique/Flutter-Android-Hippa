import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/models/note.dart';
import '../../core/theme/app_theme.dart';
import '../dashboard/dashboard_controller.dart';
import '../notes/notes_controller.dart';

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});
  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  int _days = 30;

  @override
  Widget build(BuildContext context) {
    final dash = ref.watch(dashboardControllerProvider);
    final notesState = ref.watch(notesListControllerProvider);
    final allNotes = notesState.notes;
    final cutoff = DateTime.now().subtract(Duration(days: _days));
    final notes = allNotes.where((n) => n.createdAt.isAfter(cutoff)).toList();
    final totalInPeriod = notes.length;
    final dailyAvg = _days > 0 ? (totalInPeriod / _days) : 0.0;
    final templates = <String, int>{};
    for (final n in notes) { templates[n.templateId ?? 'Other'] = (templates[n.templateId ?? 'Other'] ?? 0) + 1; }
    final drafts = notes.where((n) => n.status == NoteStatus.draft).length;
    final signed = notes.where((n) => n.status == NoteStatus.signed).length;
    final completed = notes.where((n) => n.status == NoteStatus.completed || n.status == NoteStatus.ready).length;
    // Previous period
    final prevCutoff = cutoff.subtract(Duration(days: _days));
    final prevNotes = allNotes.where((n) => n.createdAt.isAfter(prevCutoff) && n.createdAt.isBefore(cutoff)).length;
    final changePct = prevNotes > 0 ? ((totalInPeriod - prevNotes) / prevNotes * 100) : (totalInPeriod > 0 ? 100 : 0);
    // Daily data for line chart
    final dailyData = <DateTime, int>{};
    for (var i = 0; i < _days; i++) { final d = DateTime.now().subtract(Duration(days: _days - 1 - i)); dailyData[DateTime(d.year, d.month, d.day)] = 0; }
    for (final n in notes) { final d = DateTime(n.createdAt.year, n.createdAt.month, n.createdAt.day); dailyData[d] = (dailyData[d] ?? 0) + 1; }
    // Day of week data
    final weekDays = List.filled(7, 0);
    for (final n in notes) { weekDays[n.createdAt.weekday % 7] += 1; }

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SafeArea(child: ListView(padding: const EdgeInsets.fromLTRB(20, 16, 20, 32), children: [
        // Header
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          GestureDetector(onTap: () => context.canPop() ? context.pop() : context.go('/dashboard'),
            child: Container(width: 36, height: 36, decoration: BoxDecoration(color: const Color(0x0DFFFFFF), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0x1AFFFFFF))), child: const Icon(Icons.arrow_back, color: Colors.white, size: 18))),
          const SizedBox(width: 12),
          Container(width: 44, height: 44, decoration: BoxDecoration(color: AppColors.emerald400.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(14)),
            child: const Icon(Icons.show_chart, color: AppColors.emerald400, size: 22)),
          const SizedBox(width: 12),
          const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Advanced Analytics', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
            Text('Clinical documentation insights & trends', style: TextStyle(color: AppColors.slate400, fontSize: 12)),
          ])),
        ]),
        const SizedBox(height: 12),
        // Time range tabs + Export
        Row(children: [
          _TimeTab(label: '7 days', selected: _days == 7, onTap: () => setState(() => _days = 7)),
          _TimeTab(label: '30 days', selected: _days == 30, onTap: () => setState(() => _days = 30)),
          _TimeTab(label: '90 days', selected: _days == 90, onTap: () => setState(() => _days = 90)),
          const Spacer(),
          GestureDetector(onTap: () {},
            child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), decoration: BoxDecoration(color: const Color(0x0DFFFFFF), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0x1AFFFFFF))),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.download, color: AppColors.slate400, size: 14), SizedBox(width: 4), Text('Export CSV', style: TextStyle(color: AppColors.slate400, fontSize: 12, fontWeight: FontWeight.w600))]))),
        ]),
        const SizedBox(height: 16),
        // Stats row
        Row(children: [
          _StatCard(label: 'NOTES (${_days}D)', value: '$totalInPeriod', color: AppColors.emerald400, icon: Icons.description_outlined),
          const SizedBox(width: 8),
          _StatCard(label: 'DAILY AVERAGE', value: dailyAvg.toStringAsFixed(1), color: const Color(0xFFA855F7), icon: Icons.bar_chart),
          const SizedBox(width: 8),
          _StatCard(label: 'VS PREVIOUS PERIOD', value: '${changePct >= 0 ? '+' : ''}${changePct.toStringAsFixed(0)}%', color: AppColors.emerald400, icon: Icons.trending_up),
          const SizedBox(width: 8),
          _StatCard(label: 'TEMPLATES USED', value: '${templates.length}', color: const Color(0xFFF59E0B), icon: Icons.calendar_today),
        ]),
        const SizedBox(height: 16),
        // Line chart - Notes Over Time
        Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: const Color(0x0DFFFFFF), borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0x14FFFFFF))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Notes Over Time', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
                Text('Daily note creation', style: TextStyle(color: AppColors.slate400, fontSize: 11)),
              ])),
              Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: const Color(0x0DFFFFFF), borderRadius: BorderRadius.circular(6)),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.show_chart, color: AppColors.emerald400, size: 12), SizedBox(width: 4), Text('Notes', style: TextStyle(color: AppColors.emerald400, fontSize: 11, fontWeight: FontWeight.w600))])),
            ]),
            const SizedBox(height: 16),
            SizedBox(height: 160, child: CustomPaint(painter: _LineChartPainter(dailyData.values.toList()), size: Size.infinite)),
          ])),
        const SizedBox(height: 16),
        // Bottom row: By Template, By Status, Busiest Days
        // By Template
        Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: const Color(0x0DFFFFFF), borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0x14FFFFFF))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('By Template', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
            const Text('Most used note types', style: TextStyle(color: AppColors.slate400, fontSize: 11)),
            const SizedBox(height: 14),
            if (templates.isEmpty) const Text('No data', style: TextStyle(color: AppColors.slate500, fontSize: 13)),
            ...templates.entries.take(5).map((e) {
              final maxVal = templates.values.reduce(max);
              final pct = maxVal > 0 ? e.value / maxVal : 0.0;
              final colors = [AppColors.emerald400, const Color(0xFF818CF8), const Color(0xFFF59E0B), const Color(0xFFEC4899), const Color(0xFF38BDF8)];
              final idx = templates.keys.toList().indexOf(e.key);
              final c = colors[idx % colors.length];
              return Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(children: [
                SizedBox(width: 70, child: Text(e.key, style: const TextStyle(color: AppColors.slate400, fontSize: 12), overflow: TextOverflow.ellipsis)),
                const SizedBox(width: 8),
                Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: pct, minHeight: 16, backgroundColor: const Color(0x14FFFFFF), valueColor: AlwaysStoppedAnimation(c)))),
              ]));
            }),
          ])),
        const SizedBox(height: 14),
        // By Status + Busiest Days
        Row(children: [
          // By Status
          Expanded(child: Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: const Color(0x0DFFFFFF), borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0x14FFFFFF))),
            child: Column(children: [
              const Text('By Status', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800)),
              const Text('Completion breakdown', style: TextStyle(color: AppColors.slate400, fontSize: 10)),
              const SizedBox(height: 12),
              SizedBox(height: 100, width: 100, child: CustomPaint(painter: _DonutPainter(draft: drafts, signed: signed, completed: completed))),
              const SizedBox(height: 10),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                _Legend(color: const Color(0xFFF59E0B), label: 'Draft', count: drafts),
                const SizedBox(width: 12),
                _Legend(color: const Color(0xFF818CF8), label: 'Signed', count: signed),
              ]),
            ]))),
          const SizedBox(width: 10),
          // Busiest Days
          Expanded(child: Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: const Color(0x0DFFFFFF), borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0x14FFFFFF))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Busiest Days', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800)),
              const Text('Notes by day of week', style: TextStyle(color: AppColors.slate400, fontSize: 10)),
              const SizedBox(height: 12),
              SizedBox(height: 100, child: CustomPaint(painter: _BarChartPainter(weekDays), size: Size.infinite)),
              const SizedBox(height: 6),
              Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'].map((d) => Text(d, style: const TextStyle(color: AppColors.slate500, fontSize: 8))).toList()),
            ]))),
        ]),
      ])),
    );
  }
}

class _TimeTab extends StatelessWidget {
  final String label; final bool selected; final VoidCallback onTap;
  const _TimeTab({required this.label, required this.selected, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(onTap: onTap, child: Container(
    margin: const EdgeInsets.only(right: 4),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    decoration: BoxDecoration(color: selected ? const Color(0x1AFFFFFF) : Colors.transparent, borderRadius: BorderRadius.circular(8), border: Border.all(color: selected ? const Color(0x2AFFFFFF) : const Color(0x14FFFFFF))),
    child: Text(label, style: TextStyle(color: selected ? Colors.white : AppColors.slate400, fontSize: 12, fontWeight: FontWeight.w600))));
}

class _StatCard extends StatelessWidget {
  final String label, value; final Color color; final IconData icon;
  const _StatCard({required this.label, required this.value, required this.color, required this.icon});
  @override
  Widget build(BuildContext context) => Expanded(child: Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: const Color(0x0DFFFFFF), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0x14FFFFFF))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(width: 30, height: 30, decoration: BoxDecoration(color: color.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: color, size: 15)),
      const SizedBox(height: 8),
      Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
      const SizedBox(height: 2),
      Text(label, style: const TextStyle(color: AppColors.slate400, fontSize: 8, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
    ])));
}

class _Legend extends StatelessWidget {
  final Color color; final String label; final int count;
  const _Legend({required this.color, required this.label, required this.count});
  @override
  Widget build(BuildContext context) => Row(children: [
    Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
    const SizedBox(width: 4),
    Text('$label ', style: const TextStyle(color: AppColors.slate400, fontSize: 10)),
    Text('$count', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
  ]);
}

// ── Custom Painters ──

class _LineChartPainter extends CustomPainter {
  final List<int> data;
  _LineChartPainter(this.data);
  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;
    final maxV = data.reduce(max).toDouble().clamp(1.0, double.infinity);
    final paint = Paint()..color = AppColors.emerald400..strokeWidth = 2..style = PaintingStyle.stroke;
    final fillPaint = Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [AppColors.emerald400.withValues(alpha: 0.3), AppColors.emerald400.withValues(alpha: 0.0)]).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    final gridPaint = Paint()..color = const Color(0x14FFFFFF)..strokeWidth = 0.5;
    // Grid
    for (var i = 0; i <= 4; i++) { final y = size.height * i / 4; canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint); }
    // Path
    final path = Path();
    final fillPath = Path();
    final step = data.length > 1 ? size.width / (data.length - 1) : size.width;
    for (var i = 0; i < data.length; i++) {
      final x = i * step; final y = size.height - (data[i] / maxV * size.height);
      if (i == 0) { path.moveTo(x, y); fillPath.moveTo(x, size.height); fillPath.lineTo(x, y); } else { path.lineTo(x, y); fillPath.lineTo(x, y); }
    }
    fillPath.lineTo((data.length - 1) * step, size.height); fillPath.close();
    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _DonutPainter extends CustomPainter {
  final int draft, signed, completed;
  _DonutPainter({required this.draft, required this.signed, required this.completed});
  @override
  void paint(Canvas canvas, Size size) {
    final total = draft + signed + completed;
    if (total == 0) return;
    final r = min(size.width, size.height) / 2;
    final c = Offset(size.width / 2, size.height / 2);
    final paint = Paint()..style = PaintingStyle.stroke..strokeWidth = r * 0.35..strokeCap = StrokeCap.butt;
    var start = -pi / 2;
    void arc(int val, Color color) { if (val == 0) return; final sweep = val / total * 2 * pi; paint.color = color; canvas.drawArc(Rect.fromCircle(center: c, radius: r - paint.strokeWidth / 2), start, sweep, false, paint); start += sweep; }
    arc(draft, const Color(0xFFF59E0B));
    arc(signed, const Color(0xFF818CF8));
    arc(completed, AppColors.emerald400);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _BarChartPainter extends CustomPainter {
  final List<int> data;
  _BarChartPainter(this.data);
  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;
    final maxV = data.reduce(max).toDouble().clamp(1.0, double.infinity);
    final barW = size.width / (data.length * 2);
    final paint = Paint()..color = const Color(0xFF818CF8);
    for (var i = 0; i < data.length; i++) {
      final x = (i * 2 + 0.5) * barW;
      final h = data[i] / maxV * size.height;
      final rect = RRect.fromRectAndRadius(Rect.fromLTWH(x, size.height - h, barW, h), const Radius.circular(3));
      canvas.drawRRect(rect, paint);
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
