import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/template.dart';
import '../../core/theme/app_theme.dart';
import 'templates_controller.dart';

class TemplatesScreen extends ConsumerWidget {
  /// When `pickerMode` is true, tapping a template returns it via Navigator.pop
  /// instead of just opening the edit/preview.
  final bool pickerMode;

  const TemplatesScreen({super.key, this.pickerMode = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(templatesControllerProvider);
    final controller = ref.read(templatesControllerProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        title: Text(pickerMode ? 'Pick a template' : 'Templates'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => pickerMode ? Navigator.pop(context) : context.go('/dashboard'),
        ),
      ),
      body: SafeArea(child: _buildBody(context, state, controller)),
    );
  }

  Widget _buildBody(BuildContext context, TemplatesState state, TemplatesController controller) {
    if (state.loading && state.templates.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: AppColors.emerald400));
    }

    if (state.error != null && state.templates.isEmpty) {
      return _ErrorView(message: state.error!, onRetry: controller.refresh);
    }

    final builtIns = state.templates.where((t) => !t.isCustom).toList();
    final customs = state.templates.where((t) => t.isCustom).toList();

    return RefreshIndicator(
      color: AppColors.emerald400,
      backgroundColor: AppColors.slate800,
      onRefresh: controller.refresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          if (customs.isNotEmpty) ...[
            const _SectionHeader(label: 'Your custom templates', icon: Icons.star_outline),
            ...customs.map((t) => _TemplateCard(template: t, pickerMode: pickerMode)),
            const SizedBox(height: 24),
          ],
          const _SectionHeader(label: 'Built-in templates', icon: Icons.library_books_outlined),
          ...builtIns.map((t) => _TemplateCard(template: t, pickerMode: pickerMode)),
          if (state.templates.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 60),
              child: Center(
                child: Text(
                  'No templates available yet.',
                  style: TextStyle(color: AppColors.slate400),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  final IconData icon;
  const _SectionHeader({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.emerald400),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.slate400,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _TemplateCard extends StatelessWidget {
  final NoteTemplate template;
  final bool pickerMode;

  const _TemplateCard({required this.template, required this.pickerMode});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: () {
            if (pickerMode) {
              Navigator.pop(context, template);
            }
          },
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.emerald500.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.description_outlined,
                    size: 20,
                    color: AppColors.emerald400,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        template.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (template.specialty != null && template.specialty!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          template.specialty!,
                          style: const TextStyle(color: AppColors.slate400, fontSize: 12),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  pickerMode ? Icons.chevron_right : Icons.more_horiz,
                  color: AppColors.slate400,
                ),
              ],
            ),
          ),
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
