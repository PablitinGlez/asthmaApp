import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthException implements Exception {
  final String message;
  AuthException(this.message);
  @override
  String toString() => message;
}

class SupabaseAuthDataSource {
  final SupabaseClient _supabaseClient;

  SupabaseAuthDataSource(this._supabaseClient);

  Stream<AuthState> get authStateChanges =>
      _supabaseClient.auth.onAuthStateChange;

  User? get currentUser => _supabaseClient.auth.currentUser;

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

  Future<AuthResponse> signInWithGoogle() async {
    try {
      final webClientId =
          '40445796906-mspu2r92pn60f22i2upgru8igctbebnv.apps.googleusercontent.com';
      final iosClientId =
          '40445796906-5lfiq2p91qfl99nvq4radfpeafol5m7b.apps.googleusercontent.com';

      final GoogleSignIn googleSignIn = GoogleSignIn(
        serverClientId: webClientId,
        clientId: iosClientId,
      );

      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        throw AuthException('Inicio de sesión cancelado');
      }

      final googleAuth = await googleUser.authentication;
      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;

      if (accessToken == null) {
        throw AuthException('No Access Token found.');
      }
      if (idToken == null) {
        throw AuthException('No ID Token found.');
      }

      final response = await _supabaseClient.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );
      return response;
    } catch (e) {
      throw AuthException('Error al iniciar sesión con Google: $e');
    }
  }

  Future<void> signOut() async {
    try {
      await GoogleSignIn().signOut();
    } catch (e) {}
    await _supabaseClient.auth.signOut();
  }

  Future<String?> getIdToken() async {
    final session = _supabaseClient.auth.currentSession;
    return session?.accessToken;
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _supabaseClient.auth.resetPasswordForEmail(
        email,
        redirectTo: 'io.supabase.asthmaapp://reset-callback/',
      );
    } catch (e) {
      throw AuthException('Error al enviar correo de recuperación.');
    }
  }

  Future<void> updatePassword(String newPassword, {String? oldPassword}) async {
    try {
      if (oldPassword != null) {
        final email = _supabaseClient.auth.currentUser?.email;
        if (email == null) throw AuthException('Sesión no encontrada.');

        try {
          await _supabaseClient.auth.signInWithPassword(
            email: email,
            password: oldPassword,
          );
        } catch (e) {
          throw AuthException('Contraseña actual incorrecta.');
        }
      }

      await _supabaseClient.auth.updateUser(
        UserAttributes(password: newPassword),
      );
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('Error al actualizar la contraseña: $e');
    }
  }

  Future<void> resendOtp({required String email}) async {
    try {
      await _supabaseClient.auth.resend(type: OtpType.signup, email: email);
    } catch (e) {
      throw AuthException('Error al reenviar el código: $e');
    }
  }

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

  Future<UserResponse> updateUserMetadata(Map<String, dynamic> data) async {
    try {
      return await _supabaseClient.auth.updateUser(UserAttributes(data: data));
    } catch (e) {
      throw AuthException('Error al actualizar metadatos: $e');
    }
  }
}
