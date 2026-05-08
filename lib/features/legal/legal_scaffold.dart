import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../auth/auth_controller.dart';

/// Shared layout used by Privacy, Terms, HIPAA BAA, and Delete-Account pages.
/// Header chooses the back destination based on whether the user is signed
/// in — an authenticated user sees "Back to Settings"; a guest sees
/// "Back to home".
class LegalScaffold extends ConsumerWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final List<LegalSection> sections;

  const LegalScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.sections,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authed = ref.watch(authControllerProvider).isAuthenticated;
    return Scaffold(
      backgroundColor: AppColors.bgDeep,
      appBar: AppBar(
        backgroundColor: AppColors.bgDeep,
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(authed ? '/settings' : '/'),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    accent.withValues(alpha: 0.16),
                    accent.withValues(alpha: 0.06),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: accent.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(icon, color: accent, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title,
                            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 4),
                        Text(subtitle,
                            style: const TextStyle(color: AppColors.slate400, fontSize: 12.5)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            ...sections.map((s) => _SectionView(section: s, accent: accent)),
            const SizedBox(height: 12),
            const Center(
              child: Text(
                'Pronote — AI Medical Scribe',
                style: TextStyle(color: AppColors.slate500, fontSize: 11),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LegalSection {
  final String title;
  final List<String> paragraphs;
  final List<String>? bullets;
  const LegalSection({required this.title, required this.paragraphs, this.bullets});
}

class _SectionView extends StatelessWidget {
  final LegalSection section;
  final Color accent;
  const _SectionView({required this.section, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 22,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [accent, accent.withValues(alpha: 0.4)]),
                  borderRadius: BorderRadius.circular(50),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  section.title,
                  style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...section.paragraphs.map((p) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  p,
                  style: const TextStyle(color: AppColors.slate400, fontSize: 13.5, height: 1.55),
                ),
              )),
          if (section.bullets != null) ...[
            const SizedBox(height: 4),
            ...section.bullets!.map((b) => Padding(
                  padding: const EdgeInsets.only(bottom: 6, left: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 6, right: 8),
                        child: Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
                        ),
                      ),
                      Expanded(
                        child: Text(b,
                            style: const TextStyle(color: AppColors.slate400, fontSize: 13.5, height: 1.55)),
                      ),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }
}
