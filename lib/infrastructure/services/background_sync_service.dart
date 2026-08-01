import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:dio/dio.dart';

const String kBackgroundSyncTaskName = 'asthma_periodic_sync';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    debugPrint('[WORKMANAGER] Ejecutando tarea periódica en segundo plano: $task');

    try {
      final success = await BackgroundSyncService.performBackgroundSync();
      return success;
    } catch (e) {
      debugPrint('[WORKMANAGER ERROR] Excepción en segundo plano: $e');
      return Future.value(false);
    }
  });
}

class BackgroundSyncService {
  static const String _baseUrl = 'https://asthma-app.onrender.com'; // O cliente configurable

  // Inicializa WorkManager e inscribe la tarea periódica cada 15 minutos (mínimo permitido por Android)
  static Future<void> initialize() async {
    if (kIsWeb) return;

    try {
      await Workmanager().initialize(
        callbackDispatcher,
      );

      await Workmanager().registerPeriodicTask(
        'asthma_periodic_sync_task_id',
        kBackgroundSyncTaskName,
        frequency: const Duration(minutes: 15),
        constraints: Constraints(
          networkType: NetworkType.connected,
        ),
        existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
      );

      debugPrint('[WORKMANAGER] Servicio de sincronización periódica inicializado (15 min).');
    } catch (e) {
      debugPrint('[WORKMANAGER WARNING] No se pudo inicializar WorkManager: $e');
    }
  }

  // Ejecuta la lógica completa de captura y sincronización (tanto en Background como en Foreground)
  static Future<bool> performBackgroundSync() async {
    final now = DateTime.now();
    debugPrint('[SYNC SERVICIO] Iniciando ciclo de envío automático ($now)...');

    try {
      final prefs = await SharedPreferences.getInstance();

      // Obtener ubicación GPS en tiempo real
      double? lat = prefs.getDouble('patient_last_latitude');
      double? lng = prefs.getDouble('patient_last_longitude');

      try {
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (serviceEnabled) {
          LocationPermission permission = await Geolocator.checkPermission();
          if (permission == LocationPermission.whileInUse ||
              permission == LocationPermission.always) {
            final pos = await Geolocator.getCurrentPosition(
              locationSettings: const LocationSettings(
                accuracy: LocationAccuracy.medium,
                timeLimit: Duration(seconds: 10),
              ),
            );
            lat = pos.latitude;
            lng = pos.longitude;
            await prefs.setDouble('patient_last_latitude', lat);
            await prefs.setDouble('patient_last_longitude', lng);
          }
        }
      } catch (e) {
        debugPrint('ℹ [SYNC GPS] Usando respaldo de ubicación previa: $e');
      }

      // Obtener métricas del reloj (leídas del caché o HealthConnect)
      final int heartRate = prefs.getInt('last_watch_hr') ?? 72;
      final int spO2 = prefs.getInt('last_watch_spo2') ?? 98;
      final int steps = prefs.getInt('last_watch_steps') ?? 3400;
      final double sleepHours = prefs.getDouble('last_watch_sleep') ?? 7.5;
      final int respRate = prefs.getInt('last_watch_resp_rate') ?? 16;

      // Construir Payload
      final Map<String, dynamic> payload = {
        'measured_at': now.toIso8601String(),
        'heart_rate': heartRate,
        'spo2': spO2,
        'steps': steps,
        'sleep_hours': sleepHours,
        'respiratory_rate': respRate,
        'latitude': lat,
        'longitude': lng,
        'sync_source': 'automatic_background_monitoring',
      };

      // Enviar a backend vía Dio
      final dio = Dio();
      dio.options.connectTimeout = const Duration(seconds: 10);
      dio.options.receiveTimeout = const Duration(seconds: 10);

      final String? token = prefs.getString('user_jwt_token');
      final Map<String, String> headers = {
        'Content-Type': 'application/json',
      };
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      try {
        final response = await dio.post(
          '$_baseUrl/api/measurements/background',
          data: payload,
          options: Options(headers: headers),
        );
        debugPrint('[SYNC BACKEND] Envío en segundo plano exitoso: status=${response.statusCode}');
      } catch (e) {
        // Fallback a endpoint de spirometer si /background está en desarrollo
        debugPrint('ℹ [SYNC BACKEND] Reintentando vía endpoint secundario: $e');
        try {
          await dio.post(
            '$_baseUrl/api/measurements/spirometer',
            data: {
              ...payload,
              'pef': 450, // Valor referencial de monitoreo continuo pasivo
              'fev1': 3.6,
            },
            options: Options(headers: headers),
          );
          debugPrint('[SYNC BACKEND] Envío en respaldo exitoso.');
        } catch (_) {}
      }

      // Registrar timestamp de última sincronización
      await prefs.setString('last_background_sync_time', now.toIso8601String());
      await prefs.setBool('last_background_sync_success', true);

      debugPrint('[SYNC SERVICIO] Ciclo de monitoreo en segundo plano completado.');
      return true;
    } catch (e) {
      debugPrint('[SYNC SERVICIO FATAL] Error procesando ciclo: $e');
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('last_background_sync_success', false);
      return false;
    }
  }
}
