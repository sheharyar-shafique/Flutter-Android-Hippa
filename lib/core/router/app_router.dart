import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/admin/admin_screen.dart';
import '../../features/analytics/analytics_screen.dart';
import '../../features/auth/auth_controller.dart';
import '../../features/auth/forgot_password_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/signup_screen.dart';
import '../../features/capture/capture_screen.dart';
import '../../features/dashboard/dashboard_screen.dart';
import '../../features/dictation/dictation_screen.dart';
import '../../features/enterprise/enterprise_screen.dart';
import '../../features/help/help_center_screen.dart';
import '../../features/landing/landing_screen.dart';
import '../../features/legal/delete_account_info_screen.dart';
import '../../features/legal/hipaa_baa_screen.dart';
import '../../features/legal/privacy_screen.dart';
import '../../features/legal/terms_screen.dart';
import '../../features/notes/note_editor_screen.dart';
import '../../features/notes/notes_list_screen.dart';
import '../../features/patients/patient_detail_screen.dart';
import '../../features/patients/patients_list_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/subscription/plans_screen.dart';
import '../../features/subscription/subscription_locked_screen.dart';
import '../../features/team/team_screen.dart';
import '../../features/templates/template_editor_screen.dart';
import '../../features/templates/templates_screen.dart';
import '../../features/upload/upload_screen.dart';

const _kPublicPaths = {
  '/',
  '/login',
  '/signup',
  '/forgot-password',
  '/privacy',
  '/terms',
  '/hipaa-baa',
  '/enterprise',
  '/delete-account',
  '/plans',
};

bool _isPublic(String loc) {
  if (_kPublicPaths.contains(loc)) return true;
  return loc == '/help'; // help center reachable without login too
}

final routerProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authControllerProvider);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: _AuthListenable(ref),
    redirect: (context, state) {
      if (auth.initialising) return '/splash';

      final loc = state.matchedLocation;
      final isAuthRoute = loc == '/login' || loc == '/signup' || loc == '/forgot-password';
      final isLockedRoute = loc == '/subscription-locked';

      if (auth.isAuthenticated) {
        // Account locked → only the locked screen + sign-out flow are reachable.
        if (auth.subscriptionLocked) {
          if (!isLockedRoute) return '/subscription-locked';
          return null;
        }

        // Already signed in: bounce them out of guest-only routes.
        if (loc == '/splash' || isAuthRoute || isLockedRoute) {
          return '/dashboard';
        }
        // / (landing) is fine — they can browse it logged-in if they want.
        return null;
      }

      // Unauthenticated — block app surfaces, allow public ones.
      if (_isPublic(loc)) return null;
      if (loc == '/splash') return '/';
      return '/login';
    },
    routes: [
      // Public surfaces
      GoRoute(path: '/', builder: (_, __) => const LandingScreen()),
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/signup', builder: (_, __) => const SignupScreen()),
      GoRoute(path: '/forgot-password', builder: (_, __) => const ForgotPasswordScreen()),
      GoRoute(path: '/subscription-locked', builder: (_, __) => const SubscriptionLockedScreen()),

      // Legal / info (reachable from landing footer + settings links)
      GoRoute(path: '/privacy', builder: (_, __) => const PrivacyScreen()),
      GoRoute(path: '/terms', builder: (_, __) => const TermsScreen()),
      GoRoute(path: '/hipaa-baa', builder: (_, __) => const HipaaBaaScreen()),
      GoRoute(path: '/delete-account', builder: (_, __) => const DeleteAccountInfoScreen()),
      GoRoute(path: '/enterprise', builder: (_, __) => const EnterpriseScreen()),
      GoRoute(path: '/help', builder: (_, __) => const HelpCenterScreen()),
      GoRoute(path: '/plans', builder: (_, __) => const PlansScreen()),

      // Authenticated app surfaces
      GoRoute(path: '/dashboard', builder: (_, __) => const DashboardScreen()),
      GoRoute(path: '/capture', builder: (_, __) => const CaptureScreen()),
      GoRoute(path: '/dictation', builder: (_, __) => const DictationScreen()),
      GoRoute(path: '/upload', builder: (_, __) => const UploadScreen()),
      GoRoute(path: '/notes', builder: (_, __) => const NotesListScreen()),
      GoRoute(
        path: '/notes/:id',
        builder: (_, state) => NoteEditorScreen(noteId: state.pathParameters['id']!),
      ),
      GoRoute(path: '/patients', builder: (_, __) => const PatientsListScreen()),
      GoRoute(
        path: '/patients/:id',
        builder: (_, state) => PatientDetailScreen(patientId: state.pathParameters['id']!),
      ),
      GoRoute(path: '/templates', builder: (_, __) => const TemplatesScreen()),
      GoRoute(path: '/templates/new', builder: (_, __) => const TemplateEditorScreen()),
      GoRoute(
        path: '/templates/:id/edit',
        builder: (_, state) => TemplateEditorScreen(templateId: state.pathParameters['id']!),
      ),
      GoRoute(path: '/analytics', builder: (_, __) => const AnalyticsScreen()),
      GoRoute(path: '/team', builder: (_, __) => const TeamScreen()),
      GoRoute(path: '/admin', builder: (_, __) => const AdminScreen()),
      GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Page not found:\n${state.uri}',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70),
          ),
        ),
      ),
    ),
  );
});

class _AuthListenable extends ChangeNotifier {
  _AuthListenable(this._ref) {
    _ref.listen(authControllerProvider, (_, __) => notifyListeners());
  }
  final Ref _ref;
}
