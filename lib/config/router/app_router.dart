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

// Notifier para manejar el redireccionamiento basado en el estado
class AuthRouterNotifier extends ChangeNotifier {
  final Ref _ref;

  AuthRouterNotifier(this._ref) {
    // Escuchar cambios en authStateProvider de forma inteligente
    _ref.listen(authStateProvider, (previous, next) {
      final prevUser = previous?.value;
      final nextUser = next.value;

      final wasLoading = previous?.isLoading ?? true;
      final isNowLoading = next.isLoading;

      // Notificamos si:
      // 1. Terminó de cargar (Crucial para salir del Splash)
      // 2. El estado de logueo cambió (entró o salió)
      // 3. El estado de setup cambió
      final loadingFinished = wasLoading && !isNowLoading;
      final loginStatusChanged = (prevUser == null) != (nextUser == null);
      final setupStatusChanged =
          prevUser?.isSetupCompleted != nextUser?.isSetupCompleted;

      if (loadingFinished || loginStatusChanged || setupStatusChanged) {
        debugPrint(
          '🛤️ RouterNotifier: CRITICAL Change (Auth/Setup/Load) -> NotifyListeners',
        );
        notifyListeners();
      } else {
        debugPrint(
          '🛤️ RouterNotifier: Minor update detected. Skipping Router Refresh.',
        );
      }
    });

    // Escuchar cambios en onboardingCompletedProvider
    _ref.listen(onboardingCompletedProvider, (previous, next) {
      print('🛤️ RouterNotifier: Onboarding changed -> NotifyListeners');
      notifyListeners();
    });

    // Escuchar cambios en setupCompletedProvider (Simulación local)
    _ref.listen(setupCompletedProvider, (previous, next) {
      print('🛤️ RouterNotifier: Setup Local changed -> NotifyListeners');
      notifyListeners();
    });

    // Escuchar el estado de AuthNotifier (Para detectar pendingEmail y passwordRecovery)
    _ref.listen(authNotifierProvider, (previous, next) {
      final statusChanged = previous?.status != next.status;
      final pendingChanged = previous?.pendingEmail != next.pendingEmail;

      if (pendingChanged || statusChanged) {
        // OPTIMIZACIÓN: Si ya estábamos autenticados y solo estamos pasando por 'loading'
        // para una actualización interna (como el avatar), NO refrescamos el router.
        // Esto evita parpadeos, interrupciones de animaciones (pops) y flickers.
        final wasAuth = previous?.status == AuthStatus.authenticated;
        final isLoad = next.status == AuthStatus.loading;

        // Caso 1: Pasando de Auth a Loading (empieza el guardado)
        if (wasAuth && isLoad) return;

        // Caso 2: Volviendo de Loading a Auth (terminó el guardado exitoso)
        // Verificamos si seguimos teniendo datos de usuario en el Stream
        final hasUser = _ref.read(authStateProvider).value != null;
        if (hasUser &&
            previous?.status == AuthStatus.loading &&
            next.status == AuthStatus.authenticated) {
          return;
        }

        print(
          '🛤️ RouterNotifier: AuthNotifier status changed (${next.status}) -> NotifyListeners',
        );
        notifyListeners();
      }
    });

    // Leerlos para desencadenar las llamadas y no tener esqueletos
    _ref.read(smartwatchProvider);
    _ref.read(spirometerProvider);

    // Escuchar cambios en la persistencia del Setup
    _ref.listen(setupCompletedProvider, (previous, next) {
      if (previous != next) {
        print(
          '🛤️ RouterNotifier: setupCompleted status changed ($next) -> NotifyListeners',
        );
        notifyListeners();
      }
    });
  }
}

final authRouterNotifierProvider = Provider<AuthRouterNotifier>((ref) {
  return AuthRouterNotifier(ref);
});

