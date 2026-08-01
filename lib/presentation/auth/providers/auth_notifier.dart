import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import './auth_provider.dart';
import '../../profile/providers/personal_info_provider.dart';
import '../../action_plan/providers/action_plan_provider.dart';
import '../../home/providers/smartwatch_provider.dart';
import '../../home/providers/spirometer_provider.dart';
import '../../home/providers/weekly_trend_provider.dart';
import '../../home/providers/environmental_provider.dart';
import '../../home/providers/measurements_provider.dart';
import '../../home/providers/prediction_provider.dart';
import '../../notifications/providers/notification_settings_provider.dart';

enum AuthStatus {
  initial,
  loading,
  otpSent,
  mfaRequired,
  authenticated,
  passwordRecovery,
  resetEmailSent,
  sendingEmail,
  passwordUpdateSuccess,
  error,
}

class AuthState {
  final AuthStatus status;
  final String? errorMessage;
  final String? pendingEmail;
  final String? pendingFullName;

  bool get isLoading => status == AuthStatus.loading;
  bool get isOtpSent => status == AuthStatus.otpSent;
  bool get isMfaRequired => status == AuthStatus.mfaRequired;
  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isPasswordRecovery => status == AuthStatus.passwordRecovery;
  bool get isResetEmailSent => status == AuthStatus.resetEmailSent;
  bool get isSendingEmail => status == AuthStatus.sendingEmail;
  bool get isPasswordUpdateSuccess =>
      status == AuthStatus.passwordUpdateSuccess;
  bool get hasError => status == AuthStatus.error;

  AuthState({
    this.status = AuthStatus.initial,
    this.errorMessage,
    this.pendingEmail,
    this.pendingFullName,
  });

  AuthState copyWith({
    AuthStatus? status,
    String? errorMessage,
    String? pendingEmail,
    String? pendingFullName,
  }) {
    return AuthState(
      status: status ?? this.status,
      errorMessage: errorMessage,
      pendingEmail: pendingEmail ?? this.pendingEmail,
      pendingFullName: pendingFullName ?? this.pendingFullName,
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  static const String _pendingEmailKey = 'pending_reg_email';
  static const String _pendingNameKey = 'pending_reg_name';

  @override
  AuthState build() {
    final supabase = ref.watch(supabaseClientProvider);
    supabase.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      if (event == AuthChangeEvent.passwordRecovery) {
        state = state.copyWith(status: AuthStatus.passwordRecovery);
      }
    });

    _loadPersistentState();

    return AuthState();
  }

  Future<void> _loadPersistentState() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString(_pendingEmailKey);
    final name = prefs.getString(_pendingNameKey);

