import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/auth_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF050d12),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const ProviderScope(child: PronoteApp()));
}

class PronoteApp extends ConsumerStatefulWidget {
  const PronoteApp({super.key});

  @override
  ConsumerState<PronoteApp> createState() => _PronoteAppState();
}

class _PronoteAppState extends ConsumerState<PronoteApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// When the user comes back to the app — typically after completing a
  /// Stripe / PayPal checkout in their browser — re-fetch /auth/me so the
  /// fresh subscription status flows into the UI immediately.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(authControllerProvider.notifier).refreshUser();
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Pronote',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      routerConfig: router,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.0)),
          child: _SystemBackHandler(router: router, child: child ?? const SizedBox.shrink()),
        );
      },
    );
  }
}

/// Intercepts the Android system back button / swipe-back gesture.
///
/// Without this, GoRouter's flat route table means the system back button
/// exits the app immediately from any screen. This widget catches the back
/// event and either:
///   1. Pops the current route if there's a navigation stack to pop, OR
///   2. Navigates to /dashboard if the user is on a top-level page, OR
///   3. Only exits the app from / (landing) or /dashboard.
class _SystemBackHandler extends StatelessWidget {
  final GoRouter router;
  final Widget child;
  const _SystemBackHandler({required this.router, required this.child});

  static const _exitRoutes = {'/', '/dashboard', '/login', '/splash'};

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;

        // If GoRouter has stack to pop, pop it.
        if (router.canPop()) {
          router.pop();
          return;
        }

        // On exit routes, allow the app to close.
        final currentPath = router.routeInformationProvider.value.uri.path;
        if (_exitRoutes.contains(currentPath)) {
          SystemNavigator.pop();
          return;
        }

        // Otherwise, go back to dashboard.
        router.go('/dashboard');
      },
      child: child,
    );
  }
}
