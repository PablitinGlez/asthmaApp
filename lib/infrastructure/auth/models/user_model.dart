import '../../../domain/auth/entities/user_entity.dart';

class UserModel {
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

  UserModel({
    required this.dbId,
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    this.doctorCode,
    required this.avatarSeed,
    required this.avatarBackground,
    required this.isActive,
    required this.isSetupCompleted,
    this.linkingCode,
    this.latitude,
    this.longitude,
    this.lastLocationUpdate,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final id = json['supabase_uid'] ?? '';
    final rawLat = json['last_latitude'] ?? json['latitude'] ?? json['lat'];
    final rawLng = json['last_longitude'] ?? json['longitude'] ?? json['lng'];
    final rawTime = json['last_location_update'] ?? json['location_updated_at'];

    return UserModel(
      dbId: json['id'] ?? 0,
      id: id,
      email: json['email'] ?? '',
      fullName: json['full_name'] ?? '',
      role: json['role'] ?? 'patient',
      doctorCode: json['doctor_code'],
      avatarSeed: json['avatar_seed'] ?? id,
      avatarBackground: json['avatar_background'] ?? '023e8a',
      isActive: json['is_active'] ?? true,
      isSetupCompleted: json['is_setup_completed'] ?? false,
      linkingCode: json['linking_code'],
      latitude: rawLat != null ? (rawLat as num).toDouble() : null,
      longitude: rawLng != null ? (rawLng as num).toDouble() : null,
      lastLocationUpdate: rawTime != null ? DateTime.tryParse(rawTime.toString()) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': dbId,
    'supabase_uid': id,
    'email': email,
    'full_name': fullName,
    'role': role,
    'doctor_code': doctorCode,
    'avatar_seed': avatarSeed,
    'avatar_background': avatarBackground,
    'is_active': isActive,
    'is_setup_completed': isSetupCompleted,
    'linking_code': linkingCode,
    'latitude': latitude,
    'longitude': longitude,
    'last_location_update': lastLocationUpdate?.toIso8601String(),
  };

  UserEntity toEntity() => UserEntity(
    dbId: dbId,
    id: id,
    email: email,
    fullName: fullName,
    role: role,
    doctorCode: doctorCode,
    avatarSeed: avatarSeed,
    avatarBackground: avatarBackground,
    isActive: isActive,
    isSetupCompleted: isSetupCompleted,
    linkingCode: linkingCode,
    latitude: latitude,
    longitude: longitude,
    lastLocationUpdate: lastLocationUpdate,
  );
}
