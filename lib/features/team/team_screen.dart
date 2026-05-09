import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../auth/auth_controller.dart';

class TeamScreen extends ConsumerWidget {
  const TeamScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;
    final isGroupPlan = (user?.subscriptionPlan ?? '').startsWith('group');

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        title: const Text('Team'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop() ? context.pop() : context.go('/dashboard'),
        ),
      ),
      body: SafeArea(
        child: !isGroupPlan
            ? _UpgradePrompt()
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.cardBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.groups, color: AppColors.emerald400, size: 30),
                        SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Your team', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
                              SizedBox(height: 4),
                              Text('Manage clinicians, roles, and seats.',
                                  style: TextStyle(color: AppColors.slate400, fontSize: 12.5)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _PlaceholderCard(
                    icon: Icons.person_add,
                    title: 'Invite clinicians',
                    sub: 'Send invites to colleagues to join your group plan',
                  ),
                  _PlaceholderCard(
                    icon: Icons.assignment_ind_outlined,
                    title: 'Manage roles',
                    sub: 'Promote clinicians to admin or audit reviewer',
                  ),
                  _PlaceholderCard(
                    icon: Icons.workspace_premium_outlined,
                    title: 'Seat usage',
                    sub: 'Track how many of your purchased seats are active',
                  ),
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
                            'Full team management ships in the next backend release. For now, contact support@pronoteai.com to add or remove seats.',
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

class _UpgradePrompt extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(28),
              ),
              child: const Icon(Icons.workspace_premium_outlined, color: AppColors.warning, size: 40),
            ),
            const SizedBox(height: 18),
            const Text('Group plan required',
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            const Text(
              'Team management is included on Group and Enterprise plans. Upgrade to invite colleagues, manage roles, and share templates.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.slate400, fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => context.push('/enterprise'),
              icon: const Icon(Icons.upgrade),
              label: const Text('See Enterprise plan'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaceholderCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String sub;
  const _PlaceholderCard({required this.icon, required this.title, required this.sub});

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
                color: AppColors.emerald500.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, color: AppColors.emerald400, size: 19),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(sub, style: const TextStyle(color: AppColors.slate400, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
