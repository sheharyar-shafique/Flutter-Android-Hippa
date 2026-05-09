import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/template.dart';
import '../../core/theme/app_theme.dart';
import 'templates_controller.dart';

// ── Section data model ──────────────────────────────────────────
class _EditorSection {
  String title;
  String verbosity; // 'concise' | 'detailed'
  String styling;   // 'paragraph' | 'bullet'
  String content;
  String stylingInstructions;
  bool includeInCopyAll;
  bool showAdvanced;

  _EditorSection({
    required this.title,
    this.verbosity = 'detailed',
    this.styling = 'bullet',
    this.content = '',
    this.stylingInstructions = '',
    this.includeInCopyAll = true,
    this.showAdvanced = false,
  });
}

// Default content hints
const _defaultContent = <String, String>{
  'Subjective': "The patient's reported symptoms and medical history.",
  'Objective':
      'Any observable and measurable findings about the patient from the conversation.\n\nInclude the following subsections if relevant:\nVital Signs\nPhysical Exam Results\nDiagnostic Test Results and Labs',
  'Assessment':
      'Combine subjective and objective data to list detailed diagnoses.\nFor each diagnosis - begin with the diagnosis title, followed by its assessment.',
  'Plan': 'For each diagnosis listed in the assessment, provide a detailed plan.',
  'Chief Complaint': 'The primary reason the patient is seeking care today.',
  'HPI': "A detailed narrative of the patient's present illness.",
  'Review of Systems': 'Systematic review of body systems relevant to the chief complaint.',
  'Physical Exam': 'Documented findings from the physical examination.',
  'Medical Decision Making': 'Clinical reasoning supporting the diagnosis and treatment plan.',
  'Follow-Up': 'Instructions for follow-up care and next steps.',
  'Patient Instructions':
      'Compose a detailed and well-structured formal email from the doctor to the patient, summarizing the consultation and providing comprehensive care and treatment instructions.',
};

const _paragraphSections = {'Subjective', 'Chief Complaint', 'HPI', 'Medical Decision Making'};

_EditorSection _makeSection(String title) => _EditorSection(
      title: title,
      styling: _paragraphSections.contains(title) ? 'paragraph' : 'bullet',
      content: _defaultContent[title] ?? '',
    );

// ── Violet accent colour ────────────────────────────────────────
const _violet = Color(0xFF8B5CF6);
const _violetLight = Color(0xFFA78BFA);

// ── Main screen ─────────────────────────────────────────────────
class TemplateEditorScreen extends ConsumerStatefulWidget {
  final String? templateId;
  const TemplateEditorScreen({super.key, this.templateId});

  @override
  ConsumerState<TemplateEditorScreen> createState() => _TemplateEditorScreenState();
}

class _TemplateEditorScreenState extends ConsumerState<TemplateEditorScreen> {
  final _nameCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  late List<_EditorSection> _sections;
  bool _saving = false;
  String? _originalName;

  bool get _isEdit => widget.templateId != null;

