import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health/health.dart';
import 'package:dio/dio.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io' show Platform;
import '../../auth/providers/auth_provider.dart';

class SmartwatchState {
  final bool isLinked;
  final bool isLoading;
  final String? errorMessage;
  final bool isPermanentlyDenied;
  final int? heartRate;
  final int? spO2;
  final int? steps;
  final double? sleepHours;
  final int? respiratoryRate;
  final DateTime? lastSyncTime;
  final List<String> logs;
 
   SmartwatchState({
     this.isLinked = false,
     this.isLoading = true,
     this.errorMessage,
     this.isPermanentlyDenied = false,
     this.heartRate,
     this.spO2,
     this.steps,
     this.sleepHours,
     this.respiratoryRate,
     this.lastSyncTime,
     this.logs = const [],
   });
 
   SmartwatchState copyWith({
     bool? isLinked,
     bool? isLoading,
     String? errorMessage,
     bool? isPermanentlyDenied,
     int? heartRate,
     int? spO2,
     int? steps,
     double? sleepHours,
     int? respiratoryRate,
     DateTime? lastSyncTime,
     List<String>? logs,
   }) {
     return SmartwatchState(
       isLinked: isLinked ?? this.isLinked,
       isLoading: isLoading ?? this.isLoading,
       errorMessage: errorMessage,
       isPermanentlyDenied: isPermanentlyDenied ?? this.isPermanentlyDenied,
       heartRate: heartRate ?? this.heartRate,
       spO2: spO2 ?? this.spO2,
       steps: steps ?? this.steps,
       sleepHours: sleepHours ?? this.sleepHours,
       respiratoryRate: respiratoryRate ?? this.respiratoryRate,
       lastSyncTime: lastSyncTime ?? this.lastSyncTime,
       logs: logs ?? this.logs,
     );
   }
}

