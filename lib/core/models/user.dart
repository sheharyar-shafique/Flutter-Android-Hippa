class User {
  final String id;
  final String name;
  final String email;
  final String? specialty;
  final String? role;
  final String? subscriptionPlan;
  final String? subscriptionStatus;
  final DateTime? trialEndsAt;
  final String? avatarUrl;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.specialty,
    this.role,
    this.subscriptionPlan,
    this.subscriptionStatus,
    this.trialEndsAt,
    this.avatarUrl,
  });

  bool get isTrial => subscriptionStatus == 'trial';
  bool get isInactive => subscriptionStatus == 'inactive';
  bool get isAdmin => role == 'admin';

  int? get trialDaysLeft {
    if (!isTrial || trialEndsAt == null) return null;
    final ms = trialEndsAt!.difference(DateTime.now()).inMilliseconds;
    if (ms <= 0) return 0;
    return (ms / (1000 * 60 * 60 * 24)).ceil();
  }

  String get initial => name.isNotEmpty ? name[0].toUpperCase() : 'D';

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      specialty: json['specialty'] as String?,
      role: json['role'] as String?,
      subscriptionPlan: json['subscriptionPlan'] as String?,
      subscriptionStatus: json['subscriptionStatus'] as String?,
      trialEndsAt: json['trialEndsAt'] != null
          ? DateTime.tryParse(json['trialEndsAt'] as String)
          : null,
      avatarUrl: json['avatarUrl'] as String?,
    );
  }
}