  @override
  void initState() {
    super.initState();
    _sections = [];
    if (_isEdit) {
      Future.microtask(() {
        final state = ref.read(templatesControllerProvider);
        final pool = [...state.customTemplates, ...state.allTemplates];
        final t = pool.where((x) => x.id == widget.templateId).firstOrNull;
        if (t != null) {
          _originalName = t.name;
          _nameCtrl.text = '${t.name} - Copy';
          setState(() {
            _sections = (t.sections.isEmpty
                    ? ['Subjective', 'Objective', 'Assessment', 'Plan']
                    : t.sections)
                .map(_makeSection)
                .toList();
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _moveUp(int i) {
    if (i == 0) return;
    setState(() {
      final tmp = _sections[i - 1];
      _sections[i - 1] = _sections[i];
      _sections[i] = tmp;
    });
  }

  void _moveDown(int i) {
    if (i >= _sections.length - 1) return;
    setState(() {
      final tmp = _sections[i + 1];
      _sections[i + 1] = _sections[i];
      _sections[i] = tmp;
    });
  }

  void _deleteSection(int i) => setState(() => _sections.removeAt(i));

  void _addSection() {
    setState(() => _sections.add(_makeSection('New Section')));
    Future.delayed(const Duration(milliseconds: 100), () {
      _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent + 200,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      _toast('Template name is required', AppColors.danger);
      return;
    }
    if (_sections.isEmpty) {
      _toast('Add at least one section', AppColors.danger);
      return;
    }
    setState(() => _saving = true);

    // Build a real NoteTemplate and persist via controller
    final template = NoteTemplate(
      id: 'custom-${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      description: _isEdit
          ? 'Custom version based on ${_originalName ?? 'a template'}'
          : 'Custom template',
      specialty: 'Custom',
      sections: _sections.map((s) => s.title).toList(),
      isCustom: true,
      updatedAt: DateTime.now(),
    );

    await ref.read(templatesControllerProvider.notifier).upsertCustom(template);

    if (!mounted) return;
    setState(() => _saving = false);
    _toast('"$name" saved and added to My Templates!', AppColors.emerald500);
    context.go('/templates');
  }

  void _toast(String msg, Color c) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(backgroundColor: c, content: Text(msg, style: const TextStyle(color: Colors.white)), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SafeArea(
        child: Column(
          children: [
            // ── Back button ──
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  style: TextButton.styleFrom(foregroundColor: _violetLight, padding: const EdgeInsets.symmetric(horizontal: 8)),
                  onPressed: () => context.go('/templates'),
                  icon: const Icon(Icons.arrow_back, size: 16),
                  label: const Text('Back to Templates', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                ),
              ),
            ),

            // ── Scrollable body ──
            Expanded(
              child: ListView(
                controller: _scrollCtrl,
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                children: [
                  // Heading
                  Text(_isEdit ? 'Edit Template' : 'Create Template',
                      style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                  const SizedBox(height: 6),
                  if (_isEdit)
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(color: AppColors.slate400, fontSize: 13, height: 1.5),
                        children: [
                          const TextSpan(text: 'This will create a new version of the template following your edits. The original '),
                          TextSpan(text: '"${_originalName ?? 'template'}"', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                          const TextSpan(text: ' template will remain available.'),
                        ],
                      ),
                    )
                  else
                    const Text('Create your own template by adding and customizing sections.',
                        style: TextStyle(color: AppColors.slate400, fontSize: 13, height: 1.5)),

                  const SizedBox(height: 20),

                  // Walkthrough card
                  _WalkthroughCard(),

                  const SizedBox(height: 20),

                  // Template Name
                  const Text('Template Name', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  _field(_nameCtrl, 'e.g., SOAP Note - Copy'),

                  const SizedBox(height: 24),

                  // Section cards
                  for (int i = 0; i < _sections.length; i++) ...[
                    _SectionCard(
                      section: _sections[i],
                      index: i,
                      total: _sections.length,
                      onMoveUp: () => _moveUp(i),
                      onMoveDown: () => _moveDown(i),
                      onDelete: () => _deleteSection(i),
                      onChanged: () => setState(() {}),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Add Section
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: _addSection,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0x26FFFFFF), width: 2, strokeAlign: BorderSide.strokeAlignCenter),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add, color: AppColors.slate400, size: 16),
                            SizedBox(width: 6),
                            Text('Add Section', style: TextStyle(color: AppColors.slate400, fontSize: 13, fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Action buttons
                  Row(
                    children: [
                      // Cancel
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: OutlinedButton(
                            onPressed: () => context.go('/templates'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.slate300,
                              side: const BorderSide(color: Color(0x33FFFFFF)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w700)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Save
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [_violet, Color(0xFF7C3AED)]),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [BoxShadow(color: _violet.withValues(alpha: 0.35), blurRadius: 18, offset: const Offset(0, 6))],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(14),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(14),
                                onTap: _saving ? null : _save,
                                child: Center(
                                  child: _saving
                                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white))
                                      : const Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.save_outlined, size: 15, color: Colors.white),
                                            SizedBox(width: 6),
                                            Text('Save Template', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800)),
                                          ],
                                        ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String hint) {
    return TextField(
      controller: ctrl,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.slate500, fontSize: 14),
        filled: true,
        fillColor: const Color(0x0DFFFFFF),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0x1FFFFFFF))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0x1FFFFFFF))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: _violet.withValues(alpha: 0.5), width: 1.5)),
      ),
    );
  }
}

// ── Walkthrough card ────────────────────────────────────────────
class _WalkthroughCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0x0AFFFFFF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0x1AFFFFFF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Template Creation Walkthrough',
              style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          _step(Icons.layers_outlined, 1, 'Add sections to your template',
              'This will determine the structure of your note and how information is organized.'),
          const SizedBox(height: 14),
          _step(Icons.tune, 2, 'Define style and verbosity',
              'Match each section to your documentation preferences.'),
          const SizedBox(height: 14),
          _step(Icons.description_outlined, 3, 'Use content instructions',
              'Guide what should be included in each section for clarity and consistency.'),
          const SizedBox(height: 14),
          Container(height: 1, color: const Color(0x14FFFFFF)),
          const SizedBox(height: 12),
          const Center(
            child: Text('For examples and additional guidance, visit our Help Center.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.slate500, fontSize: 11.5)),
          ),
        ],
      ),
    );
  }

  Widget _step(IconData icon, int num, String title, String desc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: _violet.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _violet.withValues(alpha: 0.3)),
          ),
          child: Icon(icon, size: 15, color: _violetLight),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$num. $title', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(desc, style: const TextStyle(color: AppColors.slate500, fontSize: 11.5, height: 1.4)),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Section card ────────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  final _EditorSection section;
  final int index;
  final int total;
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;
  final VoidCallback onDelete;
  final VoidCallback onChanged;

