import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import '../../../domain/auth/entities/user_entity.dart';

class AuthMapper {
  static UserEntity supabaseUserToEntity(
    supabase.User supabaseUser, {
    String? fullNameOverride,
  }) {
    final fullName =
        fullNameOverride ??
        supabaseUser.userMetadata?['full_name'] ??
        'Usuario';
    return UserEntity(
      dbId: 0,
      id: supabaseUser.id,
      email: supabaseUser.email ?? '',
      fullName: fullName,
      role: supabaseUser.userMetadata?['role'] ?? 'pending',
      isSetupCompleted: supabaseUser.userMetadata?['is_setup_completed'] ?? false,
      avatarSeed: fullName,
      avatarBackground: '023e8a',
      isActive: true,
    );
  }
}
