import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_theme.dart';
import '../auth/auth_controller.dart';

class EnterpriseScreen extends ConsumerWidget {
  const EnterpriseScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authed = ref.watch(authControllerProvider).isAuthenticated;

    return Scaffold(
      backgroundColor: AppColors.bgDeep,
      appBar: AppBar(
        backgroundColor: AppColors.bgDeep,
        title: const Text('Enterprise'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(authed ? '/dashboard' : '/'),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  AppColors.warning.withValues(alpha: 0.16),
                  AppColors.emerald400.withValues(alpha: 0.08),
                ]),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('FOR HEALTH SYSTEMS',
                        style: TextStyle(color: AppColors.warning, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1)),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Pronote\nat scale.',
                    style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w900, height: 1.1, letterSpacing: -0.6),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'For groups of 50+ clinicians, multi-site practices, and health systems with enterprise procurement, security, and integration requirements.',
                    style: TextStyle(color: AppColors.slate400, fontSize: 14, height: 1.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            _BulletGroup(
              title: 'Security & compliance',
              items: const [
                'SOC 2 Type II ready (audit on request)',
                'SAML / Okta / Azure AD SSO',
                'Custom BAA with dedicated security review',
                'Audit log streaming to your SIEM (Splunk, Datadog)',
                'Optional on-premise deployment for self-hosted clinics',
              ],
              accent: AppColors.info,
              icon: Icons.shield_outlined,
            ),
            _BulletGroup(
              title: 'EHR integrations',
              items: const [
                'Epic (App Orchard)',
                'Cerner / Oracle Health (CareAware)',
                'athenaOne, NextGen, eClinicalWorks',
                'FHIR R4 + HL7 v2 connectors',
                'Custom EHR connectors via your IT team',
              ],
              accent: AppColors.emerald400,
              icon: Icons.link,
            ),
            _BulletGroup(
              title: 'Account team',
              items: const [
                'Dedicated account manager (named human)',
                '24/7 priority support, < 2h response SLA',
                'White-glove rollout: training sessions for every clinician',
                'Quarterly business reviews + product roadmap input',
              ],
              accent: const Color(0xFFA78BFA),
              icon: Icons.support_agent,
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Talk to sales',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  const Text(
                    'Get a tailored proposal, security questionnaire, and pilot timeline within 48 hours.',
                    style: TextStyle(color: AppColors.slate400, fontSize: 13, height: 1.5),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: kEmeraldGradient,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () async {
                            final uri = Uri.parse('mailto:enterprise@pronoteai.com?subject=Pronote%20Enterprise%20Inquiry');
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri);
                            }
                          },
                          child: const Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.email_outlined, color: Colors.white, size: 18),
                                SizedBox(width: 8),
                                Text('Email enterprise@pronoteai.com',
                                    style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
                              ],
                            ),
                          ),
                        ),
                      ),
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
}

class _BulletGroup extends StatelessWidget {
  final String title;
  final List<String> items;
  final Color accent;
  final IconData icon;

  const _BulletGroup({required this.title, required this.items, required this.accent, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: accent, size: 17),
                ),
                const SizedBox(width: 10),
                Text(title,
                    style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)),
              ],
            ),
            const SizedBox(height: 10),
            ...items.map((i) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.check_circle_outline, color: accent, size: 16),
                      const SizedBox(width: 8),
                      Expanded(child: Text(i, style: const TextStyle(color: Colors.white, fontSize: 13.5))),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