  const _SectionCard({
    required this.section,
    required this.index,
    required this.total,
    required this.onMoveUp,
    required this.onMoveDown,
    required this.onDelete,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0x0AFFFFFF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0x1AFFFFFF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row: title + move/delete buttons
          Row(
            children: [
              Expanded(
                child: Text(section.title,
                    style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
              ),
              _iconBtn(Icons.arrow_upward, index > 0, onMoveUp),
              _iconBtn(Icons.arrow_downward, index < total - 1, onMoveDown),
              _deleteBtn(onDelete),
            ],
          ),
          const SizedBox(height: 16),

          // Section Title
          _label('SECTION TITLE'),
          const SizedBox(height: 6),
          _titleField(),
          const SizedBox(height: 16),

          // Verbosity
          _label('VERBOSITY'),
          const SizedBox(height: 6),
          _toggle(
            left: 'Concise',
            right: 'Detailed',
            leftIcon: Icons.short_text,
            rightIcon: Icons.chat_bubble_outline,
            value: section.verbosity,
            leftValue: 'concise',
            rightValue: 'detailed',
            onChanged: (v) {
              section.verbosity = v;
              onChanged();
            },
          ),
          const SizedBox(height: 16),

          // Styling
          _label('STYLING'),
          const SizedBox(height: 6),
          _toggle(
            left: 'Paragraph',
            right: 'Bullet points',
            leftIcon: Icons.subject,
            rightIcon: Icons.format_list_bulleted,
            value: section.styling,
            leftValue: 'paragraph',
            rightValue: 'bullet',
            onChanged: (v) {
              section.styling = v;
              onChanged();
            },
          ),
          const SizedBox(height: 16),

          // Section Content
          Row(
            children: [
              _label('SECTION CONTENT'),
              const SizedBox(width: 4),
              const Icon(Icons.help_outline, size: 12, color: AppColors.slate600),
            ],
          ),
          const SizedBox(height: 6),
          _contentField(section.content, (v) {
            section.content = v;
            onChanged();
          }),
          const SizedBox(height: 10),

          // Advanced Settings
          _advancedToggle(),

          if (section.showAdvanced) ...[
            const SizedBox(height: 12),
            _label('OPTIONAL STYLING INSTRUCTIONS'),
            const SizedBox(height: 6),
            _contentField(section.stylingInstructions, (v) {
              section.stylingInstructions = v;
              onChanged();
            }, hint: 'e.g., Use numbered headings for each diagnosis title.', lines: 3),
            const SizedBox(height: 12),
            // Include in Copy All toggle
            Row(
              children: [
                GestureDetector(
                  onTap: () {
                    section.includeInCopyAll = !section.includeInCopyAll;
                    onChanged();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 40,
                    height: 22,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(11),
                      color: section.includeInCopyAll ? _violet : const Color(0x33FFFFFF),
                    ),
                    child: AnimatedAlign(
                      duration: const Duration(milliseconds: 200),
                      alignment: section.includeInCopyAll ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        width: 18,
                        height: 18,
                        margin: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                const Text('Include in "Copy all"', style: TextStyle(color: AppColors.slate300, fontSize: 13)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _label(String text) {
    return Text(text,
        style: const TextStyle(
            color: AppColors.slate300, fontSize: 10.5, fontWeight: FontWeight.w800, letterSpacing: 1));
  }

  Widget _iconBtn(IconData icon, bool enabled, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: enabled ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, size: 15, color: enabled ? AppColors.slate400 : const Color(0x20FFFFFF)),
        ),
      ),
    );
  }

  Widget _deleteBtn(VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: const Padding(
          padding: EdgeInsets.all(8),
          child: Icon(Icons.delete_outline, size: 15, color: AppColors.slate400),
        ),
      ),
    );
  }

  Widget _titleField() {
    return TextFormField(
      initialValue: section.title,
      onChanged: (v) {
        section.title = v;
        onChanged();
      },
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: _inputDeco(null),
    );
  }

  Widget _contentField(String value, ValueChanged<String> setter, {String? hint, int lines = 4}) {
    return TextFormField(
      initialValue: value,
      onChanged: setter,
      maxLines: lines,
      minLines: lines,
      style: const TextStyle(color: AppColors.slate300, fontSize: 13, height: 1.55),
      decoration: _inputDeco(hint ?? 'Describe what should be captured in this section…'),
    );
  }

  InputDecoration _inputDeco(String? hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.slate600, fontSize: 13),
      filled: true,
      fillColor: const Color(0x0DFFFFFF),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0x1AFFFFFF))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0x1AFFFFFF))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: _violet.withValues(alpha: 0.5), width: 1.5)),
    );
  }

  Widget _toggle({
    required String left,
    required String right,
    required IconData leftIcon,
    required IconData rightIcon,
    required String value,
    required String leftValue,
    required String rightValue,
    required ValueChanged<String> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x1AFFFFFF)),
        color: const Color(0x08FFFFFF),
      ),
      child: Row(
        children: [
          _toggleHalf(left, leftIcon, value == leftValue, () => onChanged(leftValue), isLeft: true),
          _toggleHalf(right, rightIcon, value == rightValue, () => onChanged(rightValue), isLeft: false),
        ],
      ),
    );
  }

  Widget _toggleHalf(String label, IconData icon, bool active, VoidCallback onTap, {required bool isLeft}) {
    return Expanded(
      child: Material(
        color: active ? _violet : Colors.transparent,
        borderRadius: BorderRadius.horizontal(
          left: isLeft ? const Radius.circular(13) : Radius.zero,
          right: isLeft ? Radius.zero : const Radius.circular(13),
        ),
        child: InkWell(
          borderRadius: BorderRadius.horizontal(
            left: isLeft ? const Radius.circular(13) : Radius.zero,
            right: isLeft ? Radius.zero : const Radius.circular(13),
          ),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 11),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 14, color: active ? Colors.white : AppColors.slate400),
                const SizedBox(width: 6),
                Text(label,
                    style: TextStyle(
                        color: active ? Colors.white : AppColors.slate400,
                        fontSize: 13,
                        fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _advancedToggle() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {
          section.showAdvanced = !section.showAdvanced;
          onChanged();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                section.showAdvanced ? Icons.expand_less : Icons.expand_more,
                size: 14,
                color: _violetLight,
              ),
              const SizedBox(width: 4),
              const Text('Advanced Settings',
                  style: TextStyle(color: _violetLight, fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}
