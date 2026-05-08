import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_theme.dart';
import '../features/auth/auth_controller.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;
    final currentPath = GoRouterState.of(context).matchedLocation;

    return Drawer(
      backgroundColor: AppColors.bgDeep,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      gradient: kEmeraldGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.auto_awesome, color: Colors.white, size: 19),
                  ),
                  const SizedBox(width: 10),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Pronote', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
                      Text('AI Medical Scribe', style: TextStyle(color: AppColors.emerald400, fontSize: 11, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(color: AppColors.cardBorder, height: 1),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                children: [
                  _DrawerItem(
                    icon: Icons.dashboard_outlined,
                    label: 'Dashboard',
                    route: '/dashboard',
                    color: AppColors.emerald400,
                    currentPath: currentPath,
                  ),
                  _DrawerItem(
                    icon: Icons.mic,
                    label: 'Capture',
                    route: '/capture',
                    color: const Color(0xFFFB7185),
                    currentPath: currentPath,
                  ),
                  _DrawerItem(
                    icon: Icons.chat_bubble_outline,
                    label: 'Dictation',
                    route: '/dictation',
                    color: const Color(0xFFA78BFA),
                    currentPath: currentPath,
                  ),
                  _DrawerItem(
                    icon: Icons.upload_outlined,
                    label: 'Upload',
                    route: '/upload',
                    color: AppColors.info,
                    currentPath: currentPath,
                  ),
                  _DrawerItem(
                    icon: Icons.description_outlined,
                    label: 'Notes',
                    route: '/notes',
                    color: AppColors.warning,
                    currentPath: currentPath,
                  ),
                  _DrawerItem(
                    icon: Icons.people_outline,
                    label: 'Patients',
                    route: '/patients',
                    color: const Color(0xFF60A5FA),
                    currentPath: currentPath,
                  ),
                  _DrawerItem(
                    icon: Icons.layers_outlined,
                    label: 'Templates',
                    route: '/templates',
                    color: const Color(0xFF22D3EE),
                    currentPath: currentPath,
                  ),
                  _DrawerItem(
                    icon: Icons.bar_chart,
                    label: 'Analytics',
                    route: '/analytics',
                    color: AppColors.warning,
                    currentPath: currentPath,
                  ),
                  _DrawerItem(
                    icon: Icons.workspace_premium_outlined,
                    label: 'Plans & billing',
                    route: '/plans',
                    color: const Color(0xFFFBBF24),
                    currentPath: currentPath,
                  ),
                  if ((user?.subscriptionPlan ?? '').startsWith('group'))
                    _DrawerItem(
                      icon: Icons.groups_outlined,
                      label: 'Team',
                      route: '/team',
                      color: const Color(0xFFA78BFA),
                      currentPath: currentPath,
                    ),
                  if (user?.isAdmin ?? false)
                    _DrawerItem(
                      icon: Icons.shield_outlined,
                      label: 'Admin',
                      route: '/admin',
                      color: AppColors.danger,
                      currentPath: currentPath,
                    ),
                  _DrawerItem(
                    icon: Icons.settings_outlined,
                    label: 'Settings',
                    route: '/settings',
                    color: AppColors.slate400,
                    currentPath: currentPath,
                  ),
                  _DrawerItem(
                    icon: Icons.help_outline,
                    label: 'Help center',
                    route: '/help',
                    color: AppColors.slate400,
                    currentPath: currentPath,
                  ),
                ],
              ),
            ),

            if (user != null) ...[
              const Divider(color: AppColors.cardBorder, height: 1),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        gradient: kEmeraldGradient,
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Center(
                        child: Text(
                          user.initial,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
                          ),
                          Text(
                            user.specialty ?? 'Clinician',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: AppColors.slate400, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Sign out',
                      icon: const Icon(Icons.logout, color: AppColors.slate400, size: 20),
                      onPressed: () async {
                        await ref.read(authControllerProvider.notifier).logout();
                        if (context.mounted) context.go('/login');
                      },
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String route;
  final Color color;
  final String currentPath;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.route,
    required this.color,
    required this.currentPath,
  });

  bool get _isActive {
    if (route == '/dashboard') return currentPath == '/dashboard';
    return currentPath == route || currentPath.startsWith('$route/');
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: _isActive ? AppColors.cardBg : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () {
            Navigator.pop(context);
            if (currentPath != route) context.go(route);
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: _isActive ? Border.all(color: AppColors.cardBorder) : null,
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _isActive ? color.withValues(alpha: 0.18) : AppColors.cardBg,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(icon, color: _isActive ? color : AppColors.slate400, size: 16),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: _isActive ? Colors.white : AppColors.slate400,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (_isActive)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
