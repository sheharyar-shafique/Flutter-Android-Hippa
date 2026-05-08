import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../auth/auth_controller.dart';

class AdminScreen extends ConsumerWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;
    final isAdmin = user?.isAdmin ?? false;

    if (!isAdmin) {
      return Scaffold(
        backgroundColor: AppColors.bgPrimary,
        appBar: AppBar(
          title: const Text('Admin'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/dashboard'),
          ),
        ),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_outline, color: AppColors.danger, size: 60),
                SizedBox(height: 12),
                Text('Admin access required',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                SizedBox(height: 6),
                Text(
                  'This area is restricted to accounts with the admin role.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.slate400, fontSize: 13),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        title: const Text('Admin'),
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
                gradient: LinearGradient(colors: [
                  AppColors.danger.withValues(alpha: 0.16),
                  AppColors.warning.withValues(alpha: 0.06),
                ]),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.shield, color: AppColors.danger),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'You are signed in with admin privileges. Actions taken here are audit-logged.',
                      style: TextStyle(color: Colors.white, fontSize: 13, height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const _AdminTile(icon: Icons.people_alt_outlined, label: 'Users', sub: 'Manage all clinician accounts'),
            const _AdminTile(icon: Icons.workspace_premium_outlined, label: 'Subscriptions', sub: 'Override plan, status, trial dates'),
            const _AdminTile(icon: Icons.list_alt, label: 'Audit log', sub: 'Every PHI access, edit, sign, export'),
            const _AdminTile(icon: Icons.shield_outlined, label: 'Compliance reports', sub: 'HIPAA breach notifications + 7-year audit retention'),
            const _AdminTile(icon: Icons.flag, label: 'Feature flags', sub: 'Toggle experimental features per account'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.10),
                border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.warning, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Admin write actions ship in the next backend release. The web Admin panel at pronoteai.com/admin remains the source of truth for now.',
                      style: TextStyle(color: Colors.white, fontSize: 12.5, height: 1.4),
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

class _AdminTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sub;
  const _AdminTile({required this.icon, required this.label, required this.sub});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, color: AppColors.danger, size: 19),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(sub, style: const TextStyle(color: AppColors.slate400, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.slate400, size: 20),
          ],
        ),
      ),
    );
  }
}
