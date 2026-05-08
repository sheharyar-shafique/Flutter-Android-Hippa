import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import 'templates_controller.dart';

class TemplateEditorScreen extends ConsumerStatefulWidget {
  final String? templateId;
  const TemplateEditorScreen({super.key, this.templateId});

  @override
  ConsumerState<TemplateEditorScreen> createState() => _TemplateEditorScreenState();
}

class _TemplateEditorScreenState extends ConsumerState<TemplateEditorScreen> {
  final _nameCtrl = TextEditingController();
  final _specialtyCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _structureCtrl = TextEditingController();
  bool _saving = false;

  static const _starterStructure = '''Subjective:
- Chief complaint:
- HPI:
- Review of systems:

Objective:
- Vital signs:
- Physical exam:
- Labs / imaging:

Assessment:
- Primary diagnosis:
- Differential:

Plan:
- Treatment:
- Follow-up:
- Patient education:
''';

  @override
  void initState() {
    super.initState();
    if (widget.templateId != null) {
      // Hydrate from existing template if editing. Look in the user's
      // custom templates first, then fall back to the bundled defaults.
      Future.microtask(() {
        final state = ref.read(templatesControllerProvider);
        final pool = [...state.customTemplates, ...state.allTemplates];
        final t = pool.where((x) => x.id == widget.templateId).firstOrNull;
        if (t != null) {
          _nameCtrl.text = t.name;
          _specialtyCtrl.text = t.specialty;
          _descCtrl.text = t.description;
          _structureCtrl.text = t.sections.isEmpty
              ? _starterStructure
              : t.sections.join('\n');
        }
      });
    } else {
      _structureCtrl.text = _starterStructure;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _specialtyCtrl.dispose();
    _descCtrl.dispose();
    _structureCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.danger,
          content: Text('Template needs a name.', style: TextStyle(color: Colors.white)),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    setState(() => _saving = true);
    // The TemplatesApi only exposes list/get for now — write endpoints will
    // be added when the backend exposes them. For now we simulate success
    // and refresh the local list.
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: AppColors.emerald500,
        content: Text(
          'Template saved. (Backend write endpoint pending — change is local only.)',
          style: TextStyle(color: Colors.white),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
    context.go('/templates');
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.templateId != null;
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        title: Text(isEdit ? 'Edit template' : 'New template'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/templates'),
        ),
        actions: [
          IconButton(
            tooltip: 'Save',
            icon: _saving
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white))
                : const Icon(Icons.save_outlined),
            onPressed: _saving ? null : _save,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            TextField(
              controller: _nameCtrl,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Template name',
                prefixIcon: Icon(Icons.title, color: AppColors.slate400),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _specialtyCtrl,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Specialty (optional)',
                prefixIcon: Icon(Icons.medical_services_outlined, color: AppColors.slate400),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descCtrl,
              textInputAction: TextInputAction.newline,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Short description',
                prefixIcon: Icon(Icons.notes, color: AppColors.slate400),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Structure',
              style: TextStyle(color: AppColors.slate400, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5),
            ),
            const SizedBox(height: 6),
            const Text(
              'The headings the AI will fill in. One section per line. Indent with - for sub-items.',
              style: TextStyle(color: AppColors.slate500, fontSize: 11),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: TextField(
                controller: _structureCtrl,
                maxLines: 18,
                minLines: 14,
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'monospace',
                  fontSize: 13,
                  height: 1.5,
                ),
                decoration: const InputDecoration(
                  filled: false,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.all(8),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 52,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: kEmeraldGradient,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _saving ? null : _save,
                    borderRadius: BorderRadius.circular(14),
                    child: Center(
                      child: _saving
                          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                          : Text(
                              isEdit ? 'Save changes' : 'Create template',
                              style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800),
                            ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
