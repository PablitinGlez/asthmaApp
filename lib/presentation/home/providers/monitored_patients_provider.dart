import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/auth/entities/user_entity.dart';
import '../../auth/providers/auth_provider.dart';

final monitoredPatientsProvider = NotifierProvider<MonitoredPatientsNotifier, AsyncValue<List<UserEntity>>>(() {
  return MonitoredPatientsNotifier();
});

class MonitoredPatientsNotifier extends Notifier<AsyncValue<List<UserEntity>>> {

  @override
  AsyncValue<List<UserEntity>> build() {
    
    Future.microtask(() => loadPatients());
    return const AsyncValue.loading();
  }

  Future<void> loadPatients() async {
    state = const AsyncValue.loading();
    try {
      final repository = ref.read(guardianRepositoryProvider);
      final patients = await repository.getMonitoredPatients();
      state = AsyncValue.data(patients);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> linkPatient(String code) async {
    try {
      final repository = ref.read(guardianRepositoryProvider);
      await repository.linkPatient(code);
      await loadPatients(); 
    } catch (e) {
      rethrow;
    }
  }
}

final patientLinkingCodeProvider = FutureProvider<String>((ref) async {
  final repository = ref.read(guardianRepositoryProvider);
  return await repository.getLinkingCode();
});
