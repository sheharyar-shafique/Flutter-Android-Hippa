import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_theme.dart';

class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

  static const _faqs = <_Faq>[
    _Faq(
      q: 'How accurate is the AI transcription?',
      a: 'Pronote averages 92.5% transcription accuracy on clinical vocabulary. '
          'You can always edit the generated note before signing — the AI is a draft, '
          'never the final record.',
    ),
    _Faq(
      q: 'How long can I record a single visit?',
      a: 'Up to 2 hours of continuous recording per visit. The app warns you '
          'at 1 hour 55 minutes and stops automatically at 2 hours to keep '
          'individual files manageable.',
    ),
    _Faq(
      q: 'Is patient data HIPAA-protected?',
      a: 'Yes. All audio and clinical notes are encrypted in transit (TLS 1.3) '
          'and at rest (AES-256). We sign a Business Associate Agreement (BAA) '
          'with every paid plan. Cloud backup is disabled at the OS level so '
          'PHI never leaks to Google Drive.',
    ),
    _Faq(
      q: 'Can I use Pronote offline?',
      a: 'You can record visits offline — the app caches recordings locally '
          'and uploads when reconnected. Note generation and dictation require '
          'a network connection.',
    ),
    _Faq(
      q: 'How do I switch templates per visit?',
      a: 'Open the Templates screen from the drawer, browse the 30+ specialty '
          'templates, or create a custom one. When you start a new Capture '
          'session you can pick which template to use for that note.',
    ),
    _Faq(
      q: 'How do I delete my account?',
      a: 'Settings → Danger zone → Delete my account. You will be asked to '
          'confirm by typing your account email. Deletion is permanent and '
          'completes within minutes. Anonymised audit records are retained '
          'for 7 years per HIPAA recordkeeping rules.',
    ),
    _Faq(
      q: 'My recording is stuck on "Processing" — what should I do?',
      a: 'Generation usually takes 30–60 seconds. If it stays processing for '
          'more than 5 minutes, pull-to-refresh on the note. If still stuck, '
          'email support@pronoteai.com with the note ID.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        title: const Text('Help center'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/dashboard'),
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
                    AppColors.emerald500.withValues(alpha: 0.16),
                    AppColors.teal500.withValues(alpha: 0.08),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.emerald500.withValues(alpha: 0.3)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.support_agent, color: AppColors.emerald400),
                      SizedBox(width: 8),
                      Text(
                        'Need a hand?',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Email support@pronoteai.com — most questions answered the same business day.',
                    style: TextStyle(color: AppColors.slate400, fontSize: 13, height: 1.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Padding(
              padding: EdgeInsets.only(left: 4, bottom: 8),
              child: Text(
                'FAQ',
                style: TextStyle(color: AppColors.slate400, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.0),
              ),
            ),
            ..._faqs.map((f) => _FaqTile(faq: f)),
            const SizedBox(height: 20),
            const Padding(
              padding: EdgeInsets.only(left: 4, bottom: 8),
              child: Text(
                'RESOURCES',
                style: TextStyle(color: AppColors.slate400, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.0),
              ),
            ),
            _LinkTile(
              icon: Icons.menu_book_outlined,
              label: 'Documentation',
              sub: 'pronoteai.com/docs',
              url: 'https://pronoteai.com/docs',
            ),
            _LinkTile(
              icon: Icons.privacy_tip_outlined,
              label: 'Privacy policy',
              sub: 'pronoteai.com/privacy',
              url: 'https://pronoteai.com/privacy',
            ),
            _LinkTile(
              icon: Icons.shield_outlined,
              label: 'HIPAA Business Associate Agreement',
              sub: 'pronoteai.com/hipaa-baa',
              url: 'https://pronoteai.com/hipaa-baa',
            ),
            _LinkTile(
              icon: Icons.email_outlined,
              label: 'Email support',
              sub: 'support@pronoteai.com',
              url: 'mailto:support@pronoteai.com',
            ),
          ],
        ),
      ),
    );
  }
}

class _Faq {
  final String q;
  final String a;
  const _Faq({required this.q, required this.a});
}

class _FaqTile extends StatelessWidget {
  final _Faq faq;
  const _FaqTile({required this.faq});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Theme(
          data: Theme.of(context).copyWith(
            dividerColor: Colors.transparent,
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
          ),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            iconColor: AppColors.emerald400,
            collapsedIconColor: AppColors.slate400,
            title: Text(
              faq.q,
              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700),
            ),
            children: [
              Text(
                faq.a,
                style: const TextStyle(color: AppColors.slate400, fontSize: 13, height: 1.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LinkTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sub;
  final String url;

  const _LinkTile({required this.icon, required this.label, required this.sub, required this.url});

  Future<void> _open() async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: _open,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.info.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: AppColors.info, size: 17),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text(sub, style: const TextStyle(color: AppColors.slate400, fontSize: 11)),
                    ],
                  ),
                ),
                const Icon(Icons.open_in_new, size: 16, color: AppColors.slate400),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
