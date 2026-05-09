import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/models/note.dart';
import '../../core/theme/app_theme.dart';
import 'notes_controller.dart';

class NotesListScreen extends ConsumerStatefulWidget {
  const NotesListScreen({super.key});

  @override
  ConsumerState<NotesListScreen> createState() => _NotesListScreenState();
}

class _NotesListScreenState extends ConsumerState<NotesListScreen> {
  final _searchCtrl = TextEditingController();
  bool _showFilters = false;
  String _statusFilter = 'all';
  String _sortBy = 'date';
  bool _sortAsc = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<ClinicalNote> _applyLocalFilters(List<ClinicalNote> notes) {
    var filtered = notes.toList();
    if (_statusFilter != 'all') {
      filtered = filtered.where((n) => n.status.name == _statusFilter).toList();
    }
    filtered.sort((a, b) {
      final cmp = b.updatedAt.compareTo(a.updatedAt);
      return _sortAsc ? -cmp : cmp;
    });
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notesListControllerProvider);
    final controller = ref.read(notesListControllerProvider.notifier);
    final allNotes = state.notes;
    final filtered = _applyLocalFilters(allNotes);

    // Stats
    final total = allNotes.length;
    final drafts = allNotes.where((n) => n.status == NoteStatus.draft).length;
    final completed = allNotes.where((n) => n.status == NoteStatus.completed || n.status == NoteStatus.ready).length;
    final signed = allNotes.where((n) => n.status == NoteStatus.signed).length;

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  // Back button
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
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Clinical Notes',
                            style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
                        Text('Manage and review all your clinical documentation.',
                            style: TextStyle(color: AppColors.slate400, fontSize: 12)),
                      ],
                    ),
                  ),
                  // Refresh
                  _HeaderBtn(
                    icon: Icons.refresh,
                    label: 'Refresh',
                    onTap: controller.refresh,
                  ),
                  const SizedBox(width: 8),
                  // New Note
                  GestureDetector(
                    onTap: () => context.push('/capture'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                      decoration: BoxDecoration(
                        gradient: kEmeraldGradient,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add, color: Colors.white, size: 16),
                          SizedBox(width: 4),
                          Text('New Note',
                              style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Stats cards ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  _StatCard(label: 'Total Notes', value: '$total', color: AppColors.info, icon: Icons.description_outlined),
                  const SizedBox(width: 8),
                  _StatCard(label: 'Drafts', value: '$drafts', color: const Color(0xFFF59E0B), icon: Icons.access_time),
                  const SizedBox(width: 8),
                  _StatCard(label: 'Completed', value: '$completed', color: AppColors.emerald400, icon: Icons.check_circle_outline),
                  const SizedBox(width: 8),
                  _StatCard(label: 'Signed', value: '$signed', color: const Color(0xFF22C55E), icon: Icons.verified_outlined),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // ── Search bar + Filters toggle ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 44,
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
                          hintText: 'Search by patient name, template, status...',
                          hintStyle: TextStyle(color: AppColors.slate500, fontSize: 13),
                          prefixIcon: Icon(Icons.search, color: AppColors.slate500, size: 18),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () => setState(() => _showFilters = !_showFilters),
                    child: Container(
                      height: 44,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: _showFilters ? const Color(0x1AFFFFFF) : const Color(0x0DFFFFFF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _showFilters ? AppColors.emerald400.withValues(alpha: 0.4) : const Color(0x1AFFFFFF)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.filter_list, color: _showFilters ? AppColors.emerald400 : AppColors.slate400, size: 16),
                          const SizedBox(width: 6),
                          Text('Filters', style: TextStyle(color: _showFilters ? AppColors.emerald400 : AppColors.slate400, fontSize: 13, fontWeight: FontWeight.w600)),
                          const SizedBox(width: 4),
                          Icon(_showFilters ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                              color: _showFilters ? AppColors.emerald400 : AppColors.slate400, size: 16),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Filter row ──
            if (_showFilters) ...[
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0x0DFFFFFF),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0x1AFFFFFF)),
                  ),
                  child: Row(
                    children: [
                      Expanded(child: _FilterDropdown(
                        label: 'Status',
                        value: _statusFilter,
                        items: const {'all': 'All Status', 'draft': 'Draft', 'completed': 'Completed', 'signed': 'Signed', 'processing': 'Processing'},
                        onChanged: (v) => setState(() => _statusFilter = v),
                      )),
                      const SizedBox(width: 8),
                      Expanded(child: _FilterDropdown(
                        label: 'Sort By',
                        value: _sortBy,
                        items: const {'date': 'Date', 'name': 'Name'},
                        onChanged: (v) => setState(() => _sortBy = v),
                      )),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => setState(() => _sortAsc = !_sortAsc),
                        child: Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0x0DFFFFFF),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0x1AFFFFFF)),
                          ),
                          child: Icon(
                            _sortAsc ? Icons.arrow_upward : Icons.arrow_downward,
                            color: AppColors.slate400, size: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 10),

            // ── Notes list ──
            Expanded(child: _buildBody(state, controller, filtered)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(NotesListState state, NotesListController controller, List<ClinicalNote> filtered) {
    if (state.loading && state.notes.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: AppColors.emerald400));
    }
    if (state.error != null && state.notes.isEmpty) {
      return _ErrorView(message: state.error!, onRetry: controller.refresh);
    }
    if (filtered.isEmpty) {
      return const _EmptyView();
    }

    return RefreshIndicator(
      color: AppColors.emerald400,
      backgroundColor: AppColors.slate800,
      onRefresh: controller.refresh,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
        itemCount: filtered.length,
        itemBuilder: (_, i) => _NoteRow(
          note: filtered[i],
          onTap: () => context.push('/notes/${filtered[i].id}'),
          onDelete: () => controller.delete(filtered[i].id),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Widgets
// ═══════════════════════════════════════════════════════════════════

class _HeaderBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _HeaderBtn({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: const Color(0x0DFFFFFF),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0x1AFFFFFF)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.slate400, size: 14),
            const SizedBox(width: 5),
            Text(label, style: const TextStyle(color: AppColors.slate400, fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  const _StatCard({required this.label, required this.value, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0x0DFFFFFF),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0x14FFFFFF)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(label,
                      style: const TextStyle(color: AppColors.slate400, fontSize: 10, fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis),
                ),
                Container(
                  width: 26, height: 26,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 14),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(value,
                style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.w900)),
          ],
        ),
      ),
    );
  }
}

