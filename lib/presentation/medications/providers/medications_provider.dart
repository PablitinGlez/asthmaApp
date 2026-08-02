import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../domain/models/medication.dart';
import '../../../infrastructure/medications/datasources/medication_api_datasource.dart';
import '../../../infrastructure/medications/repositories/medication_repository_impl.dart';

class MedicationsState {
  final List<Medication> medications;
  final bool isLoading;
  final String? errorMessage;

  MedicationsState({
    this.medications = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  MedicationsState copyWith({
    List<Medication>? medications,
    bool? isLoading,
    String? errorMessage,
  }) {
    return MedicationsState(
      medications: medications ?? this.medications,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class MedicationsNotifier extends Notifier<MedicationsState> {
  @override
  MedicationsState build() {
    
    Future.microtask(() => loadMedications());
    return MedicationsState();
  }

  MedicationRepository get _repository => ref.read(medicationRepositoryProvider);

  Future<String> _getToken() async {
    final session = ref.read(supabaseClientProvider).auth.currentSession;
    if (session == null) throw Exception('No hay sesión activa');
    return session.accessToken;
  }

  Future<void> loadMedications() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final token = await _getToken();
      final medications = await _repository.getMedications(token);
      state = state.copyWith(medications: medications, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<bool> addMedication(Map<String, dynamic> data) async {
    try {
      final token = await _getToken();
      final newMed = await _repository.createMedication(token, data);
      state = state.copyWith(
        medications: [...state.medications, newMed],
      );
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> updateMedication(int id, Map<String, dynamic> data) async {
    try {
      final token = await _getToken();
      final updatedMed = await _repository.updateMedication(token, id, data);
      state = state.copyWith(
        medications: state.medications
            .map((m) => m.id == id ? updatedMed : m)
            .toList(),
      );
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> deleteMedication(int id) async {
    try {
      final token = await _getToken();
      await _repository.deleteMedication(token, id);
      state = state.copyWith(
        medications: state.medications.where((m) => m.id != id).toList(),
      );
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> registerDose(int id) async {
    try {
      final token = await _getToken();
      final updatedMed = await _repository.registerDose(token, id);
      state = state.copyWith(
        medications: state.medications
            .map((m) => m.id == id ? updatedMed : m)
            .toList(),
      );
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }
}

final medicationRepositoryProvider = Provider<MedicationRepository>((ref) {
  final dioClient = ref.read(dioClientProvider);
  final dataSource = MedicationApiDataSource(client: dioClient);
  return MedicationRepositoryImpl(dataSource: dataSource);
});

final medicationsProvider = NotifierProvider<MedicationsNotifier, MedicationsState>(() {
  return MedicationsNotifier();
});
