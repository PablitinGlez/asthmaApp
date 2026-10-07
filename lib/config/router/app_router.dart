import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../presentation/splash/splash_screen.dart';
import '../../presentation/onboarding/onboarding_screen.dart';
import '../../presentation/auth/screens/login_screen.dart';
import '../../presentation/auth/screens/register_screen.dart';
import '../../presentation/auth/screens/role_selection_screen.dart';
import '../../presentation/auth/screens/forgot_password_screen.dart';
import '../../presentation/home/screens/home_screen.dart';
import '../../presentation/home/screens/guardian_home_screen.dart';
import '../../presentation/profile/screens/edit_avatar_screen.dart';
import '../../presentation/auth/providers/auth_provider.dart';
import '../../presentation/screens/setup/setup_wizard_screen.dart';
import '../../presentation/notifications/screens/notifications_screen.dart';
import '../../presentation/notifications/screens/notifications_history_screen.dart';
import '../../presentation/symptoms/screens/register_symptom_screen.dart';
import '../../presentation/action_plan/screens/action_plan_screen.dart';
import '../../presentation/profile/screens/permissions_screen.dart';
import '../../presentation/profile/screens/permission_guide_screen.dart';
import '../../presentation/profile/screens/personal_info_screen.dart';
import '../../presentation/profile/screens/help_support_screen.dart';
import '../../presentation/profile/screens/about_screen.dart';
import '../../presentation/profile/screens/legal_content_screen.dart';
import '../../presentation/home/screens/device_scanner_screen.dart';
import '../../presentation/home/screens/spirometer_screen.dart';
import '../../presentation/auth/screens/otp_verification_screen.dart';
import '../../presentation/auth/screens/reset_password_screen.dart';
import '../../presentation/home/providers/smartwatch_provider.dart';
import '../../presentation/home/providers/spirometer_provider.dart';
import '../../presentation/auth/providers/auth_notifier.dart';
import '../../presentation/profile/screens/emergency_contacts_screen.dart';
import '../../presentation/home/screens/my_devices_screen.dart';
import '../../presentation/profile/screens/mfa_setup_screen.dart';
import '../../presentation/auth/screens/mfa_verification_screen.dart';
import '../../presentation/medications/screens/medications_screen.dart';
import '../../presentation/home/screens/sos_screen.dart';
import '../../presentation/profile/screens/appearance_screen.dart';
import '../../presentation/chat/screens/chat_list_screen.dart';
import '../../presentation/chat/screens/chat_detail_screen.dart';
import '../../presentation/home/screens/vitals_detail_screen.dart';

class AuthRouterNotifier extends ChangeNotifier {
  final Ref _ref;

  AuthRouterNotifier(this._ref) {
    _ref.listen(authStateProvider, (previous, next) {
      final prevUser = previous?.value;
      final nextUser = next.value;

      final wasLoading = previous?.isLoading ?? true;
      final isNowLoading = next.isLoading;

      final loadingFinished = wasLoading && !isNowLoading;
      final loginStatusChanged = (prevUser == null) != (nextUser == null);
      final setupStatusChanged =
          prevUser?.isSetupCompleted != nextUser?.isSetupCompleted;

      if (loadingFinished || loginStatusChanged || setupStatusChanged) {
        notifyListeners();
      }
    });

    _ref.listen(onboardingCompletedProvider, (previous, next) {
      notifyListeners();
    });

    _ref.listen(setupCompletedProvider, (previous, next) {
      notifyListeners();
    });

    _ref.listen(authNotifierProvider, (previous, next) {
      final statusChanged = previous?.status != next.status;
      final pendingChanged = previous?.pendingEmail != next.pendingEmail;

      if (pendingChanged || statusChanged) {
        final wasAuth = previous?.status == AuthStatus.authenticated;
        final isLoad = next.status == AuthStatus.loading;

        if (wasAuth && isLoad) return;

        final hasUser = _ref.read(authStateProvider).value != null;
        if (hasUser &&
            previous?.status == AuthStatus.loading &&
            next.status == AuthStatus.authenticated) {
          return;
        }

        notifyListeners();
      }
    });

    _ref.read(smartwatchProvider);
    _ref.read(spirometerProvider);

    _ref.listen(setupCompletedProvider, (previous, next) {
      if (previous != next) {
        notifyListeners();
      }
    });
  }
}

final authRouterNotifierProvider = Provider<AuthRouterNotifier>((ref) {
  return AuthRouterNotifier(ref);
});