class _FilterDropdown extends StatelessWidget {
  final String label;
  final String value;
  final Map<String, String> items;
  final ValueChanged<String> onChanged;
  const _FilterDropdown({required this.label, required this.value, required this.items, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.slate500, fontSize: 10, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: const Color(0x0DFFFFFF),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0x14FFFFFF)),
          ),
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            underline: const SizedBox(),
            dropdownColor: AppColors.slate800,
            icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.slate400, size: 16),
            style: const TextStyle(color: Colors.white, fontSize: 12),
            items: items.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
            onChanged: (v) { if (v != null) onChanged(v); },
          ),
        ),
      ],
    );
  }
}

/// Each note row — matches the web's layout: avatar, name, date/template, status badge, menu.
class _NoteRow extends StatelessWidget {
  final ClinicalNote note;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  const _NoteRow({required this.note, required this.onTap, required this.onDelete});

  Color get _statusColor {
    switch (note.status) {
      case NoteStatus.signed:
        return const Color(0xFF22C55E);
      case NoteStatus.processing:
        return AppColors.warning;
      case NoteStatus.failed:
        return AppColors.danger;
      case NoteStatus.ready:
      case NoteStatus.completed:
        return AppColors.emerald400;
      case NoteStatus.draft:
        return const Color(0xFFF59E0B);
    }
  }

  Color get _statusBgColor => _statusColor.withValues(alpha: 0.15);

  IconData get _statusIcon {
    switch (note.status) {
      case NoteStatus.signed:
        return Icons.verified;
      case NoteStatus.processing:
        return Icons.hourglass_top;
      case NoteStatus.failed:
        return Icons.error_outline;
      case NoteStatus.ready:
      case NoteStatus.completed:
        return Icons.check_circle;
      case NoteStatus.draft:
        return Icons.access_time;
    }
  }

  @override
  Widget build(BuildContext context) {
    final initial = (note.patientName ?? 'U').isNotEmpty ? (note.patientName ?? 'U')[0].toUpperCase() : 'U';
    final dateStr = DateFormat('MMM d, yyyy').format(note.createdAt.toLocal());
    final tmpl = note.templateId ?? 'Note';
    // Capitalize template label
    final tmplLabel = '${tmpl[0].toUpperCase()}${tmpl.substring(1)} Note';

    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0x0FFFFFFF))),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 42, height: 42,
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(initial,
                      style: const TextStyle(color: AppColors.info, fontSize: 17, fontWeight: FontWeight.w800)),
                ),
              ),
              const SizedBox(width: 14),
              // Name + meta
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      note.patientName ?? 'Unknown Patient',
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontSize: 14.5, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined, size: 11, color: AppColors.slate500),
                        const SizedBox(width: 4),
                        Text(dateStr, style: const TextStyle(color: AppColors.slate500, fontSize: 11.5)),
                        const SizedBox(width: 10),
                        const Icon(Icons.description_outlined, size: 11, color: AppColors.slate500),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(tmplLabel,
                              maxLines: 1, overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: AppColors.slate500, fontSize: 11.5)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Status badge
              Icon(_statusIcon, color: _statusColor, size: 16),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusBgColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  note.status.label.toLowerCase(),
                  style: TextStyle(color: _statusColor, fontSize: 11, fontWeight: FontWeight.w700),
                ),
              ),
              // Menu
              SizedBox(
                width: 32,
                child: PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: AppColors.slate500, size: 18),
                  color: AppColors.slate800,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  onSelected: (v) {
                    if (v == 'open') onTap();
                    if (v == 'delete') onDelete();
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'open', child: Row(children: [
                      Icon(Icons.open_in_new, color: Colors.white, size: 16), SizedBox(width: 8),
                      Text('Open', style: TextStyle(color: Colors.white, fontSize: 13)),
                    ])),
                    const PopupMenuItem(value: 'delete', child: Row(children: [
                      Icon(Icons.delete_outline, color: AppColors.danger, size: 16), SizedBox(width: 8),
                      Text('Delete', style: TextStyle(color: AppColors.danger, fontSize: 13)),
                    ])),
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

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                color: AppColors.emerald500.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(Icons.description_outlined, color: AppColors.emerald400, size: 40),
            ),
            const SizedBox(height: 16),
            const Text('No notes yet',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            const Text('Tap "+ New Note" to record your first clinical visit.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.slate400, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, color: AppColors.danger, size: 48),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 14)),
            const SizedBox(height: 16),
            ElevatedButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
