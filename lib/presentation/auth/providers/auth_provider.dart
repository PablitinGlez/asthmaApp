import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/auth/entities/user_entity.dart';
import '../../../domain/auth/repositories/auth_repository.dart';
import '../../../infrastructure/auth/datasources/auth_api_datasource.dart';
import '../../../infrastructure/auth/datasources/guardian_api_datasource.dart';
import '../../../infrastructure/auth/datasources/supabase_auth_datasource.dart';
import '../../../infrastructure/auth/repositories/auth_repository_impl.dart';
import '../../../infrastructure/auth/repositories/guardian_repository_impl.dart';
import '../../../domain/auth/repositories/guardian_repository.dart';
import '../../../config/network/dio_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final dioClientProvider = Provider<DioClient>((ref) {
  // PRODUCCIÓN (Render)
  const baseUrl = 'https://asthma-predictor-api.onrender.com';
  
  // LOCAL (Cambia esto por tu IP local si usas celular físico)
  // const baseUrl = 'http://10.0.2.2:8000'; // Para emulador Android
  // const baseUrl = 'http://192.168.1.XX:8000'; // Para celular físico en misma red
  
  return DioClient(baseUrl: baseUrl);
});

final authApiDataSourceProvider = Provider<AuthApiDataSource>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return AuthApiDataSource(client: dioClient);
});

final supabaseAuthDataSourceProvider = Provider<SupabaseAuthDataSource>((ref) {
  final supabaseClient = ref.watch(supabaseClientProvider);
  return SupabaseAuthDataSource(supabaseClient);
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final supabaseDS = ref.watch(supabaseAuthDataSourceProvider);
  final apiDS = ref.watch(authApiDataSourceProvider);

  return AuthRepositoryImpl(
    supabaseDataSource: supabaseDS,
    apiDataSource: apiDS,
  );
});

final guardianApiDataSourceProvider = Provider<GuardianApiDataSource>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return GuardianApiDataSource(client: dioClient);
});

final guardianRepositoryProvider = Provider<GuardianRepository>((ref) {
  final apiDS = ref.watch(guardianApiDataSourceProvider);
  final supabaseDS = ref.watch(supabaseAuthDataSourceProvider);
  return GuardianRepositoryImpl(
    apiDataSource: apiDS,
    supabaseDataSource: supabaseDS,
  );
});

// Notifier que escucha el flujo de Firebase y permite actualizaciones manuales (Mutation)
class AuthStateNotifier extends StreamNotifier<UserEntity?> {
  @override
  Stream<UserEntity?> build() {
    print(' AuthStateNotifier: Build called (Subscribing to Repository)');
    final repository = ref.watch(authRepositoryProvider);
    return repository.authStateChanges();
  }

  // Actualiza el estado manualmente sin disparar estados de 'Loading'
  void updateUser(UserEntity? user) {
    print(
      ' AuthStateNotifier: Mutating state with ${user == null ? 'NULL' : 'User data (${user.email})'}',
    );
    state = AsyncData(user);
    print(' AuthStateNotifier: Local state mutated successfully');
  }

  // Actualiza el rol del usuario en el backend y localmente
  Future<void> updateRole(String role) async {
    final repository = ref.read(authRepositoryProvider);
    state = const AsyncLoading();
    
    try {
      final updatedUser = await repository.updateRole(role: role);
      state = AsyncData(updatedUser);
      print(' AuthStateNotifier: Role updated to $role');
    } catch (e) {
      print(' AuthStateNotifier: Error updating role - $e');
      state = AsyncError(e, StackTrace.current);
    }
  }
}

// Provider que gestiona el estado global del usuario autenticado
final authStateProvider =
    StreamNotifierProvider<AuthStateNotifier, UserEntity?>(() {
      return AuthStateNotifier();
    });

// Provider auxiliar para PERSISTIR que el setup se completó (Solo UI)
class SetupCompletedNotifier extends Notifier<bool> {
  @override
  bool build() {
    final authState = ref.watch(authStateProvider);
    final user = authState.value;
    
    if (user == null) {
      return false;
    }
    
    _loadFromPrefs(user.id);
    return false; // Por defecto asumimos false hasta que se cargue
  }

  Future<void> _loadFromPrefs(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool('is_setup_completed_$userId') ?? false;
    if (state)
      print(' SetupCompletedNotifier: Persistence loaded for $userId -> Setup DONE');
  }

  Future<void> complete() async {
    final user = ref.read(authStateProvider).value;
    if (user == null) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_setup_completed_${user.id}', true);
    state = true;
    print(' SetupCompletedNotifier: Setup marked as DONE locally for ${user.id}');
  }

  Future<void> reset() async {
    final user = ref.read(authStateProvider).value;
    if (user == null) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('is_setup_completed_${user.id}');
    state = false;
  }
}

final setupCompletedProvider = NotifierProvider<SetupCompletedNotifier, bool>(
  () {
    return SetupCompletedNotifier();
  },
);

// Notifier para manejar el estado del onboarding (PERSISTENCIA UI)
class OnboardingNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void complete() {
    state = true;
  }

  void reset() {
    state = false;
  }
}

final onboardingCompletedProvider = NotifierProvider<OnboardingNotifier, bool>(
  OnboardingNotifier.new,
);
