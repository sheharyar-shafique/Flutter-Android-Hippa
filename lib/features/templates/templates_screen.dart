import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/data/default_templates.dart';
import '../../core/models/template.dart';
import '../../core/theme/app_theme.dart';
import 'templates_controller.dart';

const _kAllSpecialties = 'All';

/// Full port of frontend/src/pages/TemplatesPage.tsx — header with
/// "Template Library" badge + count, search bar, My/All tabs,
/// specialty filter pills, and a single-column card grid.
class TemplatesScreen extends ConsumerStatefulWidget {
  /// When `pickerMode` is true, tapping a card returns the chosen
  /// template via Navigator.pop instead of opening the editor. Used
  /// from Capture flow.
  final bool pickerMode;

  const TemplatesScreen({super.key, this.pickerMode = false});

  @override
  ConsumerState<TemplatesScreen> createState() => _TemplatesScreenState();
}

class _TemplatesScreenState extends ConsumerState<TemplatesScreen> {
  final _searchCtrl = TextEditingController();

  String _activeTab = 'my'; // 'my' | 'all'
  String _selectedSpecialty = _kAllSpecialties;
  String _searchQuery = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<NoteTemplate> _filtered(TemplatesState state) {
    final source = _activeTab == 'my' ? state.myTemplates : state.allTemplates;
    final q = _searchQuery.toLowerCase();
    return source.where((t) {
      final matchesSpecialty =
          _selectedSpecialty == _kAllSpecialties || t.specialty == _selectedSpecialty;
      final matchesSearch = q.isEmpty ||
          t.name.toLowerCase().contains(q) ||
          t.specialty.toLowerCase().contains(q) ||
          t.description.toLowerCase().contains(q);
      return matchesSpecialty && matchesSearch;
    }).toList();
  }

