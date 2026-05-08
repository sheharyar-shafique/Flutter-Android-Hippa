import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import 'legal_scaffold.dart';

class HipaaBaaScreen extends StatelessWidget {
  const HipaaBaaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const LegalScaffold(
      title: 'HIPAA BAA',
      subtitle: 'Business Associate Agreement — included on every paid plan',
      icon: Icons.shield,
      accent: AppColors.emerald400,
      sections: [
        LegalSection(
          title: 'What this is',
          paragraphs: [
            'A Business Associate Agreement (BAA) is the legal contract HIPAA requires whenever a covered entity (you) shares Protected Health Information (PHI) with a service provider (Pronote). The BAA spells out exactly how PHI must be protected and what happens if something goes wrong.',
            'Pronote includes a BAA on every paid plan at no additional cost. You do not need to negotiate a custom contract or contact sales — it is automatic.',
          ],
        ),
        LegalSection(
          title: 'How we protect your PHI',
          paragraphs: ['Our BAA commits us to the following minimum controls:'],
          bullets: [
            'Encryption in transit (TLS 1.3) and at rest (AES-256, key-rotated quarterly)',
            'Audit logging of every access, edit, sign, and export action',
            'Access restricted to authenticated users on a need-to-know basis',
            'Incident response within 24 hours of detection',
            'Annual third-party security review',
            'Background-checked engineering staff',
            'No third-party AI training on your data — ever',
          ],
        ),
        LegalSection(
          title: 'Subprocessors under BAA',
          paragraphs: [
            'We only use subprocessors that have signed BAAs with us:',
          ],
          bullets: [
            'OpenAI — note generation (zero-retention API mode)',
            'Render — backend hosting (HIPAA-eligible plan)',
            'Stripe — billing only (no PHI sent)',
          ],
        ),
        LegalSection(
          title: 'Breach notification',
          paragraphs: [
            'If a security incident affects your PHI, we will notify you in writing within 24 hours of discovery, including:',
          ],
          bullets: [
            'What data was involved',
            'When and how the incident occurred',
            'What we have done to contain and remediate it',
            'What further actions, if any, you need to take',
          ],
        ),
        LegalSection(
          title: 'Termination and data return',
          paragraphs: [
            'On account termination you may export all your data via Settings → Export. Within 30 days of termination we permanently delete all PHI from active systems. Anonymised audit logs are retained per HIPAA recordkeeping rules (up to 7 years) and contain no identifiable patient information.',
          ],
        ),
        LegalSection(
          title: 'Reviewing the full BAA text',
          paragraphs: [
            'The full executed BAA is available in your account under Settings → Documents. If you need a custom BAA for an enterprise procurement process, contact enterprise@pronoteai.com.',
          ],
        ),
      ],
    );
  }
}
