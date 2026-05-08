import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/api/auth_api.dart';
import '../../core/models/user.dart';

/// All app state lives behind this provider so screens can `ref.watch` it
/// and `go_router` redirects can decide where to send the user.
class AuthState {
  final User? user;
  final bool initialising;
  final bool busy;
  final String? error;

  const AuthState({
    this.user,
    this.initialising = true,
    this.busy = false,
    this.error,
  });

  bool get isAuthenticated => user != null;
  bool get subscriptionLocked => user?.isInactive ?? false;

  AuthState copyWith({
    User? user,
    bool? initialising,
    bool? busy,
    String? error,
    bool clearUser = false,
    bool clearError = false,
  }) {
    return AuthState(
      user: clearUser ? null : (user ?? this.user),
      initialising: initialising ?? this.initialising,
      busy: busy ?? this.busy,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(ref);
});

class AuthController extends StateNotifier<AuthState> {
  final Ref _ref;

  AuthController(this._ref) : super(const AuthState()) {
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final storage = _ref.read(secureStorageProvider);
    final token = await storage.read(key: kTokenStorageKey);
    if (token == null || token.isEmpty) {
      state = state.copyWith(initialising: false);
      return;
    }

    try {
      final user = await _ref.read(authApiProvider).me();
      state = state.copyWith(user: user, initialising: false);
    } catch (_) {
      // Token expired/invalid — wipe and bounce to login.
      await storage.delete(key: kTokenStorageKey);
      state = state.copyWith(initialising: false, clearUser: true);
    }
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(busy: true, clearError: true);
    try {
      final result = await _ref.read(authApiProvider).login(
            email: email,
            password: password,
          );
      await _ref
          .read(secureStorageProvider)
          .write(key: kTokenStorageKey, value: result.token);
      state = state.copyWith(user: result.user, busy: false);
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(busy: false, error: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(busy: false, error: 'Unexpected error: $e');
      return false;
    }
  }

  Future<bool> signup({
    required String name,
    required String email,
    required String password,
    String? specialty,
  }) async {
    state = state.copyWith(busy: true, clearError: true);
    try {
      final result = await _ref.read(authApiProvider).signup(
            name: name,
            email: email,
            password: password,
            specialty: specialty,
          );
      await _ref
          .read(secureStorageProvider)
          .write(key: kTokenStorageKey, value: result.token);
      state = state.copyWith(user: result.user, busy: false);
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(busy: false, error: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(busy: false, error: 'Unexpected error: $e');
      return false;
    }
  }

  Future<bool> forgotPassword(String email) async {
    state = state.copyWith(busy: true, clearError: true);
    try {
      await _ref.read(authApiProvider).forgotPassword(email);
      state = state.copyWith(busy: false);
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(busy: false, error: e.message);
      return false;
    }
  }

  Future<void> logout() async {
    await _ref.read(authApiProvider).logout();
    await _ref.read(secureStorageProvider).delete(key: kTokenStorageKey);
    state = state.copyWith(clearUser: true);
  }

  /// Pulls /auth/me again so a subscription / role change made on the web
  /// (e.g. the user just paid via Stripe checkout) is reflected here.
  Future<void> refreshUser() async {
    if (state.user == null) return;
    try {
      final user = await _ref.read(authApiProvider).me();
      state = state.copyWith(user: user);
    } catch (_) {
      // Soft fail — don't disturb the UI if the refresh fails.
    }
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}
