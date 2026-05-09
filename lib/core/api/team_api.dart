import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_client.dart';

final teamApiProvider = Provider<TeamApi>((ref) => TeamApi(ref.watch(apiClientProvider)));

class TeamMember {
  final String id;
  final String? userId;
  final String? name;
  final String email;
  final String? specialty;
  final String role;
  final String status;
  final DateTime? joinedAt;

  TeamMember({required this.id, this.userId, this.name, required this.email, this.specialty, required this.role, required this.status, this.joinedAt});

  factory TeamMember.fromJson(Map<String, dynamic> json) => TeamMember(
    id: (json['id'] ?? '').toString(),
    userId: json['userId']?.toString(),
    name: json['name'] as String?,
    email: (json['email'] ?? json['invitedEmail'] ?? '') as String,
    specialty: json['specialty'] as String?,
    role: json['role'] as String? ?? 'member',
    status: json['status'] as String? ?? 'pending',
    joinedAt: json['joinedAt'] != null ? DateTime.tryParse(json['joinedAt'] as String) : null,
  );
}

class Team {
  final String id;
  final String name;
  final String ownerId;
  final int memberLimit;
  final String? plan;
  final bool isOwner;
  final List<TeamMember> members;

  Team({required this.id, required this.name, required this.ownerId, required this.memberLimit, this.plan, required this.isOwner, required this.members});

  int get activeCount => members.where((m) => m.status == 'active').length;
  int get pendingCount => members.where((m) => m.status == 'pending').length;
  int get seatsUsed => members.where((m) => m.status == 'active' || m.status == 'pending').length;

  factory Team.fromJson(Map<String, dynamic> json) => Team(
    id: (json['id'] ?? '').toString(),
    name: json['name'] as String? ?? '',
    ownerId: (json['ownerId'] ?? '').toString(),
    memberLimit: (json['memberLimit'] as num?)?.toInt() ?? 5,
    plan: json['plan'] as String?,
    isOwner: json['isOwner'] as bool? ?? false,
    members: ((json['members'] as List?) ?? []).map((m) => TeamMember.fromJson(m as Map<String, dynamic>)).toList(),
  );
}

class TeamApi {
  final Dio _dio;
  TeamApi(this._dio);

  Future<Team?> getTeam() async {
    try {
      final res = await _dio.get('/teams');
      if (res.data == null) return null;
      return Team.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<Team> createTeam(String name) async {
    try {
      final res = await _dio.post('/teams', data: {'name': name});
      return Team.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> renameTeam(String teamId, String name) async {
    try {
      await _dio.put('/teams/$teamId', data: {'name': name});
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> inviteMember(String teamId, String email) async {
    try {
      await _dio.post('/teams/$teamId/invite', data: {'email': email});
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> removeMember(String teamId, String memberId) async {
    try {
      await _dio.delete('/teams/$teamId/members/$memberId');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> disbandTeam(String teamId) async {
    try {
      await _dio.delete('/teams/$teamId');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
