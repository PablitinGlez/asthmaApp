import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import '../../../domain/auth/entities/user_entity.dart';

class AuthMapper {
  static UserEntity supabaseUserToEntity(supabase.User supabaseUser) {
    final fullName = supabaseUser.userMetadata?['full_name'] ?? 'Usuario';
    return UserEntity(
      dbId: 0, // Placeholder temporal, se reescribirá al llamar a la API
      id: supabaseUser.id,
      email: supabaseUser.email ?? '',
      fullName: fullName,
      role: supabaseUser.userMetadata?['role'] ?? 'pending',
      isSetupCompleted: supabaseUser.userMetadata?['is_setup_completed'] ?? false,
      avatarSeed: fullName, // Usar el nombre como seed para iniciales
      avatarBackground: '023e8a', // Color institucional
      isActive: true,
    );
  }
}
