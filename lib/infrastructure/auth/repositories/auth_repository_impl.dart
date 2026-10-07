import '../../../domain/auth/entities/user_entity.dart';
import '../../../domain/auth/entities/user_profile_entity.dart';
import '../../../domain/auth/repositories/auth_repository.dart';
import '../datasources/supabase_auth_datasource.dart';
import '../datasources/auth_api_datasource.dart';
import '../mappers/auth_mapper.dart';
import '../models/user_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:shared_preferences/shared_preferences.dart';

class AuthRepositoryImpl implements AuthRepository {
  final SupabaseAuthDataSource _supabaseDataSource;
  final AuthApiDataSource _apiDataSource;

  static const _fullNameKey = 'cached_full_name';
  static const _tokenKey = 'user_jwt_token';

  AuthRepositoryImpl({
    required SupabaseAuthDataSource supabaseDataSource,
    required AuthApiDataSource apiDataSource,
  }) : _supabaseDataSource = supabaseDataSource,
       _apiDataSource = apiDataSource;

  UserModel? _cachedUser;
  DateTime? _lastVerificationTime;
  final _cacheDuration = const Duration(seconds: 10);

  /// Persiste el nombre real del usuario para poder mostrarlo sin conexión.
  Future<void> _cacheFullName(String fullName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (fullName.isNotEmpty && fullName != 'Usuario') {
        await prefs.setString(_fullNameKey, fullName);
      }
    } catch (_) {}
  }

  Future<String?> _readCachedFullName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_fullNameKey);
    } catch (_) {
      return null;
    }
  }

  /// Persiste el token de sesión para que el sync en segundo plano
  /// (WorkManager) pueda autenticarse sin acceso a Supabase.
  Future<void> _cacheToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token);
    } catch (_) {}
  }

  Future<void> _clearCachedToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
    } catch (_) {}
  }

  Future<UserModel?> _verifyWithCache(String token) async {
    final now = DateTime.now();
    if (_cachedUser != null &&
        _lastVerificationTime != null &&
        now.difference(_lastVerificationTime!) < _cacheDuration) {
      return _cachedUser;
    }

    final user = await _apiDataSource.verifyTokenInBackend(token);
    if (user == null) return null;
    _cachedUser = user;
    _lastVerificationTime = now;
    await _cacheFullName(user.fullName);
    return user;
  }

  /// Fallback sin internet: conserva el nombre real del usuario si la sesión
  /// persistente de Supabase no trae metadata de nombre.
  Future<UserEntity> _offlineEntity(supabase.User supabaseUser) async {
    final cachedName = await _readCachedFullName();
    return AuthMapper.supabaseUserToEntity(
      supabaseUser,
      fullNameOverride: cachedName,
    );
  }

  @override
  Stream<UserEntity?> authStateChanges() {
    return _supabaseDataSource.authStateChanges.asyncMap((authState) async {
      final supabaseUser = authState.session?.user;

      if (supabaseUser == null) {
        await _clearCachedToken();
        return null;
      }

      final token = authState.session?.accessToken;

      if (token == null) {
        return AuthMapper.supabaseUserToEntity(supabaseUser);
      }

      await _cacheToken(token);

      try {
        final userModel = await _verifyWithCache(token);

        if (userModel != null) {
          final currentMetadata = supabaseUser.userMetadata ?? {};
          final needsUpdate = currentMetadata['role'] != userModel.role ||
                             currentMetadata['is_setup_completed'] != userModel.isSetupCompleted;

          if (needsUpdate) {
            await _supabaseDataSource.updateUserMetadata({
              'role': userModel.role,
              'is_setup_completed': userModel.isSetupCompleted,
            });
          }

          return userModel.toEntity();
        } else {
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
            await _supabaseDataSource.updateUserMetadata({
              'role': 'pending',
              'is_setup_completed': false,
            });

            _cachedUser = newUser;
            _lastVerificationTime = DateTime.now();
            await _cacheFullName(newUser.fullName);
            return newUser.toEntity();
          } catch (registerError) {
            return _offlineEntity(supabaseUser);
          }
        }
      } catch (e) {
        return _offlineEntity(supabaseUser);
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
    final normalizedEmail = email.trim().toLowerCase();

    final emailExists = await _apiDataSource.checkEmailExists(
      email: normalizedEmail,
    );
    if (emailExists) {
      throw Exception(
        'Error al procesar el registro. Por favor verifica tus datos o intenta con otro método.',
      );
    }

    final response = await _supabaseDataSource.signUp(
      email: normalizedEmail,
      password: password,
      data: {'full_name': fullName},
    );

    if (response.user == null ||
        (response.user!.identities != null &&
            response.user!.identities!.isEmpty)) {
      throw Exception(
        'Error al procesar el registro. Por favor verifica tus datos o intenta con otro método.',
      );
    }

    return AuthMapper.supabaseUserToEntity(response.user!);
  }

  Future<UserEntity> verifyOtpAndSync({
    required String email,
    required String tokenPin,
    required String fullName,
    required String role,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();

    final response = await _supabaseDataSource.verifyOtp(
      email: normalizedEmail,
      token: tokenPin,
    );
    final sessionToken = response.session?.accessToken;

    if (sessionToken == null || response.user == null) {
      throw Exception('Fallo la validación OTP o no se obtuvo sesión.');
    }

    final userModel = await _apiDataSource.registerInBackend(
      token: sessionToken,
      fullName: fullName,
      role: role,
    );

    await _supabaseDataSource.updateUserMetadata({
      'role': role,
      'is_setup_completed': userModel.isSetupCompleted,
    });

    _cachedUser = userModel;
    _lastVerificationTime = DateTime.now();

    return userModel.toEntity();
  }

  @override
  Future<UserEntity> login({
    required String email,
    required String password,
  }) async {
    final response = await _supabaseDataSource.signIn(
      email: email,
      password: password,
    );

    final token = response.session?.accessToken;
    if (token == null)
      throw Exception(
        'No se pudo obtener el token (Posible cuenta sin verificar)',
      );

    _cachedUser = null;
    _lastVerificationTime = null;

    final userModel = await _verifyWithCache(token);
    if (userModel == null)
      throw Exception('Usuario no encontrado en el servidor');

    return userModel.toEntity();
  }

  @override
  Future<UserEntity> signInWithGoogle() async {
    final response = await _supabaseDataSource.signInWithGoogle();

    final token = response.session?.accessToken;
    if (token == null) throw Exception('No se pudo obtener el token Auth');

    final existingUser = await _verifyWithCache(token);

    if (existingUser != null) {
      return existingUser.toEntity();
    }

    try {
      final newUser = await _apiDataSource.registerInBackend(
        token: token,
        fullName: response.user?.userMetadata?['full_name'] ?? 'Usuario',
        role: 'pending',
      );

      await _supabaseDataSource.updateUserMetadata({
        'role': 'pending',
        'is_setup_completed': false,
      });

      _cachedUser = newUser;
      _lastVerificationTime = DateTime.now();
      await _cacheFullName(newUser.fullName);

      return newUser.toEntity();
    } catch (e) {
      return _offlineEntity(response.user!);
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
    final token = await _supabaseDataSource.getIdToken();
    if (token == null) throw Exception('No se pudo obtener el token');

    final updatedUserModel = await _apiDataSource.updateAvatarInBackend(
      token: token,
      avatarSeed: avatarSeed,
      avatarBackground: avatarBackground,
    );

    _cachedUser = updatedUserModel;
    _lastVerificationTime = DateTime.now();

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
    final token = await _supabaseDataSource.getIdToken();
    if (token == null) throw Exception('No se pudo obtener el token');

    await _apiDataSource.createProfile(token: token, profileData: profileData);

    _cachedUser = null;
    _lastVerificationTime = null;
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

    await _supabaseDataSource.updateUserMetadata({
      'role': role,
      'is_setup_completed': updatedUserModel.isSetupCompleted,
    });

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
