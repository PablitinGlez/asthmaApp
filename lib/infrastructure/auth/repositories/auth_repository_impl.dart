import '../../../domain/auth/entities/user_entity.dart';
import '../../../domain/auth/entities/user_profile_entity.dart';
import '../../../domain/auth/repositories/auth_repository.dart';
import '../datasources/supabase_auth_datasource.dart';
import '../datasources/auth_api_datasource.dart';
import '../mappers/auth_mapper.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final SupabaseAuthDataSource _supabaseDataSource;
  final AuthApiDataSource _apiDataSource;

  AuthRepositoryImpl({
    required SupabaseAuthDataSource supabaseDataSource,
    required AuthApiDataSource apiDataSource,
  }) : _supabaseDataSource = supabaseDataSource,
       _apiDataSource = apiDataSource;

  // Cache para evitar llamadas repetidas al backend en ráfagas (startup/burst)
  UserModel? _cachedUser;
  DateTime? _lastVerificationTime;
  final _cacheDuration = const Duration(seconds: 10);

  /// Helper para verificar token con caché
  Future<UserModel?> _verifyWithCache(String token) async {
    final now = DateTime.now();
    if (_cachedUser != null &&
        _lastVerificationTime != null &&
        now.difference(_lastVerificationTime!) < _cacheDuration) {
      print('⚡ AuthRepository: Using cached user data');
      return _cachedUser;
    }

    print('🟢 AuthRepository: Calling API (No cache or expired)...');
    final user = await _apiDataSource.verifyTokenInBackend(token);

    _cachedUser = user;
    _lastVerificationTime = now;
    return user;
  }

  @override
  Stream<UserEntity?> authStateChanges() {
    return _supabaseDataSource.authStateChanges.asyncMap((authState) async {
      final supabaseUser = authState.session?.user;
      print(
        '🔵 authStateChanges: supabaseUser = ${supabaseUser?.id} | Event: ${authState.event.name}',
      );

      if (supabaseUser == null) {
        print('🔴 authStateChanges: No user, returning null');
        return null;
      }

      // Obtener el token y consultar la API para datos completos
      final token = authState.session?.accessToken;
      print('🟡 authStateChanges: Got token');

      if (token == null) {
        print('🟠 authStateChanges: No token, using Supabase mapper');
        return AuthMapper.supabaseUserToEntity(supabaseUser);
      }

      try {
        final userModel = await _verifyWithCache(token);

        if (userModel != null) {
          print('✅ authStateChanges: API success - ${userModel.email}');
          
          // Sincronizar metadatos SOLO si han cambiado para evitar bucles infinitos (429 Rate Limit)
          final currentMetadata = supabaseUser.userMetadata ?? {};
          final needsUpdate = currentMetadata['role'] != userModel.role || 
                             currentMetadata['is_setup_completed'] != userModel.isSetupCompleted;

          if (needsUpdate) {
            print('🔄 authStateChanges: Syncing metadata to Supabase...');
            await _supabaseDataSource.updateUserMetadata({
              'role': userModel.role,
              'is_setup_completed': userModel.isSetupCompleted,
            });
          } else {
            print('⏭️ authStateChanges: Metadata already in sync, skipping update');
          }

          return userModel.toEntity();
        } else {
          // El usuario existe en Supabase pero NO en FastAPI (ej. primer login con Google).
          // Lo registramos automáticamente en el backend para que el flujo no se rompa.
          print(
            '🆕 authStateChanges: Usuario no encontrado en backend. Auto-registrando...',
          );
          try {
            final newUser = await _apiDataSource.registerInBackend(
              token: token,
              fullName:
                  supabaseUser.userMetadata?['full_name'] ??
                  supabaseUser.userMetadata?['name'] ??
                  supabaseUser.email ??
                  'Usuario',
              role: 'pending',
            );
            // Actualizar metadatos en Supabase para persistencia rápida
            await _supabaseDataSource.updateUserMetadata({
              'role': 'pending',
              'is_setup_completed': false,
            });

            // Actualizar caché con el usuario recién creado
            _cachedUser = newUser;
            _lastVerificationTime = DateTime.now();
            print(
              '✅ authStateChanges: Auto-registro exitoso - ${newUser.email}',
            );
            return newUser.toEntity();
          } catch (registerError) {
            print('⚠️ authStateChanges: Auto-registro falló - $registerError');
            // Fallback seguro: devolver datos de Supabase (isSetupCompleted=false por defecto)
            return AuthMapper.supabaseUserToEntity(supabaseUser);
          }
        }
      } catch (e) {
        print('❌ authStateChanges: API failed - $e');
        return AuthMapper.supabaseUserToEntity(supabaseUser);
      }
    });
  }

  @override
  Future<UserEntity> register({
    required String email,
    required String password,
    required String fullName,
    required String role,
  }) async {
    // Normalizar el email a minúsculas para evitar problemas con Supabase
    final normalizedEmail = email.trim().toLowerCase();

    // 0. Guardián: Validar primero contra nuestro backend si el correo ya existe.
    final emailExists = await _apiDataSource.checkEmailExists(
      email: normalizedEmail,
    );
    if (emailExists) {
      // Mensaje genérico para evitar account enumeration
      throw Exception(
        'Error al procesar el registro. Por favor verifica tus datos o intenta con otro método.',
      );
    }

    // 1. Registro inicial en Supabase
    final response = await _supabaseDataSource.signUp(
      email: normalizedEmail,
      password: password,
      data: {'full_name': fullName},
    );

    // SEGURIDAD: Supabase devuelve un usuario exitoso pero sin identidades si el email
    // ya está en uso por otro proveedor (ej. Google) y no se pudo vincular/crear.
    // Esto evita que el usuario se quede atrapado en la pantalla de OTP esperando un PIN.
    if (response.user == null ||
        (response.user!.identities != null &&
            response.user!.identities!.isEmpty)) {
      throw Exception(
        'Error al procesar el registro. Por favor verifica tus datos o intenta con otro método.',
      );
    }

    // Devolvemos el usuario preliminar (El backend se sincronizará cuando termine el OTP flow)
    return AuthMapper.supabaseUserToEntity(response.user!);
  }

  // Nuevo método necesario para manejar validación del código (El dominio debería integrarlo próximamente o manearse en Presentation)
  Future<UserEntity> verifyOtpAndSync({
    required String email,
    required String tokenPin,
    required String fullName,
    required String role,
  }) async {
    // Normalizar el email para que coincida exactamente con lo que Supabase guarda
    final normalizedEmail = email.trim().toLowerCase();

    final response = await _supabaseDataSource.verifyOtp(
      email: normalizedEmail,
      token: tokenPin,
    );
    final sessionToken = response.session?.accessToken;

    if (sessionToken == null || response.user == null) {
      throw Exception('Fallo la validación OTP o no se obtuvo sesión.');
    }

    // 3. Registrar/Sincronizar en tu Backend (FastAPI + Supabase)
    final userModel = await _apiDataSource.registerInBackend(
      token: sessionToken,
      fullName: fullName,
      role: role,
    );

    // 4. Sincronizar rol en Supabase para persistencia rápida (Flicker fix)
    await _supabaseDataSource.updateUserMetadata({
      'role': role,
      'is_setup_completed': userModel.isSetupCompleted,
    });

    // 5. Actualizar caché
    _cachedUser = userModel;
    _lastVerificationTime = DateTime.now();

    return userModel.toEntity();
  }

  @override
  Future<UserEntity> login({
    required String email,
    required String password,
  }) async {
    // 1. Login en Supabase
    final response = await _supabaseDataSource.signIn(
      email: email,
      password: password,
    );

    // 2. Obtener el Token
    final token = response.session?.accessToken;
    if (token == null)
      throw Exception(
        'No se pudo obtener el token (Posible cuenta sin verificar)',
      );

    // Limpiar caché vieja antes de pedir datos frescos del login
    _cachedUser = null;
    _lastVerificationTime = null;

    // 3. Traer los datos frescos de tu Backend (usando caché limpia)
    final userModel = await _verifyWithCache(token);
    if (userModel == null)
      throw Exception('Usuario no encontrado en el servidor');

    return userModel.toEntity();
  }

  @override
  Future<UserEntity> signInWithGoogle() async {
    // 1. Sign in con Google (Supabase nativo)
    final response = await _supabaseDataSource.signInWithGoogle();

    // 2. Obtener el Token
    final token = response.session?.accessToken;
    if (token == null) throw Exception('No se pudo obtener el token Auth');

    // 3. Verificar si ya existe el usuario antes de registrar (usando caché)
    final existingUser = await _verifyWithCache(token);

    if (existingUser != null) {
      print('✅ signInWithGoogle: User already exists, skipping registration');
      return existingUser.toEntity();
    }

    // 4. Si no existe, registrar en Backend (siempre como 'patient')
    print('🆕 signInWithGoogle: User not found, registering...');
    try {
      final newUser = await _apiDataSource.registerInBackend(
        token: token,
        fullName: response.user?.userMetadata?['full_name'] ?? 'Usuario',
        role: 'pending',
      );

      // 4. Sincronizar rol en Supabase (siempre pending inicial)
      await _supabaseDataSource.updateUserMetadata({
        'role': 'pending',
        'is_setup_completed': false,
      });

      // Actualizar caché con el nuevo usuario
      _cachedUser = newUser;
      _lastVerificationTime = DateTime.now();

      return newUser.toEntity();
    } catch (e) {
      print('⚠️ Error registrando en backend: $e');
      // Si el registro falla pero Supabase funcionó, devolvemos datos básicos
      return AuthMapper.supabaseUserToEntity(response.user!);
    }
  }

  @override
  Future<void> logout() async {
    _cachedUser = null;
    _lastVerificationTime = null;
    await _supabaseDataSource.signOut();
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    await _supabaseDataSource.sendPasswordResetEmail(email);
  }

  @override
  Future<UserEntity> updateAvatar({
    required String avatarSeed,
    required String avatarBackground,
  }) async {
    // 1. Obtener Token
    final token = await _supabaseDataSource.getIdToken();
    if (token == null) throw Exception('No se pudo obtener el token');

    // 2. Actualizar en Backend
    final updatedUserModel = await _apiDataSource.updateAvatarInBackend(
      token: token,
      avatarSeed: avatarSeed,
      avatarBackground: avatarBackground,
    );

    // 3. Actualizar Caché local inmediatamente
    _cachedUser = updatedUserModel;
    _lastVerificationTime = DateTime.now();

    print('✨ AuthRepository: Avatar updated and cache refreshed');

    return updatedUserModel.toEntity();
  }

  @override
  Future<void> updatePassword(String newPassword, {String? oldPassword}) async {
    await _supabaseDataSource.updatePassword(
      newPassword,
      oldPassword: oldPassword,
    );
  }

  @override
  Future<void> createProfile({
    required Map<String, dynamic> profileData,
  }) async {
    // 1. Obtener Token
    final token = await _supabaseDataSource.getIdToken();
    if (token == null) throw Exception('No se pudo obtener el token');

    // 2. Crear el perfil de usuario en el servidor enviando los JSON (Datos del form)
    await _apiDataSource.createProfile(token: token, profileData: profileData);

    // 3. INVALIDAR CACHÉ MIENTRAS SE NOTIFICA LA APP
    _cachedUser = null;
    _lastVerificationTime = null;

    print(
      '✨ AuthRepository: Profile created in backend and Local Cache cleared.',
    );
  }

  @override
  Future<UserProfileEntity> getProfile() async {
    final token = await _supabaseDataSource.getIdToken();
    if (token == null) throw Exception('No se pudo obtener el token');

    final profileModel = await _apiDataSource.getProfile(token: token);
    return profileModel.toEntity();
  }

  @override
  Future<UserProfileEntity> updateProfile({
    required Map<String, dynamic> profileData,
  }) async {
    final token = await _supabaseDataSource.getIdToken();
    if (token == null) throw Exception('No se pudo obtener el token');

    final profileModel = await _apiDataSource.updateProfile(
      token: token,
      profileData: profileData,
    );
    return profileModel.toEntity();
  }

  @override
  Future<String> assignDoctor({required String doctorCode}) async {
    final token = await _supabaseDataSource.getIdToken();
    if (token == null) throw Exception('No se pudo obtener el token');

    return await _apiDataSource.assignDoctor(
      token: token,
      doctorCode: doctorCode,
    );
  }

  @override
  Future<void> resendOtp({required String email}) async {
    await _supabaseDataSource.resendOtp(email: email);
  }

  // --- MFA (Google Authenticator) ---

  @override
  Future<dynamic> enrollMfa() async {
    return await _supabaseDataSource.enrollMfa();
  }

  @override
  Future<dynamic> challengeAndVerifyMfa({
    required String factorId,
    required String code,
  }) async {
    return await _supabaseDataSource.challengeAndVerifyMfa(
      factorId: factorId,
      code: code,
    );
  }

  @override
  Future<void> unenrollMfa(String factorId) async {
    await _supabaseDataSource.unenrollMfa(factorId);
  }

  @override
  Future<dynamic> getAuthenticatorAssuranceLevel() async {
    return await _supabaseDataSource.getAuthenticatorAssuranceLevel();
  }

  @override
  Future<List<dynamic>> listFactors() async {
    return await _supabaseDataSource.listFactors();
  }

  @override
  Future<UserEntity> updateRole({required String role}) async {
    final token = await _supabaseDataSource.getIdToken();
    if (token == null) throw Exception('No se pudo obtener el token');

    final updatedUserModel = await _apiDataSource.updateRole(
      token: token,
      role: role,
    );

    // Sincronizar rol en Supabase para evitar flickers en el próximo inicio
    await _supabaseDataSource.updateUserMetadata({
      'role': role,
      'is_setup_completed': updatedUserModel.isSetupCompleted,
    });

    // Actualizar Caché local
    _cachedUser = updatedUserModel;
    _lastVerificationTime = DateTime.now();

    return updatedUserModel.toEntity();
  }

  @override
  Future<String> getLinkingCode() async {
    final token = await _supabaseDataSource.getIdToken();
    if (token == null) throw Exception('No se pudo obtener el token');
    return await _apiDataSource.getLinkingCode(token: token);
  }

  @override
  Future<List<Map<String, dynamic>>> getMyGuardians() async {
    final token = await _supabaseDataSource.getIdToken();
    if (token == null) throw Exception('No se pudo obtener el token');
    return await _apiDataSource.getMyGuardians(token: token);
  }

  @override
  Future<void> unlinkGuardian({required int guardianId}) async {
    final token = await _supabaseDataSource.getIdToken();
    if (token == null) throw Exception('No se pudo obtener el token');
    await _apiDataSource.unlinkGuardian(token: token, guardianId: guardianId);
  }

  @override
  Future<void> updateFcmToken({required String fcmToken}) async {
    final token = await _supabaseDataSource.getIdToken();
    if (token == null) throw Exception('No se pudo obtener el token');
    await _apiDataSource.updateFcmToken(token: token, fcmToken: fcmToken);
  }
}