// Provider del GoRouter
final appRouterProvider = Provider<GoRouter>((ref) {
  final routerNotifier = ref.watch(authRouterNotifierProvider);

  print('🚀 appRouterProvider: Creating GoRouter Instance (Only once!)');

  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: false,
    refreshListenable: routerNotifier,
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);
      final onboardingCompleted = ref.read(onboardingCompletedProvider);
      final localSetupDone = ref.read(
        setupCompletedProvider,
      ); // PERSISTENCIA LOCAL

      final isLoadingAuth = authState.isLoading;
      final user = authState.value;
      final isLoggedIn = user != null;
      final hasCompletedOnboarding = onboardingCompleted;

      final currentLocation = state.matchedLocation;
      print(
        '🔍 ROUTER REDIRECT: location=$currentLocation, user=${user?.email}, loading=$isLoadingAuth',
      );
      // ============================================
      // 2. TOMA DE DECISIONES DE RUTAS (Ya validadas)
      // ============================================

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

      // Si Supabase ya tiene la sesión en disco PERO nuestro 'user' de FastAPI
      // todavía es null (cargando), congelamos la pantalla en el Splash.
      final hasSession = Supabase.instance.client.auth.currentSession != null;
      final authStatus = ref.read(authNotifierProvider).status;
      final isFetchingProfile =
          hasSession && user == null && authStatus != AuthStatus.initial;

      if (isOnSplash || isOnLogin || isOnRegister || isOnSetup) {
        print('================ 🚦 ESTADO DEL ROUTER 🚦 ================');
        print('📍 Rutas       : isOnSplash=$isOnSplash, isOnSetup=$isOnSetup');
        print('⏳ Auth        : isLoadingAuth=$isLoadingAuth');
        print(
          '👀 Perfil      : isFetchingProfile=$isFetchingProfile (hasSession=$hasSession, user=${user?.email})',
        );
        print(
          '✅ Setup       : API=${user?.isSetupCompleted}, LOCAL=$localSetupDone',
        );
        print('=========================================================');
      }

      // GUARDIA: Esperamos a que el Stream de auth se resuelva con un usuario real
      if (isLoadingAuth || isFetchingProfile) {
        // Redirigimos al Splash SOLO si no estamos ya en una pantalla de Auth
        // Esto evita el "parpadeo" blanco/azul al loguearse o verificar OTP
        final isAuthScreen =
            isOnLogin ||
            isOnRegister ||
            isOnForgotPassword ||
            isOnOtp ||
            isOnResetPassword ||
            isOnMfaVerify;
        if (!isOnSplash && !isAuthScreen) return '/';
        return null; // Si ya estamos en Login/OTP/etc, nos quedamos ahí mientras carga
      }

      // 2. Si no ha completado el Onboarding visual y no está logueado -> Onboarding
      if (!isLoggedIn && !hasCompletedOnboarding) {
        if (!isOnOnboarding) return '/onboarding';
        return null;
      }

      // 3. pendingEmail existe -> Redirigir a OTP sin importar nada más
      final pendingEmail = ref.read(authNotifierProvider).pendingEmail;

      if (pendingEmail != null && !isLoggedIn) {
        if (!isOnOtp) {
          print('🏠 ROUTER: Redirecting to /otp-verification (Pending OTP)');
          return '/otp-verification';
        }
        return null; // Ya está ahí
      }

      // --- RECUPERACIÓN DE CONTRASEÑA ---
      if (isOnResetPassword && authStatus == AuthStatus.loading) {
        return null;
      }

      if (ref.read(authNotifierProvider).isPasswordRecovery) {
        if (!isOnResetPassword) {
          print('🏠 ROUTER: Redirecting to /reset-password (Recovery Mode)');
          return '/reset-password';
        }
        return null;
      }

      // --- MFA REQUIRED ---
      if (authStatus == AuthStatus.mfaRequired) {
        if (!isOnMfaVerify) {
          print('🏠 ROUTER: Redirecting to /mfa-verify (MFA Required)');
          return '/mfa-verify';
        }
        return null;
      }

      // 4. Si NO está logueado
      if (!isLoggedIn) {
        // Si estamos en medio de una carga (SplashScreen), nos quedamos ahí
        if (isLoadingAuth || isFetchingProfile) return null;

        if (isOnSplash) return '/login';

        // Si ya está en una pantalla de auth permitida, no redirigir
        if (isOnLogin ||
            isOnRegister ||
            isOnForgotPassword ||
            isOnOtp ||
            isOnResetPassword ||
            isOnMfaVerify) {
          return null;
        }

        // Si intenta acceder a cualquier otra pantalla (Home, Setup, etc) sin sesión -> Login
        return '/login';
      }

      // 5. Si ESTÁ logueado pero el ROL es PENDING (NUEVO)
      if (isLoggedIn && user.role == 'pending') {
        if (!isOnRoleSelection) return '/role-selection';
        return null;
      }

      // 4. Si ESTÁ logueado
      if (isLoggedIn) {
        // ── AUTO-SYNC: Si el API dice que el setup ya está hecho pero LOCAL
        // no lo sabe aún (fresh install, borrado de datos), lo sincronizamos.
        if (user.isSetupCompleted && !localSetupDone) {
          // Disparamos en background, no bloqueamos el redirect
          Future.microtask(
            () => ref.read(setupCompletedProvider.notifier).complete(),
          );
        }

        // **USUARIO SIN SETUP MEDICO COMPLETO**
        // Skip solo si AMBOS (API y Local) dicen que falta, Y no es un guardián
        if (!user.isSetupCompleted &&
            !localSetupDone &&
            user.role != 'guardian') {
          if (!isOnSetup) return '/setup';
          return null;
        }

        // **USUARIO CON SESIÓN Y SETUP AL DÍA**
        // Si ya completó setup, pero intenta volver a pantallas de auth/onboarding/onboarding -> Home
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

        // EXCEPCIÓN CRÍTICA: Si ya estamos en SOS, no hacemos nada (nos quedamos ahí)
        final isOnSos = currentLocation == '/sos';
        if (isOnSos) return null;

        if (isOnAuthSystem) {
          print('🏠 ROUTER: Redirecting to /home (Session active)');
          return user.role == 'guardian' ? '/guardian-home' : '/home';
        }

        // Prevención de cruce de roles
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
    ],
  );
});

// Notifier para manejar el estado del onboarding se movió a auth_provider.dart
