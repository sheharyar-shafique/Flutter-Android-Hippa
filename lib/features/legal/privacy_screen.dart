import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import 'legal_scaffold.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const LegalScaffold(
      title: 'Privacy Policy',
      subtitle: 'Last updated: April 19, 2026',
      icon: Icons.shield_outlined,
      accent: AppColors.info,
      sections: [
        LegalSection(
          title: '1. Introduction',
          paragraphs: [
            'Pronote ("we," "our," or "us") is committed to protecting your privacy and the privacy of your patients. This Privacy Policy describes how we collect, use, disclose, and safeguard information when you use our AI medical scribe platform.',
            'As a healthcare technology platform, we are acutely aware of the sensitivity of medical data and have designed our systems with privacy and HIPAA compliance as core principles.',
          ],
        ),
        LegalSection(
          title: '2. Information We Collect',
          paragraphs: ['Account information:'],
          bullets: [
            'Full name, email address, and password (stored encrypted at rest)',
            'Medical specialty and professional credentials',
            'Billing and payment information (processed via Stripe — we never store card numbers)',
            'Account preferences and settings',
          ],
        ),
        LegalSection(
          title: '3. Clinical Content',
          paragraphs: [
            'When you use Pronote to capture a visit we collect:',
          ],
          bullets: [
            'Audio recordings you upload or capture for transcription',
            'AI-generated clinical notes and transcriptions',
            'Patient identifiers you enter (name, MRN, DOB, etc.)',
            'Note edits, custom templates, and documentation preferences',
          ],
        ),
        LegalSection(
          title: '4. How We Protect Your Data',
          paragraphs: [
            'All data is encrypted in transit (TLS 1.3) and at rest (AES-256). Audio files are stored in private application storage on the device and excluded from cloud backups. We sign a Business Associate Agreement (BAA) with every paid plan.',
            'Patient audio and notes are NEVER used to train any AI model. They live only in your account, encrypted, and are deleted when you delete your account.',
          ],
        ),
        LegalSection(
          title: '5. Data Retention',
          paragraphs: [
            'You can delete your account at any time from Settings → Danger zone. Account deletion is permanent and completes within minutes.',
            'Per HIPAA recordkeeping requirements we retain anonymised audit logs for up to 7 years after deletion. These records contain no identifiable patient information.',
          ],
        ),
        LegalSection(
          title: '6. Third-Party Services',
          paragraphs: [
            'Pronote uses a small number of vetted subprocessors under signed BAAs:',
          ],
          bullets: [
            'OpenAI for note generation (data is processed but not retained for training)',
            'Stripe for billing (PCI DSS Level 1 certified)',
            'Render for hosted backend infrastructure',
          ],
        ),
        LegalSection(
          title: '7. Your Rights',
          paragraphs: [
            'Under HIPAA, GDPR (where applicable), and state privacy laws, you have the right to access, correct, export, and delete your personal data. Contact our privacy team at support@pronoteai.com for any request — we respond within 7 business days.',
          ],
        ),
        LegalSection(
          title: '8. Changes to This Policy',
          paragraphs: [
            'We may update this policy periodically. Material changes will be communicated by email and surfaced in the app on next sign-in. Continued use after a change constitutes acceptance of the updated policy.',
          ],
        ),
        LegalSection(
          title: '9. Contact',
          paragraphs: [
            'Privacy questions: support@pronoteai.com\nMail: Pronote AI Medical Scribe, Privacy Office\nWebsite: pronoteai.com',
          ],
        ),
      ],
    );
  }
}