class SmartwatchNotifier extends Notifier<SmartwatchState>
    with WidgetsBindingObserver {
  // Configuración de HealthFactory para acceder a Google Fit / Apple Health
  final health = Health();

  // Timer para auto-refresh cada 5 minutos (sin fugas de memoria)
  Timer? _refreshTimer;

  // Los tipos de datos que queremos leer del smartwatch
  // RESPIRATORY_RATE removed: Samsung Health on One UI 6 does not expose
  // this data type through Health Connect, causing the entire auth to fail.
  final types = [
    HealthDataType.HEART_RATE,
    HealthDataType.STEPS,
    HealthDataType.BLOOD_OXYGEN,
    HealthDataType.SLEEP_SESSION,
  ];

  // Nivel de acceso requerido (solo leer)
  final permissions = [
    HealthDataAccess.READ,
    HealthDataAccess.READ,
    HealthDataAccess.READ,
    HealthDataAccess.READ,
  ];

  @override
  SmartwatchState build() {
    WidgetsBinding.instance.addObserver(this);
    ref.onDispose(() {
      _refreshTimer?.cancel();
      WidgetsBinding.instance.removeObserver(this);
    });

    // 1. Instanciamos el factory
    Health().configure();
    // 2. Verificamos permisos locales primero (sin consultar la red)
    Future.microtask(checkLocalPermissionsAndFetch);
    return SmartwatchState();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState appState) {
    if (appState == AppLifecycleState.resumed) {
      if (state.isPermanentlyDenied) {
        recheckPermissions();
      }
    }
  }

  void _addLog(String message) {
    print(message);
    state = state.copyWith(logs: [...state.logs, message]);
  }

  void clearLogs() {
    state = state.copyWith(logs: []);
  }

  Future<void> recheckPermissions() async {
    if (Platform.isAndroid && state.isPermanentlyDenied) {
      final activityStatus = await Permission.activityRecognition.status;
      final sensorsStatus = await Permission.sensors.status;

      if (!activityStatus.isPermanentlyDenied &&
          !sensorsStatus.isPermanentlyDenied) {
        state = state.copyWith(isPermanentlyDenied: false, errorMessage: null);
      }
    }
  }

  /// Verifica permisos locales en Android/iOS sin consultar la red.
  /// Si ya existen permisos, extrae los datos al instante.
  /// Solo muestra el banner de vinculación si no hay permisos previos.
  Future<void> checkLocalPermissionsAndFetch() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      // Preguntar directo al OS si ya tenemos permisos (no usa internet)
      final bool? hasPermissions = await health.hasPermissions(
        types,
        permissions: permissions,
      );

      if (hasPermissions == true) {
        // ¡Ya tenemos los permisos! Jalamos los datos sin mostrar el banner.
        print(
          '[LOG HEALTH] Permisos locales detectados. Auto-cargando vitales...',
        );
        state = state.copyWith(isLinked: true);
        await fetchTodayVitals();
        // ✔ Arrancar auto-refresh cada 5 minutos (limpia el anterior si existía)
        _refreshTimer?.cancel();
        _refreshTimer = Timer.periodic(const Duration(minutes: 5), (_) {
          if (state.isLinked) {
            print('[LOG HEALTH] Auto-refresh periódico de vitales (5 min).');
            fetchTodayVitals();
          }
        });
      } else {
        // Primera vez o permisos revocados. Mostrar el banner de vinculación.
        print(
          '[LOG HEALTH] Sin permisos locales. Mostrando banner de vinculación.',
        );
        state = state.copyWith(isLinked: false, isLoading: false);
      }
    } catch (e) {
      print('[LOG HEALTH ERROR] Error al verificar permisos locales: $e');
      // En caso de error, mostramos el banner como fallback seguro
      state = state.copyWith(isLinked: false, isLoading: false);
    }
  }

  /// Desvincula el SmartWatch reseteando el estado local.
  void unlinkSmartwatch() {
    _refreshTimer?.cancel(); // Apagar el auto-refresh al desvincular
    state = SmartwatchState(isLinked: false, isLoading: false);
  }

  /// Abre los ajustes de la aplicación para que el usuario pueda corregir permisos denegados permanentemente.
  Future<void> openSettings() async {
    await openAppSettings();
    // Reiniciamos el estado para que deje de mostrar el error y permita intentar de nuevo al volver
    state = state.copyWith(isPermanentlyDenied: false, errorMessage: null);
  }

  Future<void> linkSmartwatch() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    clearLogs();

    try {
      _addLog('--- INICIANDO VINCULACIÓN DE SMARTWATCH ---');

      // 0. En Android, Health Connect requiere permisos base
      if (Platform.isAndroid) {
        _addLog('[LOG] Solicitando permisos base...');
        
        // Pedimos uno por uno para saber exactamente cuál falla
        final activityStatus = await Permission.activityRecognition.request();
        _addLog('[LOG] Activity Recognition: $activityStatus');
        
        final sensorsStatus = await Permission.sensors.request();
        _addLog('[LOG] Body Sensors: $sensorsStatus');

        // Solo bloqueamos si AMBOS son denegados permanentemente.
        if (activityStatus.isPermanentlyDenied && sensorsStatus.isPermanentlyDenied) {
          _addLog('[ERROR] Permisos bloqueados permanentemente.');
          state = state.copyWith(
            isLoading: false,
            isPermanentlyDenied: true,
            errorMessage: 'Permisos bloqueados en ajustes. Actívalos manualmente.',
          );
          return;
        }
      }

      // 1. Verificar cuales tipos soporta este dispositivo antes de pedir auth
      _addLog('[LOG] Verificando soporte de Health Connect en este dispositivo...');
      _addLog('[DEBUG] Tipos a solicitar: HEART_RATE, STEPS, BLOOD_OXYGEN, SLEEP_SESSION');

      // Verificar si Health Connect está disponible
      final hcStatus = health.getHealthConnectSdkStatus();
      _addLog('[DEBUG] Health Connect SDK status: $hcStatus');

      // Verificar permisos actuales antes de pedir
      bool? currentPerms;
      try {
        currentPerms = await health.hasPermissions(types, permissions: permissions);
        _addLog('[DEBUG] Permisos actuales antes de solicitar: $currentPerms');
      } catch (e) {
        _addLog('[DEBUG] No se pudo verificar permisos previos: $e');
      }

      _addLog('[LOG] Solicitando autorización nativa a Health Connect...');
      
      bool? authorized;
      try {
        authorized = await health.requestAuthorization(
          types,
          permissions: permissions,
        );
      } catch (e) {
        _addLog('[LOG ERROR] Excepción nativa en requestAuthorization: $e');
        _addLog('[LOG ERROR] Tipo de excepción: ${e.runtimeType}');
        authorized = false;
      }

      _addLog('[LOG] Resultado de autorización nativa: $authorized');

      // Verificar permisos uno por uno para saber cuál falló
      _addLog('[DEBUG] Verificando permisos individuales post-auth...');
      try {
        final hrPerm = await health.hasPermissions([HealthDataType.HEART_RATE], permissions: [HealthDataAccess.READ]);
        _addLog('[DEBUG] HEART_RATE permitido: $hrPerm');
        final stepsPerm = await health.hasPermissions([HealthDataType.STEPS], permissions: [HealthDataAccess.READ]);
        _addLog('[DEBUG] STEPS permitido: $stepsPerm');
        final spo2Perm = await health.hasPermissions([HealthDataType.BLOOD_OXYGEN], permissions: [HealthDataAccess.READ]);
        _addLog('[DEBUG] BLOOD_OXYGEN (SpO2) permitido: $spo2Perm');
        final sleepPerm = await health.hasPermissions([HealthDataType.SLEEP_SESSION], permissions: [HealthDataAccess.READ]);
        _addLog('[DEBUG] SLEEP_SESSION permitido: $sleepPerm');
      } catch (e) {
        _addLog('[DEBUG] Error verificando permisos individuales: $e');
      }

      if (authorized != true) {
        _addLog('[ERROR] Health Connect devolvió authorized=false.');
        _addLog('[DEBUG] Revisa los permisos individuales arriba para ver cuál bloqueó.');
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Permisos de Health Connect denegados. Revisa los logs para el detalle.',
        );
        return;
      }

      // 2. Registramos el dispositivo DE VERDAD en la Base de Datos
      final dioClient = ref.read(dioClientProvider);
      final supabaseAuthDS = ref.read(supabaseAuthDataSourceProvider);
      final token = await supabaseAuthDS.getIdToken();

      if (token != null) {
        try {
          _addLog('[LOG] Guardando dispositivo en el servidor...');
          await dioClient.post(
            '/api/devices',
            data: {
              "device_type": "smartwatch",
              "device_brand": Platform.isAndroid
                  ? "Google Fit"
                  : "Apple Health",
              "device_model": "Simulation/Native API",
              "device_mac_address": "00:00:00:00:00:00",
            },
            options: Options(headers: {'Authorization': 'Bearer $token'}),
          );
          _addLog('✅ Sincronización: Reloj guardado en backend.');
        } on DioException catch (dioErr) {
          if (dioErr.response?.statusCode == 400 &&
              dioErr.response?.data.toString().contains('registrado') == true) {
            _addLog('[INFO] El reloj ya estaba en el servidor.');
          } else {
            _addLog('[ERROR API] ${dioErr.message}');
            rethrow;
          }
        }
      }

      state = state.copyWith(isLinked: true, errorMessage: null);
      _addLog('🚀 ¡VINCULACIÓN COMPLETADA CON ÉXITO!');
      await fetchTodayVitals();
    } catch (e) {
      _addLog('[FATAL] $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error vinculando Smartwatch: $e',
      );
    }
  }

  Future<void> fetchTodayVitals() async {
    state = state.copyWith(isLoading: true);
    try {
      final now = DateTime.now();
      final midnight = DateTime(now.year, now.month, now.day);

      _addLog('[DEBUG] Extrayendo vitales desde $midnight...');
      List<HealthDataPoint> healthData = [];
      try {
        healthData = await health.getHealthDataFromTypes(
          types: types,
          startTime: midnight,
          endTime: now,
        );
      } catch (e) {
        _addLog('[LOG ERROR] Fallo crítico al extraer datos de Health Connect: $e');
        _addLog('[SAMSUNG FIX] Algunos tipos de datos (como RespRate o SpO2) pueden no estar soportados por el puente de Samsung. Verifica las actualizaciones del celular.');
        throw e; // Lanza al catch principal
      }
      
      _addLog('[DEBUG] Puntos encontrados en la BD del celular: ${healthData.length}');
      if (healthData.isEmpty) {
        _addLog('[WARNING] Health Connect respondió bien, pero entregó 0 datos. Esto pasa cuando el Galaxy Watch aún no sincroniza con la app "Samsung Health" en el teléfono.');
      }

      // Variables temporales para acumular/promediar
      int? currentHr;
      int? currentSpO2;
      int totalSteps = 0;
      double totalSleepMinutes = 0;
      int? currentRespRate;

      for (var point in healthData) {
        print('[LOG HEALTH POINT] Tipo: ${point.type}, Valor: ${point.value}');
        if (point.type == HealthDataType.HEART_RATE) {
          currentHr = (point.value as NumericHealthValue).numericValue.toInt();
        } else if (point.type == HealthDataType.BLOOD_OXYGEN) {
          double val = (point.value as NumericHealthValue).numericValue
              .toDouble();
          if (val <= 1.0) val *= 100;
          currentSpO2 = val.toInt();
        } else if (point.type == HealthDataType.STEPS) {
          totalSteps += (point.value as NumericHealthValue).numericValue
              .toInt();
        } else if (point.type == HealthDataType.SLEEP_SESSION) {
          // Calcular minutos de sueño de la sesion
          final durationMs = point.dateTo.difference(point.dateFrom).inMinutes;
          totalSleepMinutes += durationMs;
        } else if (point.type == HealthDataType.RESPIRATORY_RATE) {
          currentRespRate = (point.value as NumericHealthValue).numericValue
              .toInt();
        }
      }

      final sleepHrs = totalSleepMinutes > 0
          ? (totalSleepMinutes / 60.0)
          : null;

      print(
        '[LOG HEALTH SUMMARY] HR: $currentHr, SpO2: $currentSpO2, Steps: $totalSteps, Sleep: ${sleepHrs?.toStringAsFixed(1)}h, RespRate: $currentRespRate',
      );

      state = state.copyWith(
        heartRate: currentHr,
        spO2: currentSpO2,
        steps: totalSteps > 0 ? totalSteps : null,
        sleepHours: sleepHrs,
        respiratoryRate: currentRespRate,
        lastSyncTime: DateTime.now(),
        isLoading: false,
      );
    } catch (e) {
      print('Error obteniendo health logs: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'No se pudieron extraer los datos del reloj',
      );
    }
  }
}

final smartwatchProvider =
    NotifierProvider<SmartwatchNotifier, SmartwatchState>(
      SmartwatchNotifier.new,
    );
