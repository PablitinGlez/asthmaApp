import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'firebase_options.dart';
import 'config/router/app_router.dart';
import 'presentation/auth/providers/auth_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:toastification/toastification.dart';
import 'presentation/home/providers/push_notifications_provider.dart';
import 'infrastructure/notifications/services/local_notification_service.dart';
import 'infrastructure/services/background_sync_service.dart';
import 'presentation/profile/providers/appearance_provider.dart';
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await Supabase.initialize(
    url: 'https://gspjcaqonnvrzuviqrjq.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdzcGpjYXFvbm52cnp1dmlxcmpxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjY4Njk5NjMsImV4cCI6MjA4MjQ0NTk2M30.H-V78osW0tkcTfFQbIKKtEAdoEbhyQnVznwQCTiyOWw',
  );

  await LocalNotificationService.init();
  await BackgroundSyncService.initialize();

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
    ref.listen(pushNotificationsProvider, (_, __) {});

    final router = ref.watch(appRouterProvider);
    final appearance = ref.watch(appearanceProvider);

    return ToastificationWrapper(
      child: MaterialApp.router(
        title: 'Asthma App',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(appearance.seedColor, Brightness.light),
        darkTheme: buildAppTheme(appearance.seedColor, Brightness.dark),
        themeMode: appearance.themeMode,
        routerConfig: router,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('es', 'ES'),
          Locale('en', 'US'),
        ],
        locale: const Locale('es', 'ES'),
      ),
    );
  }
}

