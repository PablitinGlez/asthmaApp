import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';

// Asumimos que AuthException sigue existiendo en el proyecto
class AuthException implements Exception {
  final String message;
  AuthException(this.message);
  @override
  String toString() => message;
}

class SupabaseAuthDataSource {
  final SupabaseClient _supabaseClient;

  SupabaseAuthDataSource(this._supabaseClient);

  // Escucha cambios de estado
  Stream<AuthState> get authStateChanges =>
      _supabaseClient.auth.onAuthStateChange;

  // Obtener el usuario actual
  User? get currentUser => _supabaseClient.auth.currentUser;

  // Registro con Email y Password (y se dispara envío automático de OTP)
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    Map<String, dynamic>? data,
  }) async {
    try {
      return await _supabaseClient.auth.signUp(
        email: email,
        password: password,
        data: data,
      );
    } on AuthException catch (e) {
      throw AuthException(e.message);
    } catch (e) {
      throw AuthException('Error al registrar usuario en Supabase: $e');
    }
  }

  // Verificar OTP
  Future<AuthResponse> verifyOtp({
    required String email,
    required String token,
  }) async {
    try {
      return await _supabaseClient.auth.verifyOTP(
        type: OtpType.signup,
        token: token,
        email: email,
      );
    } catch (e) {
      throw AuthException('Código de verificación inválido o expirado.');
    }
  }

  // Login con Email y Password
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      return await _supabaseClient.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      throw AuthException('Credenciales incorrectas.');
    }
  }

  // Login con Google usando Supabase de forma nativa
  Future<AuthResponse> signInWithGoogle() async {
    try {
      print('=== INICIANDO GOOGLE SIGN IN ===');
      // Usando el flujo nativo de Google Sign-In de Flutter para obtener tokens de Google
      final webClientId =
          '40445796906-mspu2r92pn60f22i2upgru8igctbebnv.apps.googleusercontent.com'; // Servidor Web
      final iosClientId =
          '40445796906-5lfiq2p91qfl99nvq4radfpeafol5m7b.apps.googleusercontent.com'; // iOS Nativo

      final GoogleSignIn googleSignIn = GoogleSignIn(
        serverClientId: webClientId,
        clientId: iosClientId,
      );

      print('Llamando a googleSignIn.signIn()...');
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        print('Excepción: googleUser es null. El usuario canceló o falló.');
        throw AuthException('Inicio de sesión cancelado');
      }

      print('googleUser obtenido correctamente: \${googleUser.email}');
      print('Obteniendo authentication tokens...');
      final googleAuth = await googleUser.authentication;
      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;

      if (accessToken == null) {
        print('Excepción: accessToken es null.');
        throw AuthException('No Access Token found.');
      }
      if (idToken == null) {
        print('Excepción: idToken es null.');
        throw AuthException('No ID Token found.');
      }

      print(
        'Tokens de Google obtenidos. Enviando a Supabase signInWithIdToken...',
      );
      final response = await _supabaseClient.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );
      print('=== GOOGLE SIGN IN EXITOSO ===');
      return response;
    } catch (e) {
      print('ERR_GOOGLE_SIGNIN: $e');
      throw AuthException('Error al iniciar sesión con Google: $e');
    }
  }

  // Logout
  Future<void> signOut() async {
    try {
      await GoogleSignIn().signOut();
    } catch (e) {
      print('Aviso: Falla al limpiar caché de Google Sign-In: $e');
    }
    await _supabaseClient.auth.signOut();
  }

  // Obtener el Token JWT actual (el que usaremos para FastAPI)
  Future<String?> getIdToken() async {
    final session = _supabaseClient.auth.currentSession;
    return session?.accessToken;
  }

  // Enviar correo de recuperación de contraseña
  Future<void> sendPasswordResetEmail(String email) async {
    print('📧 SupabaseAuthDataSource: Requesting reset for $email');
    try {
      await _supabaseClient.auth.resetPasswordForEmail(
        email,
        redirectTo: 'io.supabase.asthmaapp://reset-callback/',
      );
      print('✅ SupabaseAuthDataSource: resetPasswordForEmail call completed');
    } catch (e) {
      print('❌ SupabaseAuthDataSource ERROR: $e');
      throw AuthException('Error al enviar correo de recuperación.');
    }
  }

  // Actualizar la contraseña del usuario logueado
  Future<void> updatePassword(String newPassword, {String? oldPassword}) async {
    try {
      // Si se proporciona la contraseña antigua, la verificamos primero
      if (oldPassword != null) {
        final email = _supabaseClient.auth.currentUser?.email;
        if (email == null) throw AuthException('Sesión no encontrada.');

        try {
          // Intentamos un re-login silencioso para validar la clave actual
          await _supabaseClient.auth.signInWithPassword(
            email: email,
            password: oldPassword,
          );
        } catch (e) {
          throw AuthException('Contraseña actual incorrecta.');
        }
      }

      // Procedemos con la actualización
      await _supabaseClient.auth.updateUser(
        UserAttributes(password: newPassword),
      );
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('Error al actualizar la contraseña: $e');
    }
  }

  // Reenviar OTP
  Future<void> resendOtp({required String email}) async {
    try {
      await _supabaseClient.auth.resend(type: OtpType.signup, email: email);
    } catch (e) {
      throw AuthException('Error al reenviar el código: $e');
    }
  }

  // --- MÉTODOS DE MFA (Google Authenticator) ---

  Future<AuthMFAEnrollResponse> enrollMfa() async {
    try {
      return await _supabaseClient.auth.mfa.enroll(
        factorType: FactorType.totp,
        issuer: 'AsthmaApp',
      );
    } catch (e) {
      throw AuthException('Error al generar código 2FA: $e');
    }
  }

  Future<AuthMFAVerifyResponse> challengeAndVerifyMfa({
    required String factorId,
    required String code,
  }) async {
    try {
      final challenge = await _supabaseClient.auth.mfa.challenge(
        factorId: factorId,
      );
      return await _supabaseClient.auth.mfa.verify(
        factorId: factorId,
        challengeId: challenge.id,
        code: code,
      );
    } catch (e) {
      throw AuthException('Código de verificación incorrecto o expirado.');
    }
  }

  Future<void> unenrollMfa(String factorId) async {
    try {
      await _supabaseClient.auth.mfa.unenroll(factorId);
    } catch (e) {
      throw AuthException('Error al desactivar 2FA: $e');
    }
  }

  Future<AuthMFAGetAuthenticatorAssuranceLevelResponse>
  getAuthenticatorAssuranceLevel() async {
    try {
      return await _supabaseClient.auth.mfa.getAuthenticatorAssuranceLevel();
    } catch (e) {
      throw AuthException('Error al verificar el Assurance Level: $e');
    }
  }

  Future<List<dynamic>> listFactors() async {
    try {
      final response = await _supabaseClient.auth.mfa.listFactors();
      return response.all;
    } catch (e) {
      throw AuthException('Error al listar factores de autenticación: $e');
    }
  }

  // Actualizar metadatos del usuario
  Future<UserResponse> updateUserMetadata(Map<String, dynamic> data) async {
    try {
      return await _supabaseClient.auth.updateUser(UserAttributes(data: data));
    } catch (e) {
      throw AuthException('Error al actualizar metadatos: $e');
    }
  }
}