final appRouterProvider = Provider<GoRouter>((ref) {
  final routerNotifier = ref.watch(authRouterNotifierProvider);

  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: false,
    refreshListenable: routerNotifier,
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);
      final onboardingCompleted = ref.read(onboardingCompletedProvider);
      final localSetupDone = ref.read(setupCompletedProvider);

      final isLoadingAuth = authState.isLoading;
      final user = authState.value;
      final isLoggedIn = user != null;
      final hasCompletedOnboarding = onboardingCompleted;

      final currentLocation = state.matchedLocation;

      final isOnSplash = currentLocation == '/';
      final isOnLogin = currentLocation == '/login';
      final isOnRegister = currentLocation == '/register';
      final isOnForgotPassword = currentLocation == '/forgot-password';
      final isOnOnboarding = currentLocation == '/onboarding';
      final isOnSetup = currentLocation == '/setup';
      final isOnOtp = currentLocation == '/otp-verification';
      final isOnResetPassword = currentLocation == '/reset-password';
      final isOnMfaVerify = currentLocation == '/mfa-verify';
      final isOnRoleSelection = currentLocation == '/role-selection';

      final hasSession = Supabase.instance.client.auth.currentSession != null;
      final authStatus = ref.read(authNotifierProvider).status;
      final isFetchingProfile =
          hasSession && user == null && authStatus != AuthStatus.initial;

      if (isLoadingAuth || isFetchingProfile) {
        final isAuthScreen =
            isOnLogin ||
            isOnRegister ||
            isOnForgotPassword ||
            isOnOtp ||
            isOnResetPassword ||
            isOnMfaVerify;
        if (!isOnSplash && !isAuthScreen) return '/';
        return null;
      }

      if (!isLoggedIn && !hasCompletedOnboarding) {
        if (!isOnOnboarding) return '/onboarding';
        return null;
      }

      final pendingEmail = ref.read(authNotifierProvider).pendingEmail;

      if (pendingEmail != null && !isLoggedIn) {
        if (!isOnOtp) {
          return '/otp-verification';
        }
        return null;
      }

      if (isOnResetPassword && authStatus == AuthStatus.loading) {
        return null;
      }

      if (ref.read(authNotifierProvider).isPasswordRecovery) {
        if (!isOnResetPassword) {
          return '/reset-password';
        }
        return null;
      }

      if (authStatus == AuthStatus.mfaRequired) {
        if (!isOnMfaVerify) {
          return '/mfa-verify';
        }
        return null;
      }

      if (!isLoggedIn) {
        if (isLoadingAuth || isFetchingProfile) return null;

        if (isOnSplash) return '/login';

        if (isOnLogin ||
            isOnRegister ||
            isOnForgotPassword ||
            isOnOtp ||
            isOnResetPassword ||
            isOnMfaVerify) {
          return null;
        }

        return '/login';
      }

      if (isLoggedIn && user.role == 'pending') {
        if (!isOnRoleSelection) return '/role-selection';
        return null;
      }

      if (isLoggedIn) {
        if (user.isSetupCompleted && !localSetupDone) {
          Future.microtask(
            () => ref.read(setupCompletedProvider.notifier).complete(),
          );
        }

        if (!user.isSetupCompleted &&
            !localSetupDone &&
            user.role != 'guardian') {
          if (!isOnSetup) return '/setup';
          return null;
        }

        final isOnAuthSystem =
            isOnSetup ||
            isOnRoleSelection ||
            isOnLogin ||
            isOnRegister ||
            isOnForgotPassword ||
            isOnSplash ||
            isOnOtp ||
            isOnMfaVerify ||
            isOnOnboarding;

        final isOnSos = currentLocation == '/sos';
        if (isOnSos) return null;

        if (isOnAuthSystem) {
          return user.role == 'guardian' ? '/guardian-home' : '/home';
        }

        if (user.role == 'guardian' && currentLocation == '/home')
          return '/guardian-home';
        if (user.role == 'patient' && currentLocation == '/guardian-home')
          return '/home';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/role-selection',
        name: 'role-selection',
        builder: (context, state) => const RoleSelectionScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        name: 'forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/otp-verification',
        name: 'otp-verification',
        builder: (context, state) => const OtpVerificationScreen(),
      ),
      GoRoute(
        path: '/reset-password',
        name: 'reset-password',
        builder: (context, state) => const ResetPasswordScreen(),
      ),
      GoRoute(
        path: '/change-password',
        name: 'change-password',
        builder: (context, state) => const ResetPasswordScreen(),
      ),
      GoRoute(
        path: '/mfa-setup',
        name: 'mfa-setup',
        builder: (context, state) => const MfaSetupScreen(),
      ),
      GoRoute(
        path: '/mfa-verify',
        name: 'mfa-verify',
        builder: (context, state) => const MfaVerificationScreen(),
      ),
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/guardian-home',
        name: 'guardian-home',
        builder: (context, state) => const GuardianHomeScreen(),
      ),
      GoRoute(
        path: '/edit-avatar',
        name: 'edit-avatar',
        builder: (context, state) => const EditAvatarScreen(),
      ),
      GoRoute(
        path: '/setup',
        name: 'setup',
        builder: (context, state) => const SetupWizardScreen(),
      ),
      GoRoute(
        path: '/notifications',
        name: 'notifications',
        builder: (context, state) => const NotificationsHistoryScreen(),
        routes: [
          GoRoute(
            path: 'settings',
            name: 'notification-settings',
            builder: (context, state) => const NotificationsScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/register-symptom',
        name: 'register-symptom',
        builder: (context, state) => const RegisterSymptomScreen(),
      ),
      GoRoute(
        path: '/action-plan',
        name: 'action-plan',
        builder: (context, state) {
          final isReadOnly = state.extra as bool? ?? false;
          return ActionPlanScreen(isReadOnly: isReadOnly);
        },
      ),
      GoRoute(
        path: '/medications',
        name: 'medications',
        builder: (context, state) => const MedicationsScreen(),
      ),
      GoRoute(
        path: '/permissions',
        name: 'permissions',
        builder: (context, state) => const PermissionsScreen(),
      ),
      GoRoute(
        path: '/permissions-guide',
        name: 'permissions-guide',
        builder: (context, state) => const PermissionGuideScreen(),
      ),
      GoRoute(
        path: '/appearance',
        name: 'appearance',
        builder: (context, state) => const AppearanceScreen(),
      ),
      GoRoute(
        path: '/personal-info',
        name: 'personal-info',
        builder: (context, state) => const PersonalInfoScreen(),
      ),
      GoRoute(
        path: '/spirometer',
        name: 'spirometer',
        builder: (context, state) => const SpirometerScreen(),
      ),
      GoRoute(
        path: '/device-scanner',
        name: 'device-scanner',
        builder: (context, state) => const DeviceScannerScreen(),
      ),
      GoRoute(
        path: '/emergency-contacts',
        name: 'emergency-contacts',
        builder: (context, state) => const EmergencyContactsScreen(),
      ),
      GoRoute(
        path: '/my-devices',
        name: 'my-devices',
        builder: (context, state) => const MyDevicesScreen(),
      ),
      GoRoute(
        path: '/help-support',
        name: 'help-support',
        builder: (context, state) => const HelpSupportScreen(),
      ),
      GoRoute(
        path: '/about',
        name: 'about',
        builder: (context, state) => const AboutScreen(),
      ),
      GoRoute(
        path: '/terms',
        name: 'terms',
        builder: (context, state) => const LegalContentScreen(
          title: 'Términos y Condiciones',
          content: '''
Bienvenido a AsthmaApp. Al utilizar esta aplicación, aceptas los siguientes términos:

1. Uso de la Aplicación
AsthmaApp es una herramienta de apoyo para el control del asma. No sustituye el consejo médico profesional. Siempre consulta a tu médico antes de realizar cambios en tu tratamiento.

2. Privacidad de Datos
Tus datos de salud se almacenan de forma segura. No compartimos tu información personal con terceros sin tu consentimiento explícito.

3. Responsabilidad
El usuario es responsable de la exactitud de los datos ingresados. AsthmaApp no se hace responsable por decisiones médicas tomadas basadas únicamente en la aplicación.

4. Modificaciones
Nos reservamos el derecho de modificar estos términos en cualquier momento. El uso continuado de la app implica la aceptación de los nuevos términos.
          ''',
        ),
      ),
      GoRoute(
        path: '/privacy',
        name: 'privacy',
        builder: (context, state) => const LegalContentScreen(
          title: 'Política de Privacidad',
          content: '''
Tu privacidad es nuestra prioridad en AsthmaApp. Aquí explicamos cómo manejamos tu información:

1. Recopilación de Información
Recopilamos datos de salud (PEF, síntomas) y datos de contacto básicos (nombre, email) para el funcionamiento de la app.

2. Uso de la Información
Tus datos se utilizan exclusivamente para:
- Mostrarte tendencias y gráficas de salud.
- Permitir que tu doctor (si lo autorizas) vea tu progreso.
- Notificar a tus contactos de emergencia si se detecta una alerta.

3. Almacenamiento Seguro
Utilizamos encriptación de grado bancario y servicios de nube líderes (Supabase) para proteger tus datos de accesos no autorizados.

4. Tus Derechos
Puedes solicitar la eliminación de tu cuenta y todos tus datos en cualquier momento desde el área de soporte.
          ''',
        ),
      ),
      GoRoute(
        path: '/sos',
        name: 'sos',
        builder: (context, state) => const SosScreen(),
      ),
      GoRoute(
        path: '/chat',
        name: 'chat-list',
        builder: (context, state) => const ChatListScreen(),
        routes: [
          GoRoute(
            path: ':conversationId',
            name: 'chat-detail',
            builder: (context, state) {
              final id = state.pathParameters['conversationId'] ?? '';
              return ChatDetailScreen(
                conversationId: id,
                conversation: state.extra,
              );
            },
          ),
        ],
      ),
      GoRoute(
        path: '/vitals-detail',
        name: 'vitals-detail',
        builder: (context, state) => const VitalsDetailScreen(),
      ),
    ],
  );
});