    if (email != null) {
      state = state.copyWith(
        pendingEmail: email,
        pendingFullName: name,
      );
    }
  }

  Future<void> register({
    required String email,
    required String password,
    required String fullName,
    required String role,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final repository = ref.read(authRepositoryProvider);
      await repository.register(
        email: email,
        password: password,
        fullName: fullName,
        role: role,
      );
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_pendingEmailKey, email);
      await prefs.setString(_pendingNameKey, fullName);

      state = state.copyWith(
        status: AuthStatus.otpSent,
        pendingEmail: email,
        pendingFullName: fullName,
      );
    } catch (e) {
      final errorStr = e.toString().toLowerCase();
      String userMessage = e.toString().replaceAll('Exception:', '').trim();

      if (errorStr.contains('rate limit') ||
          errorStr.contains('429') ||
          errorStr.contains('email limit')) {
        userMessage =
            'Demasiados envíos de correo. Por favor, espera un minuto e intenta de nuevo.';
      }

      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: userMessage,
      );
    }
  }

  Future<void> verifyOtp({
    required String email,
    required String tokenPin,
    required String fullName,
    required String role,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final repository = ref.read(authRepositoryProvider);
      await repository.verifyOtpAndSync(
        email: email,
        tokenPin: tokenPin,
        fullName: fullName,
        role: role,
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_pendingEmailKey);
      await prefs.remove(_pendingNameKey);

      state = state.copyWith(
        status: AuthStatus.authenticated,
        pendingEmail: null,
        pendingFullName: null,
      );
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString().replaceAll('Exception:', '').trim(),
      );
    }
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);

    try {
      final repository = ref.read(authRepositoryProvider);
      await repository.login(email: email, password: password);

      final aal = await repository.getAuthenticatorAssuranceLevel();
      final currentLvl = aal.currentLevel.toString();
      final nextLvl = aal.nextLevel.toString();

      if (currentLvl.contains('aal1') && nextLvl.contains('aal2')) {
        state = state.copyWith(status: AuthStatus.mfaRequired);
        return;
      }

      state = state.copyWith(status: AuthStatus.authenticated);
    } catch (e) {
      final errorStr = e.toString().toLowerCase();
      String userMessage = 'Email o contraseña incorrectos.';

      if (errorStr.contains('rate limit') || errorStr.contains('429')) {
        userMessage =
            'Demasiados intentos fallidos. Intenta de nuevo en un minuto.';
      }

      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: userMessage,
      );
    }
  }

  Future<void> signInWithGoogle() async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final repository = ref.read(authRepositoryProvider);
      await repository.signInWithGoogle();

      final aal = await repository.getAuthenticatorAssuranceLevel();
      final currentLvl = aal.currentLevel.toString();
      final nextLvl = aal.nextLevel.toString();

      if (currentLvl.contains('aal1') && nextLvl.contains('aal2')) {
        state = state.copyWith(status: AuthStatus.mfaRequired);
        return;
      }

      state = state.copyWith(status: AuthStatus.authenticated);
    } catch (e) {
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('cancel') || errorStr.contains('user-cancelled')) {
        state = state.copyWith(status: AuthStatus.initial, errorMessage: null);
        return;
      }

      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Error al iniciar sesión con Google.',
      );
    }
  }

  Future<void> logout() async {
    state = AuthState();
    ref.read(authStateProvider.notifier).updateUser(null);
    ref.read(setupCompletedProvider.notifier).reset();

    final repository = ref.read(authRepositoryProvider);
    await repository.logout();

    ref.invalidate(personalInfoProvider);
    ref.invalidate(actionPlanProvider);
    ref.invalidate(smartwatchProvider);
    ref.invalidate(spirometerProvider);
    ref.invalidate(weeklyTrendProvider);
    ref.invalidate(environmentalProvider);
    ref.invalidate(notificationSettingsProvider);
    ref.invalidate(measurementsProvider);
    ref.invalidate(predictionProvider);
  }

  void clearRecoveryState() {
    state = state.copyWith(status: AuthStatus.authenticated);
  }

  Future<void> sendPasswordResetEmail(String email) async {
    state = state.copyWith(status: AuthStatus.sendingEmail, errorMessage: null);
    try {
      final repository = ref.read(authRepositoryProvider);
      await repository.sendPasswordResetEmail(email);
      state = state.copyWith(status: AuthStatus.resetEmailSent);
    } catch (e) {
      final errorStr = e.toString().toLowerCase();
      String userMessage = 'Error al enviar el correo de recuperación.';

      if (errorStr.contains('rate limit') ||
          errorStr.contains('429') ||
          errorStr.contains('email limit')) {
        userMessage =
            'Límite de envíos alcanzado. Por favor, espera un minuto.';
      }

      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: userMessage,
      );
    }
  }

  Future<void> updatePassword(String newPassword, {String? oldPassword}) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final repository = ref.read(authRepositoryProvider);
      await repository.updatePassword(newPassword, oldPassword: oldPassword);
      state = state.copyWith(status: AuthStatus.passwordUpdateSuccess);
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString().replaceAll('Exception:', '').trim(),
      );
    }
  }

  Future<void> updateAvatar({
    required String avatarSeed,
    required String avatarBackground,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final repository = ref.read(authRepositoryProvider);
      final updatedUser = await repository.updateAvatar(
        avatarSeed: avatarSeed,
        avatarBackground: avatarBackground,
      );

      ref.read(authStateProvider.notifier).updateUser(updatedUser);

      state = state.copyWith(status: AuthStatus.authenticated);
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  void resetState() {
    SharedPreferences.getInstance().then((prefs) {
      prefs.remove(_pendingEmailKey);
      prefs.remove(_pendingNameKey);
    });
    state = AuthState();
  }

  Future<void> resendOtp(String email) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final repository = ref.read(authRepositoryProvider);
      await repository.resendOtp(email: email);
      state = state.copyWith(status: AuthStatus.otpSent);
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString().contains('429')
            ? 'Espera un minuto antes de pedir otro código.'
            : 'Error al reenviar el código.',
      );
    }
  }

  Future<void> verifyMfaCode({required String code}) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final repository = ref.read(authRepositoryProvider);
      final supabase = ref.read(supabaseClientProvider);

      final factors = await supabase.auth.mfa.listFactors();
      final totpFactor = factors.totp.firstWhere(
        (f) => f.status == FactorStatus.verified,
        orElse: () => throw AuthException(
          'No hay un factor 2FA configurado y verificado.',
        ),
      );

      await repository.challengeAndVerifyMfa(
        factorId: totpFactor.id,
        code: code,
      );

      state = state.copyWith(status: AuthStatus.authenticated);
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.mfaRequired,
        errorMessage: 'Código de 6 dígitos incorrecto.',
      );
    }
  }

  Future<String> assignDoctor(String doctorCode) async {
    try {
      final repository = ref.read(authRepositoryProvider);
      final message = await repository.assignDoctor(doctorCode: doctorCode);
      
      ref.invalidate(personalInfoProvider);
      
      return message;
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception:', '').trim());
    }
  }
}

final authNotifierProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});
