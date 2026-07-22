import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/auth/repositories/auth_repository.dart';
import '../../auth/providers/auth_provider.dart';

class PatientGuardiansState {
  final bool isLoading;
  final String? linkingCode;
  final List<Map<String, dynamic>> guardians;
  final String? errorMessage;

  PatientGuardiansState({
    this.isLoading = true,
    this.linkingCode,
    this.guardians = const [],
    this.errorMessage,
  });

  PatientGuardiansState copyWith({
    bool? isLoading,
    String? linkingCode,
    List<Map<String, dynamic>>? guardians,
    String? errorMessage,
  }) {
    return PatientGuardiansState(
      isLoading: isLoading ?? this.isLoading,
      linkingCode: linkingCode ?? this.linkingCode,
      guardians: guardians ?? this.guardians,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class PatientGuardiansNotifier extends Notifier<PatientGuardiansState> {
  @override
  PatientGuardiansState build() {
    Future.microtask(() => loadData());
    return PatientGuardiansState();
  }

  Future<void> loadData() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final repository = ref.read(authRepositoryProvider);
      
      // Llamadas en paralelo para no bloquear mucho
      final results = await Future.wait([
        repository.getLinkingCode(),
        repository.getMyGuardians(),
      ]);

      final code = results[0] as String;
      final guardiansList = results[1] as List<Map<String, dynamic>>;

      state = state.copyWith(
        isLoading: false,
        linkingCode: code,
        guardians: guardiansList,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> unlinkGuardian(int guardianId) async {
    try {
      final repository = ref.read(authRepositoryProvider);
      await repository.unlinkGuardian(guardianId: guardianId);
      
      // Recargar lista
      await loadData();
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }
}

final patientGuardiansProvider =
    NotifierProvider<PatientGuardiansNotifier, PatientGuardiansState>(() {
  return PatientGuardiansNotifier();
});
