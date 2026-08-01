class UserEntity {
  final int dbId;
  final String id;
  final String email;
  final String fullName;
  final String role;
  final String? doctorCode;
  final String avatarSeed;
  final String avatarBackground;
  final bool isActive;
  final bool isSetupCompleted;
  final String? linkingCode;
  final double? latitude;
  final double? longitude;
  final DateTime? lastLocationUpdate;

  UserEntity({
    required this.dbId,
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    this.doctorCode,
    required this.avatarSeed,
    required this.avatarBackground,
    this.isActive = true,
    this.isSetupCompleted = false,
    this.linkingCode,
    this.latitude,
    this.longitude,
    this.lastLocationUpdate,
  });

  bool get isDoctor => role == 'doctor';

  UserEntity copyWith({
    int? dbId,
    String? id,
    String? email,
    String? fullName,
    String? role,
    String? doctorCode,
    String? avatarSeed,
    String? avatarBackground,
    bool? isActive,
    bool? isSetupCompleted,
  }) {
    return UserEntity(
      dbId: dbId ?? this.dbId,
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      doctorCode: doctorCode ?? this.doctorCode,
      avatarSeed: avatarSeed ?? this.avatarSeed,
      avatarBackground: avatarBackground ?? this.avatarBackground,
      isActive: isActive ?? this.isActive,
      isSetupCompleted: isSetupCompleted ?? this.isSetupCompleted,
    );
  }
}
