import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user.dart';
import 'api_client.dart';

final usersApiProvider = Provider<UsersApi>((ref) {
  return UsersApi(ref.watch(apiClientProvider));
});

class UsersApi {
  final Dio _dio;
  UsersApi(this._dio);

  Future<User> updateProfile({String? name, String? specialty}) async {
    try {
      final res = await _dio.put('/users/me', data: {
        if (name != null) 'name': name,
        if (specialty != null) 'specialty': specialty,
      });
      return User.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await _dio.post('/auth/change-password', data: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      });
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// HIPAA-required: irrevocably wipes the account + all PHI.
  Future<void> deleteAccount({required String confirmEmail}) async {
    try {
      await _dio.post('/users/delete-account', data: {
        'confirmEmail': confirmEmail,
      });
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
