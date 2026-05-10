import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user.dart';
import 'api_client.dart';

class AuthResult {
  final User user;
  final String token;
  AuthResult({required this.user, required this.token});

  factory AuthResult.fromJson(Map<String, dynamic> json) {
    return AuthResult(
      user: User.fromJson(json['user'] as Map<String, dynamic>),
      token: json['token'] as String,
    );
  }
}

final authApiProvider = Provider<AuthApi>((ref) {
  return AuthApi(ref.watch(apiClientProvider));
});

class AuthApi {
  final Dio _dio;
  AuthApi(this._dio);

  Future<AuthResult> login({required String email, required String password}) async {
    try {
      final res = await _dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });
      return AuthResult.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<AuthResult> signup({
    required String name,
    required String email,
    required String password,
    String? specialty,
  }) async {
    try {
      final res = await _dio.post('/auth/signup', data: {
        'name': name,
        'email': email,
        'password': password,
        if (specialty != null) 'specialty': specialty,
      });
      return AuthResult.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<User> me() async {
    try {
      final res = await _dio.get('/auth/me');
      return User.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> forgotPassword(String email) async {
    try {
      await _dio.post('/auth/forgot-password', data: {'email': email});
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// Google OAuth — sends the Google ID token to the backend which verifies
  /// it and returns a Pronote JWT + user, matching the web's
  /// `authApi.googleLogin(idToken)`.
  Future<AuthResult> googleLogin({required String idToken}) async {
    try {
      final res = await _dio.post('/auth/google', data: {
        'idToken': idToken,
      });
      return AuthResult.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> logout() async {
    try {
      await _dio.post('/auth/logout');
    } on DioException catch (_) {
      // Logout is best-effort: even if server fails, we clear the local token.
    }
  }
}
