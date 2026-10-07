import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../infrastructure/services/pending_measurements_service.dart';
import 'connectivity_provider.dart';

/// Reenvía automáticamente las mediciones pendientes cuando vuelve internet.
/// Escucha el provider de conectividad: al pasar de offline a online hace
/// flush de la cola local.
final offlineSyncProvider = Provider<void>((ref) {
  final connectivity = ref.watch(connectivityProvider);

  connectivity.whenData((isOnline) {
    if (isOnline) {
      PendingMeasurementsService().flushPending();
    }
  });

  return null;
});
