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

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notesListControllerProvider);
    final controller = ref.read(notesListControllerProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        title: const Text('Notes'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop() ? context.pop() : context.go('/dashboard'),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.emerald500,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.mic),
        label: const Text('New visit', style: TextStyle(fontWeight: FontWeight.w700)),
        onPressed: () => context.push('/capture'),
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
                  hintText: 'Search notes…',
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

  Widget _buildBody(NotesListState state, NotesListController controller) {
    if (state.loading && state.notes.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: AppColors.emerald400));
    }

    if (state.error != null && state.notes.isEmpty) {
      return _ErrorView(message: state.error!, onRetry: controller.refresh);
    }

    if (state.notes.isEmpty) {
      return const _EmptyView();
    }

    return RefreshIndicator(
      color: AppColors.emerald400,
      backgroundColor: AppColors.slate800,
      onRefresh: controller.refresh,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
        itemCount: state.notes.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) => _NoteCard(
          note: state.notes[i],
          onTap: () => context.push('/notes/${state.notes[i].id}'),
          onDelete: () => controller.delete(state.notes[i].id),
        ),
      ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  final ClinicalNote note;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _NoteCard({required this.note, required this.onTap, required this.onDelete});

  Color get _statusColor {
    switch (note.status) {
      case NoteStatus.signed:
        return AppColors.emerald400;
      case NoteStatus.processing:
        return AppColors.warning;
      case NoteStatus.failed:
        return AppColors.danger;
      case NoteStatus.ready:
      case NoteStatus.completed:
        return AppColors.info;
      case NoteStatus.draft:
        return AppColors.slate400;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.cardBg,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _statusColor.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.description_outlined, color: _statusColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      note.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (note.patientName != null && note.patientName!.isNotEmpty) ...[
                          const Icon(Icons.person_outline, size: 12, color: AppColors.slate400),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              note.patientName!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: AppColors.slate400, fontSize: 12),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(width: 3, height: 3, decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.slate500)),
                          const SizedBox(width: 10),
                        ],
                        const Icon(Icons.access_time, size: 12, color: AppColors.slate400),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('MMM d, h:mm a').format(note.updatedAt.toLocal()),
                          style: const TextStyle(color: AppColors.slate400, fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _statusColor.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        note.status.label,
                        style: TextStyle(color: _statusColor, fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.more_horiz, color: AppColors.slate400),
                onPressed: () async {
                  final action = await showModalBottomSheet<String>(
                    context: context,
                    backgroundColor: AppColors.slate800,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    builder: (_) => SafeArea(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(
                            leading: const Icon(Icons.open_in_new, color: Colors.white),
                            title: const Text('Open', style: TextStyle(color: Colors.white)),
                            onTap: () => Navigator.pop(context, 'open'),
                          ),
                          ListTile(
                            leading: const Icon(Icons.delete_outline, color: AppColors.danger),
                            title: const Text('Delete', style: TextStyle(color: AppColors.danger)),
                            onTap: () => Navigator.pop(context, 'delete'),
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  );
                  if (action == 'open') onTap();
                  if (action == 'delete') onDelete();
                },
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
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.emerald500.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(Icons.description_outlined, color: AppColors.emerald400, size: 40),
            ),
            const SizedBox(height: 16),
            const Text(
              'No notes yet',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            const Text(
              'Tap the mic below to record your first clinical visit.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.slate400, fontSize: 13),
            ),
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
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
