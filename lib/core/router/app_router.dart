import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/auth_controller.dart';
import '../../features/auth/forgot_password_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/signup_screen.dart';
import '../../features/capture/capture_screen.dart';
import '../../features/dashboard/dashboard_screen.dart';
import '../../features/dictation/dictation_screen.dart';
import '../../features/notes/note_editor_screen.dart';
import '../../features/notes/notes_list_screen.dart';
import '../../features/patients/patients_list_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/subscription/subscription_locked_screen.dart';
import '../../features/templates/templates_screen.dart';
import '../../features/upload/upload_screen.dart';

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

        if (isLockedRoute || loc == '/splash' || isAuthRoute || loc == '/') {
          return '/dashboard';
        }
        return null;
      }

      // Unauthenticated — only auth surfaces are reachable.
      if (loc == '/splash' ||
          loc == '/subscription-locked' ||
          loc.startsWith('/dashboard') ||
          loc.startsWith('/capture') ||
          loc.startsWith('/notes') ||
          loc.startsWith('/patients') ||
          loc.startsWith('/templates') ||
          loc.startsWith('/upload') ||
          loc.startsWith('/dictation') ||
          loc.startsWith('/settings')) {
        return '/login';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/', redirect: (_, __) => '/login'),
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/signup', builder: (_, __) => const SignupScreen()),
      GoRoute(path: '/forgot-password', builder: (_, __) => const ForgotPasswordScreen()),
      GoRoute(path: '/subscription-locked', builder: (_, __) => const SubscriptionLockedScreen()),

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
      GoRoute(path: '/templates', builder: (_, __) => const TemplatesScreen()),
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