  Future<void> _confirmDelete(NoteTemplate t) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.slate800,
        title: Text('Delete "${t.name}"?',
            style: const TextStyle(color: Colors.white, fontSize: 16)),
        content: const Text(
          'This permanently removes the template from your library.',
          style: TextStyle(color: AppColors.slate400),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(templatesControllerProvider.notifier).delete(t);
      _toast('Template deleted', AppColors.danger);
    }
  }

  void _share(NoteTemplate t) {
    final text = '${t.name}: ${t.sections.join(', ')}';
    Clipboard.setData(ClipboardData(text: text));
    _toast('Template info copied to clipboard', AppColors.emerald500);
  }

  void _use(NoteTemplate t) {
    ref.read(templatesControllerProvider.notifier).select(t.id);
    _toast('Now using "${t.name}"', AppColors.emerald500);
    if (widget.pickerMode) {
      Navigator.pop(context, t);
    } else {
      context.go('/capture');
    }
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
    final state = ref.watch(templatesControllerProvider);
    final filtered = _filtered(state);

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        title: Text(widget.pickerMode ? 'Pick a template' : 'Templates'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => widget.pickerMode ? Navigator.pop(context) : context.go('/dashboard'),
        ),
      ),
      body: SafeArea(
        child: state.initialising
            ? const Center(child: CircularProgressIndicator(color: AppColors.emerald400))
            : CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: _Header(
                      total: state.allTemplates.length,
                      onCreate: widget.pickerMode
                          ? null
                          : () => context.go('/templates/new'),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
                      child: _SearchBox(
                        controller: _searchCtrl,
                        onChanged: (v) => setState(() => _searchQuery = v),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _TabSwitcher(
                        active: _activeTab,
                        myCount: state.myTemplates.length,
                        allCount: state.allTemplates.length,
                        onChanged: (t) => setState(() => _activeTab = t),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
                      child: _SpecialtyPills(
                        selected: _selectedSpecialty,
                        onSelected: (sp) => setState(() => _selectedSpecialty = sp),
                      ),
                    ),
                  ),
                  if (filtered.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _EmptyState(activeTab: _activeTab),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                      sliver: SliverList.builder(
                        itemCount: filtered.length,
                        itemBuilder: (_, i) {
                          final t = filtered[i];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _TemplateCard(
                              template: t,
                              isAdded: state.isAdded(t.id),
                              isSelected: state.isSelected(t.id),
                              pickerMode: widget.pickerMode,
                              onToggleAdd: () => ref
                                  .read(templatesControllerProvider.notifier)
                                  .toggleAdd(t),
                              onEdit: widget.pickerMode
                                  ? null
                                  : () => context.go('/templates/${t.id}/edit'),
                              onShare: () => _share(t),
                              onDelete: t.isCustom ? () => _confirmDelete(t) : null,
                              onUse: () => _use(t),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Header
// ─────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final int total;
  final VoidCallback? onCreate;

  const _Header({required this.total, required this.onCreate});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFA78BFA), Color(0xFF8B5CF6)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.description, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Template Library',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.4,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  borderRadius: BorderRadius.circular(50),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Text(
                  '$total templates',
                  style: const TextStyle(
                    color: AppColors.slate400,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Choose or edit any of our templates, or create your own from scratch.',
            style: TextStyle(color: AppColors.slate400, fontSize: 12.5, height: 1.45),
          ),
          const SizedBox(height: 4),
          const Text(
            "Added templates appear in the Templates dropdown when you start a new visit.",
            style: TextStyle(color: AppColors.slate500, fontSize: 12, height: 1.45),
          ),
          if (onCreate != null) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: kEmeraldGradient,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.emerald500.withValues(alpha: 0.3),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: onCreate,
                    child: const Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add, color: Colors.white, size: 18),
                          SizedBox(width: 6),
                          Text(
                            'Create New Template',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Search box
// ─────────────────────────────────────────────────────────────────

class _SearchBox extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _SearchBox({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: const TextStyle(color: Colors.white, fontSize: 13.5),
      decoration: InputDecoration(
        hintText: 'Search by name, specialty or keyword…',
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.25), fontSize: 13.5),
        prefixIcon: const Icon(Icons.search, color: AppColors.slate500, size: 18),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                icon: const Icon(Icons.clear, color: AppColors.slate400, size: 16),
                onPressed: () {
                  controller.clear();
                  onChanged('');
                },
              ),
        filled: true,
        fillColor: const Color(0x0DFFFFFF),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0x1AFFFFFF)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0x1AFFFFFF)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.emerald400.withValues(alpha: 0.5), width: 1.5),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Tabs
// ─────────────────────────────────────────────────────────────────

class _TabSwitcher extends StatelessWidget {
  final String active;
  final int myCount;
  final int allCount;
  final ValueChanged<String> onChanged;

  const _TabSwitcher({
    required this.active,
    required this.myCount,
    required this.allCount,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0x0AFFFFFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x1AFFFFFF)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _TabButton(
              label: 'My Templates ($myCount)',
              active: active == 'my',
              onTap: () => onChanged('my'),
            ),
          ),
          Expanded(
            child: _TabButton(
              label: 'All Templates ($allCount)',
              active: active == 'all',
              onTap: () => onChanged('all'),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _TabButton({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? AppColors.emerald500 : Colors.transparent,
      borderRadius: BorderRadius.circular(11),
      child: InkWell(
        borderRadius: BorderRadius.circular(11),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: active ? Colors.white : AppColors.slate400,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Specialty filter pills
// ─────────────────────────────────────────────────────────────────

class _SpecialtyPills extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelected;

  const _SpecialtyPills({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final specialties = [_kAllSpecialties, ...kAllSpecialties];

    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: specialties.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (_, i) {
          final sp = specialties[i];
          final isSelected = selected == sp;
          return Material(
            color: isSelected ? AppColors.emerald500 : const Color(0x0AFFFFFF),
            borderRadius: BorderRadius.circular(50),
            child: InkWell(
              borderRadius: BorderRadius.circular(50),
              onTap: () => onSelected(sp),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(50),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.emerald500
                        : const Color(0x1AFFFFFF),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (sp != _kAllSpecialties) ...[
                      Icon(
                        Icons.local_offer,
                        size: 11,
                        color: isSelected ? Colors.white : AppColors.slate400,
                      ),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      sp,
                      style: TextStyle(
                        color: isSelected ? Colors.white : AppColors.slate400,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Template card
// ─────────────────────────────────────────────────────────────────

class _TemplateCard extends StatelessWidget {
  static const _visibleSections = 4;

  final NoteTemplate template;
  final bool isAdded;
  final bool isSelected;
  final bool pickerMode;
  final VoidCallback onToggleAdd;
  final VoidCallback? onEdit;
  final VoidCallback onShare;
  final VoidCallback? onDelete;
  final VoidCallback onUse;

  const _TemplateCard({
    required this.template,
    required this.isAdded,
    required this.isSelected,
    required this.pickerMode,
    required this.onToggleAdd,
    required this.onEdit,
    required this.onShare,
    required this.onDelete,
    required this.onUse,
  });

  @override
  Widget build(BuildContext context) {
    final color = specialtyColor(template.specialty);
    final extra = template.sections.length - _visibleSections;
    final sections = template.sections.take(_visibleSections).toList();

    return Container(
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.emerald500.withValues(alpha: 0.1)
            : const Color(0x0AFFFFFF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isSelected
              ? AppColors.emerald500.withValues(alpha: 0.4)
              : const Color(0x14FFFFFF),
          width: isSelected ? 1.5 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: pickerMode ? onUse : null,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Specialty + Added badges
                Row(
                  children: [
                    _SpecialtyBadge(name: template.specialty, color: color),
                    if (isAdded) ...[
                      const SizedBox(width: 8),
                      const _AddedBadge(),
                    ],
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  template.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  template.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.slate500,
                    fontSize: 12.5,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 12),
                if (template.sections.isEmpty)
                  const Text(
                    'No sections defined yet',
                    style: TextStyle(
                      color: AppColors.slate500,
                      fontSize: 11.5,
                      fontStyle: FontStyle.italic,
                    ),
                  )
                else ...[
                  ...sections.map(
                    (s) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.description_outlined,
                              size: 13, color: AppColors.slate500),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              s,
                              style: const TextStyle(
                                color: AppColors.slate400,
                                fontSize: 12.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (extra > 0)
                    Padding(
                      padding: const EdgeInsets.only(left: 19, top: 2),
                      child: Text(
                        '+$extra more section${extra == 1 ? '' : 's'}',
                        style: const TextStyle(
                          color: AppColors.slate500,
                          fontSize: 11.5,
                        ),
                      ),
                    ),
                ],
                const SizedBox(height: 12),
                Container(height: 1, color: const Color(0x12FFFFFF)),
                const SizedBox(height: 10),
                if (!pickerMode) _ActionRow(
                  isAdded: isAdded,
                  hasEdit: onEdit != null,
                  hasDelete: onDelete != null,
                  onToggleAdd: onToggleAdd,
                  onEdit: onEdit ?? () {},
                  onShare: onShare,
                  onDelete: onDelete ?? () {},
                ),
                if (isSelected) ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 38,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: kEmeraldGradient,
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(11),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(11),
                          onTap: onUse,
                          child: const Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.check, color: Colors.white, size: 14),
                                SizedBox(width: 6),
                                Text(
                                  'Currently Selected — Start Recording',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SpecialtyBadge extends StatelessWidget {
  final String name;
  final TemplateSpecialtyColor color;

  const _SpecialtyBadge({required this.name, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.bg,
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: color.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.local_offer, size: 9, color: color.fg),
          const SizedBox(width: 4),
          Text(
            name,
            style: TextStyle(
              color: color.fg,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _AddedBadge extends StatelessWidget {
  const _AddedBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.emerald500.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: AppColors.emerald500.withValues(alpha: 0.4)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle, size: 11, color: AppColors.emerald400),
          SizedBox(width: 4),
          Text(
            'Added',
            style: TextStyle(
              color: AppColors.emerald400,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final bool isAdded;
  final bool hasEdit;
  final bool hasDelete;
  final VoidCallback onToggleAdd;
  final VoidCallback onEdit;
  final VoidCallback onShare;
  final VoidCallback onDelete;

  const _ActionRow({
    required this.isAdded,
    required this.hasEdit,
    required this.hasDelete,
    required this.onToggleAdd,
    required this.onEdit,
    required this.onShare,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 36,
            child: OutlinedButton.icon(
              onPressed: onToggleAdd,
              icon: Icon(
                isAdded ? Icons.close : Icons.add,
                size: 14,
              ),
              label: Text(isAdded ? 'Remove' : 'Add',
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
              style: OutlinedButton.styleFrom(
                foregroundColor: isAdded ? AppColors.danger : AppColors.emerald400,
                side: BorderSide(
                  color: (isAdded ? AppColors.danger : AppColors.emerald400)
                      .withValues(alpha: 0.4),
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
            ),
          ),
        ),
        if (hasEdit) ...[
          const SizedBox(width: 6),
          TextButton(
            onPressed: onEdit,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.slate400,
              minimumSize: const Size(56, 36),
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            child: const Text('Edit',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
          ),
        ],
        const SizedBox(width: 2),
        IconButton(
          tooltip: 'Copy template info',
          onPressed: onShare,
          icon: const Icon(Icons.share, color: AppColors.slate500, size: 17),
          padding: const EdgeInsets.all(6),
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        ),
        if (hasDelete)
          IconButton(
            tooltip: 'Delete template',
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline, color: AppColors.slate500, size: 17),
            padding: const EdgeInsets.all(6),
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Empty state
// ─────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final String activeTab;
  const _EmptyState({required this.activeTab});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.library_books_outlined,
                size: 56, color: AppColors.slate500),
            const SizedBox(height: 16),
            Text(
              activeTab == 'my'
                  ? 'No templates added yet'
                  : 'No templates match your search',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              activeTab == 'my'
                  ? 'Switch to All Templates to add some.'
                  : 'Try a different keyword or specialty.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.slate500, fontSize: 12.5),
            ),
          ],
        ),
      ),
    );
  }
}
