import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'firebase_options.dart';
import 'config/router/app_router.dart';
import 'presentation/auth/providers/auth_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
// import 'package:intl/date_symbol_data_local.dart'; // Removido por Jank
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:toastification/toastification.dart';
import 'presentation/home/providers/push_notifications_provider.dart';
import 'infrastructure/notifications/services/local_notification_service.dart';
import 'infrastructure/services/background_sync_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Inicializar Supabase
  await Supabase.initialize(
    url: 'https://gspjcaqonnvrzuviqrjq.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdzcGpjYXFvbm52cnp1dmlxcmpxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjY4Njk5NjMsImV4cCI6MjA4MjQ0NTk2M30.H-V78osW0tkcTfFQbIKKtEAdoEbhyQnVznwQCTiyOWw',
  );

  // Inicializar notificaciones locales
  await LocalNotificationService.init();

  // Inicializar trabajo en segundo plano
  await BackgroundSyncService.initialize();

  // Precargar preferencias del sistema
  final prefs = await SharedPreferences.getInstance();
  final onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;
  final setupCompleted = prefs.getBool('is_setup_completed') ?? false;

  runApp(
    ProviderScope(
      overrides: [
        onboardingCompletedProvider.overrideWith(
          () => PreloadedOnboardingNotifier(onboardingCompleted),
        ),
        setupCompletedProvider.overrideWith(
          () => PreloadedSetupNotifier(setupCompleted),
        ),
      ],
      child: const MainApp(),
    ),
  );
}

class PreloadedOnboardingNotifier extends OnboardingNotifier {
  final bool initialValue;
  PreloadedOnboardingNotifier(this.initialValue);

  @override
  bool build() {
    return initialValue;
  }
}

class PreloadedSetupNotifier extends SetupCompletedNotifier {
  final bool initialValue;
  PreloadedSetupNotifier(this.initialValue);

  @override
  bool build() {
    return initialValue;
  }
}

class MainApp extends ConsumerWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Configurar notificaciones push
    ref.listen(pushNotificationsProvider, (_, __) {});
    
    final router = ref.watch(appRouterProvider);

    return ToastificationWrapper(
      child: MaterialApp.router(
        title: 'Asthma App',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF023E8A)),
          useMaterial3: true,
          fontFamily: 'Satoshi',
        ),
        routerConfig: router,
        // Idioma de la aplicación
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('es', 'ES'), // Español
          Locale('en', 'US'), // Inglés
        ],
        locale: const Locale('es', 'ES'), // Idioma por defecto
      ),
    );
  }
}
