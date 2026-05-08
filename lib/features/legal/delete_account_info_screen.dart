import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../auth/auth_controller.dart';
import 'legal_scaffold.dart';

/// Public-facing account-deletion info page (HIPAA / Play Store requirement).
/// Mirrors the web /delete-account page word-for-word so the URL path users
/// type into a browser and the screen they see in the app are consistent.
class DeleteAccountInfoScreen extends ConsumerWidget {
  const DeleteAccountInfoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authed = ref.watch(authControllerProvider).isAuthenticated;
    return Stack(
      children: [
        const LegalScaffold(
          title: 'Delete your account',
          subtitle: 'Pronote — AI Medical Scribe',
          icon: Icons.delete_outline,
          accent: AppColors.danger,
          sections: [
            LegalSection(
              title: 'Method 1 — Delete from inside the app',
              paragraphs: [
                'Sign in, open Settings from the drawer, scroll to Danger zone, and tap Delete account. You will be asked to type your email to confirm.',
                'Your account and all associated data are removed within minutes. You will receive a confirmation email when deletion completes.',
              ],
            ),
            LegalSection(
              title: 'Method 2 — Email request',
              paragraphs: [
                'If you cannot sign in, send a deletion request from the email address associated with your Pronote account to support@pronoteai.com with subject "Account deletion request".',
                'We will verify your identity and complete the deletion within 7 business days, in accordance with HIPAA recordkeeping requirements.',
              ],
            ),
            LegalSection(
              title: 'What is deleted',
              paragraphs: ['On account deletion we permanently remove:'],
              bullets: [
                'Your account profile (name, email, specialty, credentials)',
                'All audio recordings you have captured or uploaded',
                'All AI-generated clinical notes',
                'All patient identifiers and chart data you have entered',
                'Custom templates and saved preferences',
                'Authentication tokens and session history',
              ],
            ),
            LegalSection(
              title: 'What is retained (and why)',
              paragraphs: [
                'To meet legal, tax, and HIPAA recordkeeping obligations, we retain a limited set of data after account deletion:',
              ],
              bullets: [
                'Anonymised billing and audit records — retained for 7 years for tax and HIPAA audit-trail compliance. These records do not contain identifiable patient information.',
                'Aggregated, non-identifiable analytics — retained indefinitely to improve Pronote\'s reliability. These cannot be linked back to you or your patients.',
              ],
            ),
            LegalSection(
              title: 'Need help?',
              paragraphs: [
                'Email our privacy team at support@pronoteai.com if you have questions about deletion, data retention, or your rights under HIPAA, GDPR, or state privacy law.',
              ],
            ),
          ],
        ),
        if (authed)
          Positioned(
            left: 16,
            right: 16,
            bottom: 20,
            child: SafeArea(
              child: SizedBox(
                height: 54,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [AppColors.danger, Color(0xFFDC2626)]),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.danger.withValues(alpha: 0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => context.go('/settings'),
                      child: const Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.delete_forever, color: Colors.white),
                            SizedBox(width: 8),
                            Text('Open Settings to delete now',
                                style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
