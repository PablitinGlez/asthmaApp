import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/auth/entities/user_profile_entity.dart';
import '../../auth/providers/auth_provider.dart';

class PersonalInfoState {
  final UserProfileEntity? profile;
  final bool isLoading;
  final bool isSaving;
  final String? errorMessage;

  PersonalInfoState({
    this.profile,
    this.isLoading = true,
    this.isSaving = false,
    this.errorMessage,
  });

  PersonalInfoState copyWith({
    UserProfileEntity? profile,
    bool? isLoading,
    bool? isSaving,
    String? errorMessage,
  }) {
    return PersonalInfoState(
      profile: profile ?? this.profile,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class PersonalInfoNotifier extends Notifier<PersonalInfoState> {
  @override
  PersonalInfoState build() {
    // Solo cargamos el perfil una vez al entrar a la pantalla
    Future.microtask(() => _loadProfile());
    return PersonalInfoState();
  }

  Future<void> _loadProfile() async {
    try {
      final repository = ref.read(authRepositoryProvider);
      final profile = await repository.getProfile();
      state = state.copyWith(profile: profile, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<bool> updateProfile(Map<String, dynamic> data) async {
    state = state.copyWith(isSaving: true, errorMessage: null);
    try {
      final repository = ref.read(authRepositoryProvider);
      final updatedProfile = await repository.updateProfile(profileData: data);
      state = state.copyWith(profile: updatedProfile, isSaving: false);

      // 🔥 SINCRONIZACIÓN DE IDENTIDAD EN LA APP:
      // Si el nombre cambió, actualizamos el AuthState para que se refleje 
      // en el Header, Dashboard y mensajes de Bienvenida al instante.
      final authNotifier = ref.read(authStateProvider.notifier);
      final currentUser = ref.read(authStateProvider).value;
      if (currentUser != null && (data.containsKey('first_name') || data.containsKey('last_name'))) {
        final newFirstName = data['first_name'] ?? updatedProfile.firstName ?? '';
        final newLastName = data['last_name'] ?? updatedProfile.lastName ?? '';
        final newFullName = '$newFirstName $newLastName'.trim();
        
        authNotifier.updateUser(currentUser.copyWith(fullName: newFullName));
      }

      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, errorMessage: e.toString());
      return false;
    }
  }
}

final personalInfoProvider =
    NotifierProvider<PersonalInfoNotifier, PersonalInfoState>(() {
      return PersonalInfoNotifier();
    });
