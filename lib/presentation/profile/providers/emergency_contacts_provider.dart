import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../infrastructure/models/emergency_contact_model.dart';
import '../../auth/providers/auth_provider.dart';

// ─── State ───────────────────────────────────────────────────────────────────

class EmergencyContactsState {
  final bool isLoading;
  final String? errorMessage;
  final bool isSuccess;
  final List<EmergencyContactModel> contacts;

  EmergencyContactsState({
    this.isLoading = false,
    this.errorMessage,
    this.isSuccess = false,
    this.contacts = const [],
  });

  EmergencyContactsState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool? isSuccess,
    List<EmergencyContactModel>? contacts,
  }) {
    return EmergencyContactsState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      isSuccess: isSuccess ?? this.isSuccess,
      contacts: contacts ?? this.contacts,
    );
  }
}

// ─── Notifier ─────────────────────────────────────────────────────────────────

class EmergencyContactsNotifier extends Notifier<EmergencyContactsState> {
  @override
  EmergencyContactsState build() {
    Future.microtask(() => loadContacts());
    return EmergencyContactsState();
  }

  Future<void> loadContacts() async {
    state = state.copyWith(isLoading: true);
    try {
      final dioClient = ref.read(dioClientProvider);
      final supabaseAuthDS = ref.read(supabaseAuthDataSourceProvider);
      final token = await supabaseAuthDS.getIdToken();
      if (token == null) return;

      final response = await dioClient.get(
        '/api/emergency-contacts',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        final contacts = data
            .map(
              (json) =>
                  EmergencyContactModel.fromJson(json as Map<String, dynamic>),
            )
            .toList();
        state = state.copyWith(isLoading: false, contacts: contacts);
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error al cargar los contactos',
      );
    }
  }

  Future<void> createContact({
    required String name,
    required String phone,
    String? relationship,
    bool isPrimary = false,
  }) async {
    state = state.copyWith(isLoading: true, isSuccess: false);
    try {
      final dioClient = ref.read(dioClientProvider);
      final supabaseAuthDS = ref.read(supabaseAuthDataSourceProvider);
      final token = await supabaseAuthDS.getIdToken();
      if (token == null) return;

      await dioClient.post(
        '/api/emergency-contacts',
        data: {
          'contact_name': name,
          'phone_number': phone,
          'relationship': relationship,
          'is_primary': isPrimary,
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      await loadContacts();
      state = state.copyWith(isSuccess: true);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error al crear el contacto',
      );
    }
  }

  Future<void> updateContact({
    required int contactId,
    required String name,
    required String phone,
    String? relationship,
    required bool isPrimary,
  }) async {
    state = state.copyWith(isLoading: true, isSuccess: false);
    try {
      final dioClient = ref.read(dioClientProvider);
      final supabaseAuthDS = ref.read(supabaseAuthDataSourceProvider);
      final token = await supabaseAuthDS.getIdToken();
      if (token == null) return;

      await dioClient.put(
        '/api/emergency-contacts/$contactId',
        data: {
          'contact_name': name,
          'phone_number': phone,
          'relationship': relationship,
          'is_primary': isPrimary,
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      await loadContacts();
      state = state.copyWith(isSuccess: true);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error al actualizar el contacto',
      );
    }
  }

  Future<void> deleteContact(int contactId) async {
    state = state.copyWith(isLoading: true);
    try {
      final dioClient = ref.read(dioClientProvider);
      final supabaseAuthDS = ref.read(supabaseAuthDataSourceProvider);
      final token = await supabaseAuthDS.getIdToken();
      if (token == null) return;

      await dioClient.delete(
        '/api/emergency-contacts/$contactId',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      await loadContacts();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error al eliminar el contacto',
      );
    }
  }

  void resetState() {
    state = state.copyWith(isSuccess: false, errorMessage: null);
  }
}

// ─── Provider ─────────────────────────────────────────────────────────────────

final emergencyContactsProvider =
    NotifierProvider<EmergencyContactsNotifier, EmergencyContactsState>(() {
      return EmergencyContactsNotifier();
    });
