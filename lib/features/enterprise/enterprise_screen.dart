import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_theme.dart';
import '../auth/auth_controller.dart';

class EnterpriseScreen extends ConsumerStatefulWidget {
  const EnterpriseScreen({super.key});
  @override
  ConsumerState<EnterpriseScreen> createState() => _EnterpriseScreenState();
}

class _EnterpriseScreenState extends ConsumerState<EnterpriseScreen> {
  final _specialtyCtrl = TextEditingController();
  final _terminologyCtrl = TextEditingController();
  final _phrasingCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() { _specialtyCtrl.dispose(); _terminologyCtrl.dispose(); _phrasingCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SafeArea(child: ListView(padding: const EdgeInsets.fromLTRB(20, 16, 20, 32), children: [
        // Header
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          GestureDetector(onTap: () => context.canPop() ? context.pop() : context.go('/dashboard'),
            child: Container(width: 36, height: 36, decoration: BoxDecoration(color: const Color(0x0DFFFFFF), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0x1AFFFFFF))),
              child: const Icon(Icons.arrow_back, color: Colors.white, size: 18))),
          const SizedBox(width: 12),
          Container(width: 44, height: 44, decoration: BoxDecoration(color: const Color(0xFFF59E0B).withValues(alpha: 0.18), borderRadius: BorderRadius.circular(14)),
            child: const Icon(Icons.star, color: Color(0xFFF59E0B), size: 22)),
          const SizedBox(width: 12),
          const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Enterprise Features', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
            Text('Exclusive tools included in your Group Annual plan', style: TextStyle(color: AppColors.slate400, fontSize: 12)),
          ])),
        ]),
        const SizedBox(height: 24),

        // ═══ Custom AI Training section ═══
        Row(children: [
          Container(width: 40, height: 40, decoration: BoxDecoration(color: AppColors.emerald400.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.psychology, color: AppColors.emerald400, size: 20)),
          const SizedBox(width: 12),
          const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Custom AI Training', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
            Text('Train the AI on your specialty-specific terminology and phrasing', style: TextStyle(color: AppColors.slate400, fontSize: 12)),
          ])),
        ]),
        const SizedBox(height: 16),

        // 3 feature pills
        Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
          decoration: BoxDecoration(color: const Color(0x0DFFFFFF), borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0x14FFFFFF))),
          child: Row(children: [
            _FeaturePill(emoji: '🎯', title: 'Specialty Vocabulary', sub: 'Medical terms specific to your field'),
            const SizedBox(width: 8),
            _FeaturePill(emoji: '💪', title: 'Preferred Phrasing', sub: 'How you like notes structured'),
            const SizedBox(width: 8),
            _FeaturePill(emoji: '⚡', title: 'Auto-corrections', sub: 'Common transcription fixes'),
          ]),
        ),
        const SizedBox(height: 16),

        // YOUR SPECIALTY
        const Text('YOUR SPECIALTY *', style: TextStyle(color: AppColors.slate300, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
        const SizedBox(height: 8),
        TextField(controller: _specialtyCtrl, style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: _inputDeco('e.g. Interventional Cardiology, Pediatric Neurology...')),
        const SizedBox(height: 18),

        // CUSTOM TERMINOLOGY
        const Text('CUSTOM TERMINOLOGY *', style: TextStyle(color: AppColors.slate300, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
        const SizedBox(height: 8),
        TextField(controller: _terminologyCtrl, maxLines: 5, style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: _inputDeco('List specialty-specific terms, abbreviations, drug names, or procedures — one per line. e.g.:\nTAVI (Transcatheter Aortic Valve Implantation)\nFFR (Fractional Flow Reserve)\nIVUS')),
        const SizedBox(height: 18),

        // PHRASING PREFERENCES
        Row(children: [
          const Text('PHRASING PREFERENCES ', style: TextStyle(color: AppColors.slate300, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
          Text('(optional)', style: TextStyle(color: AppColors.slate500, fontSize: 11)),
        ]),
        const SizedBox(height: 8),
        TextField(controller: _phrasingCtrl, maxLines: 3, style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: _inputDeco("Describe how you prefer notes to be formatted or phrased. e.g.: 'Always spell out medication names fully', 'Use past tense for history', 'Include laterality (left/right) explicitly'")),
        const SizedBox(height: 20),

        // Submit button
        GestureDetector(
          onTap: _submitting ? null : () async {
            if (_specialtyCtrl.text.trim().isEmpty || _terminologyCtrl.text.trim().isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill in specialty and terminology fields.'), behavior: SnackBarBehavior.floating, backgroundColor: AppColors.danger));
              return;
            }
            setState(() => _submitting = true);
            await Future.delayed(const Duration(seconds: 1));
            if (!mounted) return;
            setState(() => _submitting = false);
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Training request submitted!'), behavior: SnackBarBehavior.floating, backgroundColor: AppColors.emerald500));
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            decoration: BoxDecoration(gradient: kEmeraldGradient, borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: AppColors.emerald500.withValues(alpha: 0.35), blurRadius: 16, offset: const Offset(0, 6))]),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              _submitting
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.send, color: Colors.white, size: 16),
              const SizedBox(width: 8),
              const Text('Submit Training Request', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
            ]),
          ),
        ),
        const SizedBox(height: 30),

        // ═══ Dedicated Success Manager section ═══
        const Divider(color: Color(0x14FFFFFF), height: 1),
        const SizedBox(height: 24),
        Row(children: [
          Container(width: 40, height: 40, decoration: BoxDecoration(color: const Color(0xFFA855F7).withValues(alpha: 0.18), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.support_agent, color: Color(0xFFA855F7), size: 20)),
          const SizedBox(width: 12),
          const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Dedicated Success Manager', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
            Text('Your personal point of contact for onboarding, training, and strategy', style: TextStyle(color: AppColors.slate400, fontSize: 12)),
          ])),
        ]),
        const SizedBox(height: 16),

        // Manager card + services
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Manager profile
          Container(width: 130, padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: const Color(0x0DFFFFFF), borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0x14FFFFFF))),
            child: Column(children: [
              Container(width: 64, height: 64, decoration: BoxDecoration(color: const Color(0xFFA855F7).withValues(alpha: 0.2), borderRadius: BorderRadius.circular(16)),
                child: const Icon(Icons.person, color: Color(0xFFA855F7), size: 32)),
              const SizedBox(height: 10),
              const Text('Alex Morgan', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
              const Text('Enterprise Success Manager', style: TextStyle(color: AppColors.slate400, fontSize: 9), textAlign: TextAlign.center),
              const SizedBox(height: 10),
              GestureDetector(onTap: () => launchUrl(Uri.parse('mailto:enterprise@pronoteai.com')),
                child: Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 8), decoration: BoxDecoration(gradient: kEmeraldGradient, borderRadius: BorderRadius.circular(8)),
                  child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.send, color: Colors.white, size: 12), SizedBox(width: 4), Text('Email Me', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600))]))),
              const SizedBox(height: 6),
              Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 8), decoration: BoxDecoration(color: const Color(0x0DFFFFFF), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0x1AFFFFFF))),
                child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.open_in_new, color: AppColors.slate400, size: 12), SizedBox(width: 4), Text('Book a Call', style: TextStyle(color: AppColors.slate400, fontSize: 11, fontWeight: FontWeight.w600))])),
            ])),
          const SizedBox(width: 12),
          // Services list
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Your dedicated success manager is here to help you get the most out of Pronote. They handle everything from initial setup to ongoing optimization.',
                style: TextStyle(color: AppColors.slate400, fontSize: 12, height: 1.5)),
            const SizedBox(height: 14),
            _ServiceRow(icon: Icons.rocket_launch, color: const Color(0xFFEF4444), title: 'Onboarding & Setup', sub: 'Guided setup, team training sessions, and workflow optimization.'),
            _ServiceRow(icon: Icons.school, color: const Color(0xFFF59E0B), title: 'Staff Training', sub: 'Live training sessions for your entire clinical team.'),
            _ServiceRow(icon: Icons.assessment, color: AppColors.emerald400, title: 'Quarterly Business Reviews', sub: 'Usage analytics review and ROI reporting every quarter.'),
            _ServiceRow(icon: Icons.build, color: const Color(0xFFA855F7), title: 'Custom Configuration', sub: 'Help configuring templates, integrations, and AI settings.'),
            _ServiceRow(icon: Icons.phone, color: const Color(0xFFEF4444), title: 'Escalation Priority', sub: 'Direct escalation path bypassing standard support queues.'),
          ])),
        ]),
      ])),
    );
  }

  InputDecoration _inputDeco(String hint) => InputDecoration(
    hintText: hint, hintStyle: const TextStyle(color: AppColors.slate500, fontSize: 13), hintMaxLines: 5,
    filled: true, fillColor: const Color(0x0DFFFFFF),
    contentPadding: const EdgeInsets.all(16),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0x1AFFFFFF))),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0x1AFFFFFF))),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.emerald400.withValues(alpha: 0.5))),
  );
}

class _FeaturePill extends StatelessWidget {
  final String emoji, title, sub;
  const _FeaturePill({required this.emoji, required this.title, required this.sub});
  @override
  Widget build(BuildContext context) => Expanded(child: Column(children: [
    Text(emoji, style: const TextStyle(fontSize: 22)),
    const SizedBox(height: 6),
    Text(title, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700), textAlign: TextAlign.center),
    const SizedBox(height: 2),
    Text(sub, style: const TextStyle(color: AppColors.slate400, fontSize: 9), textAlign: TextAlign.center),
  ]));
}

class _ServiceRow extends StatelessWidget {
  final IconData icon; final Color color; final String title, sub;
  const _ServiceRow({required this.icon, required this.color, required this.title, required this.sub});
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 10), child: Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: const Color(0x08FFFFFF), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0x0AFFFFFF))),
    child: Row(children: [
      Container(width: 32, height: 32, decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: color, size: 16)),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
        Text(sub, style: const TextStyle(color: AppColors.slate500, fontSize: 11)),
      ])),
    ])));
}
