import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import 'legal_scaffold.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const LegalScaffold(
      title: 'Terms of Service',
      subtitle: 'Effective: April 19, 2026',
      icon: Icons.description_outlined,
      accent: AppColors.warning,
      sections: [
        LegalSection(
          title: '1. Acceptance of Terms',
          paragraphs: [
            'By creating an account or using Pronote, you agree to these Terms of Service. If you do not agree, do not use the service.',
            'These terms constitute a legal agreement between you (or the entity you represent) and Pronote.',
          ],
        ),
        LegalSection(
          title: '2. Service Description',
          paragraphs: [
            'Pronote is an AI-powered clinical documentation platform that records patient encounters, generates structured clinical notes, and helps clinicians manage related workflows. Pronote is a documentation tool — it is not a medical device, does not provide clinical decision support, and does not replace clinician judgment.',
          ],
        ),
        LegalSection(
          title: '3. Eligibility',
          paragraphs: [
            'You must be a licensed healthcare professional or work under one to use Pronote with patient data. You are responsible for ensuring your use complies with state licensure rules and your employer\'s policies.',
          ],
        ),
        LegalSection(
          title: '4. Account Security',
          paragraphs: [
            'You are responsible for the confidentiality of your account credentials and for all activity under your account. Notify us immediately at support@pronoteai.com if you suspect unauthorised access. We support optional 2-factor authentication and recommend enabling it for clinical accounts.',
          ],
        ),
        LegalSection(
          title: '5. Acceptable Use',
          paragraphs: ['You agree NOT to:'],
          bullets: [
            'Upload audio that you do not have legal authority to record',
            'Reverse-engineer or attempt to extract our model weights',
            'Use Pronote for billing fraud, prior-auth gaming, or insurance abuse',
            'Share your account credentials with anyone outside your authorised practice',
            'Bypass HIPAA workflows by exporting raw audio outside the platform',
          ],
        ),
        LegalSection(
          title: '6. HIPAA Business Associate Agreement',
          paragraphs: [
            'Every paid plan includes a Business Associate Agreement (BAA). The BAA forms a separate legal document and governs how Pronote handles Protected Health Information (PHI) on your behalf. By accepting these terms on a paid plan, you also accept the BAA.',
          ],
        ),
        LegalSection(
          title: '7. Subscription and Billing',
          paragraphs: [
            'Paid plans bill monthly or annually via Stripe. The 7-day free trial starts automatically when you sign up and does not require a credit card. After trial expiry, the account is locked until a paid plan is activated. Refunds are evaluated case-by-case — contact support@pronoteai.com.',
          ],
        ),
        LegalSection(
          title: '8. Termination',
          paragraphs: [
            'You may delete your account at any time. We may suspend or terminate accounts that violate these terms, are involved in fraud, or for non-payment. Termination does not waive any obligations that survive by their nature (e.g., HIPAA BAA terms, indemnities).',
          ],
        ),
        LegalSection(
          title: '9. Disclaimers',
          paragraphs: [
            'Pronote is provided "as is". We make no warranties about the accuracy, completeness, or fitness of generated notes. Clinicians must always review and approve every note before signing.',
            'We do NOT guarantee 100% transcription accuracy. The AI produces a draft; the human clinician produces the medical record.',
          ],
        ),
        LegalSection(
          title: '10. Limitation of Liability',
          paragraphs: [
            'To the maximum extent permitted by law, Pronote\'s aggregate liability is limited to the fees you paid in the 12 months preceding the claim. We are not liable for indirect, incidental, or consequential damages.',
          ],
        ),
        LegalSection(
          title: '11. Governing Law',
          paragraphs: [
            'These terms are governed by the laws of the State of Delaware, USA, without regard to conflict-of-law principles. Disputes are resolved in the state or federal courts of Delaware.',
          ],
        ),
        LegalSection(
          title: '12. Contact',
          paragraphs: [
            'Questions about these terms: support@pronoteai.com',
          ],
        ),
      ],
    );
  }
}
