import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/api/api_client.dart';
import '../../core/api/users_api.dart';
import '../../core/theme/app_theme.dart';
import '../auth/auth_controller.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/dashboard'),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            if (user != null) _ProfileCard(name: user.name, email: user.email, specialty: user.specialty, initial: user.initial),
            const SizedBox(height: 18),
            const _SectionHeader(title: 'Subscription'),
            _SettingsTile(
              icon: Icons.workspace_premium_outlined,
              label: user?.subscriptionPlan?.replaceAll('_', ' ').toUpperCase() ?? 'No active plan',
              sub: user?.isTrial == true && user?.trialDaysLeft != null
                  ? '${user!.trialDaysLeft} day${user.trialDaysLeft == 1 ? '' : 's'} left in trial'
                  : (user?.subscriptionStatus ?? '—'),
              color: AppColors.warning,
              onTap: () => _openExternal('https://pronoteai.com/dashboard?manage=subscription'),
            ),

            const SizedBox(height: 18),
            const _SectionHeader(title: 'Account'),
            _SettingsTile(
              icon: Icons.lock_outline,
              label: 'Change password',
              color: AppColors.info,
              onTap: () => _showChangePassword(context, ref),
            ),
            _SettingsTile(
              icon: Icons.privacy_tip_outlined,
              label: 'Privacy policy',
              color: AppColors.info,
              onTap: () => context.go('/privacy'),
            ),
            _SettingsTile(
              icon: Icons.description_outlined,
              label: 'Terms of service',
              color: AppColors.info,
              onTap: () => context.go('/terms'),
            ),
            _SettingsTile(
              icon: Icons.shield_outlined,
              label: 'HIPAA Business Associate Agreement',
              color: AppColors.emerald400,
              onTap: () => context.go('/hipaa-baa'),
            ),

            const SizedBox(height: 18),
            const _SectionHeader(title: 'Session'),
            _SettingsTile(
              icon: Icons.logout,
              label: 'Sign out',
              color: AppColors.warning,
              onTap: () async {
                await ref.read(authControllerProvider.notifier).logout();
                if (context.mounted) context.go('/login');
              },
            ),

            const SizedBox(height: 32),
            const _SectionHeader(title: 'Danger zone', danger: true),
            _SettingsTile(
              icon: Icons.delete_forever,
              label: 'Delete my account',
              sub: 'Permanently removes your account and all PHI',
              color: AppColors.danger,
              danger: true,
              onTap: () => _confirmDeleteAccount(context, ref),
            ),

            const SizedBox(height: 32),
            const Center(
              child: Text(
                'Pronote — AI Medical Scribe • v1.0.0',
                style: TextStyle(color: AppColors.slate500, fontSize: 11),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openExternal(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _showChangePassword(BuildContext context, WidgetRef ref) async {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    bool busy = false;
    String? error;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          backgroundColor: AppColors.slate800,
          title: const Text('Change password', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: currentCtrl,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Current password'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: newCtrl,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'New password (8+ chars)'),
              ),
              if (error != null) ...[
                const SizedBox(height: 10),
                Text(error!, style: const TextStyle(color: AppColors.danger, fontSize: 12)),
              ],
            ],
          ),
          actions: [
            TextButton(onPressed: busy ? null : () => Navigator.pop(ctx), child: const Text('Cancel')),
            TextButton(
              onPressed: busy
                  ? null
                  : () async {
                      if (newCtrl.text.length < 8) {
                        setSt(() => error = 'New password must be at least 8 characters.');
                        return;
                      }
                      setSt(() {
                        busy = true;
                        error = null;
                      });
                      try {
                        await ref.read(usersApiProvider).changePassword(
                              currentPassword: currentCtrl.text,
                              newPassword: newCtrl.text,
                            );
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              backgroundColor: AppColors.emerald500,
                              content: Text('Password updated.', style: TextStyle(color: Colors.white)),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      } on ApiException catch (e) {
                        setSt(() {
                          busy = false;
                          error = e.message;
                        });
                      }
                    },
              child: busy
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.2, color: AppColors.emerald400))
                  : const Text('Update', style: TextStyle(color: AppColors.emerald400, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDeleteAccount(BuildContext context, WidgetRef ref) async {
    final user = ref.read(authControllerProvider).user;
    if (user == null) return;

    final confirmCtrl = TextEditingController();
    bool busy = false;
    String? error;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          backgroundColor: AppColors.slate800,
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: AppColors.danger),
              SizedBox(width: 8),
              Text('Delete account?', style: TextStyle(color: Colors.white)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'This permanently removes your account, all clinical notes, audio recordings, '
                'patient data, templates, and authentication tokens.\n\n'
                'Anonymised billing/audit records may be retained up to 7 years for HIPAA compliance.\n\n'
                'This cannot be undone.',
                style: TextStyle(color: AppColors.slate400, fontSize: 13, height: 1.5),
              ),
              const SizedBox(height: 16),
              Text('Type your email (${user.email}) to confirm:', style: const TextStyle(color: AppColors.slate400, fontSize: 12)),
              const SizedBox(height: 6),
              TextField(
                controller: confirmCtrl,
                decoration: const InputDecoration(hintText: 'your.email@example.com'),
              ),
              if (error != null) ...[
                const SizedBox(height: 8),
                Text(error!, style: const TextStyle(color: AppColors.danger, fontSize: 12)),
              ],
            ],
          ),
          actions: [
            TextButton(onPressed: busy ? null : () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            TextButton(
              onPressed: busy
                  ? null
                  : () async {
                      if (confirmCtrl.text.trim().toLowerCase() != user.email.toLowerCase()) {
                        setSt(() => error = "Email doesn't match.");
                        return;
                      }
                      setSt(() {
                        busy = true;
                        error = null;
                      });
                      try {
                        await ref.read(usersApiProvider).deleteAccount(confirmEmail: confirmCtrl.text.trim());
                        if (ctx.mounted) Navigator.pop(ctx, true);
                      } on ApiException catch (e) {
                        setSt(() {
                          busy = false;
                          error = e.message;
                        });
                      }
                    },
              child: busy
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.2, color: AppColors.danger))
                  : const Text('Delete forever', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );

    if (ok == true) {
      await ref.read(authControllerProvider.notifier).logout();
      if (context.mounted) context.go('/login');
    }
  }
}

class _ProfileCard extends StatelessWidget {
  final String name;
  final String email;
  final String? specialty;
  final String initial;

  const _ProfileCard({required this.name, required this.email, required this.specialty, required this.initial});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.emerald500.withValues(alpha: 0.18),
            AppColors.teal500.withValues(alpha: 0.10),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.emerald500.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: kEmeraldGradient,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Center(
              child: Text(
                initial,
                style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(email, style: const TextStyle(color: AppColors.slate400, fontSize: 12)),
                if (specialty != null && specialty!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.emerald500.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      specialty!,
                      style: const TextStyle(color: AppColors.emerald400, fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final bool danger;
  const _SectionHeader({required this.title, this.danger = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: danger ? AppColors.danger : AppColors.slate500,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? sub;
  final Color color;
  final VoidCallback onTap;
  final bool danger;

  const _SettingsTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.sub,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: danger ? AppColors.danger.withValues(alpha: 0.4) : AppColors.cardBorder,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          color: danger ? AppColors.danger : Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (sub != null) ...[
                        const SizedBox(height: 2),
                        Text(sub!, style: const TextStyle(color: AppColors.slate400, fontSize: 12)),
                      ],
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: danger ? AppColors.danger : AppColors.slate400),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
