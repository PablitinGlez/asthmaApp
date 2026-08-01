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
  final health = Health();

  Timer? _refreshTimer;

  final types = [
    HealthDataType.HEART_RATE,
    HealthDataType.STEPS,
    HealthDataType.BLOOD_OXYGEN,
    HealthDataType.SLEEP_SESSION,
  ];

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

    Health().configure();
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

  Future<void> checkLocalPermissionsAndFetch() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final bool? hasPermissions = await health.hasPermissions(
        types,
        permissions: permissions,
      );

      if (hasPermissions == true) {
        state = state.copyWith(isLinked: true);
        await fetchTodayVitals();
        _refreshTimer?.cancel();
        _refreshTimer = Timer.periodic(const Duration(minutes: 5), (_) {
          if (state.isLinked) {
            fetchTodayVitals();
          }
        });
      } else {
        state = state.copyWith(isLinked: false, isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(isLinked: false, isLoading: false);
    }
  }

  void unlinkSmartwatch() {
    _refreshTimer?.cancel();
    state = SmartwatchState(isLinked: false, isLoading: false);
  }

  Future<void> openSettings() async {
    await openAppSettings();
    state = state.copyWith(isPermanentlyDenied: false, errorMessage: null);
  }

  Future<void> linkSmartwatch() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    clearLogs();

    try {
      _addLog('--- INICIANDO VINCULACIÓN DE SMARTWATCH ---');

      if (Platform.isAndroid) {
        final activityStatus = await Permission.activityRecognition.request();
        final sensorsStatus = await Permission.sensors.request();

        if (activityStatus.isPermanentlyDenied && sensorsStatus.isPermanentlyDenied) {
          state = state.copyWith(
            isLoading: false,
            isPermanentlyDenied: true,
            errorMessage: 'Permisos bloqueados en ajustes. Actívalos manualmente.',
          );
          return;
        }
      }

      final hcStatus = health.getHealthConnectSdkStatus();

      bool? currentPerms;
      try {
        currentPerms = await health.hasPermissions(types, permissions: permissions);
      } catch (e) {
        _addLog('[DEBUG] No se pudo verificar permisos previos: $e');
      }

      bool? authorized;
      try {
        authorized = await health.requestAuthorization(
          types,
          permissions: permissions,
        );
      } catch (e) {
        _addLog('[LOG ERROR] Excepción nativa en requestAuthorization: $e');
        authorized = false;
      }

      try {
        await health.hasPermissions([HealthDataType.HEART_RATE], permissions: [HealthDataAccess.READ]);
        await health.hasPermissions([HealthDataType.STEPS], permissions: [HealthDataAccess.READ]);
        await health.hasPermissions([HealthDataType.BLOOD_OXYGEN], permissions: [HealthDataAccess.READ]);
        await health.hasPermissions([HealthDataType.SLEEP_SESSION], permissions: [HealthDataAccess.READ]);
      } catch (e) {
        _addLog('[DEBUG] Error verificando permisos individuales: $e');
      }

      if (authorized != true) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Permisos de Health Connect denegados.',
        );
        return;
      }

      final dioClient = ref.read(dioClientProvider);
      final supabaseAuthDS = ref.read(supabaseAuthDataSourceProvider);
      final token = await supabaseAuthDS.getIdToken();

      if (token != null) {
        try {
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
        } on DioException catch (dioErr) {
          if (dioErr.response?.statusCode == 400 &&
              dioErr.response?.data.toString().contains('registrado') == true) {
          } else {
            rethrow;
          }
        }
      }

      state = state.copyWith(isLinked: true, errorMessage: null);
      await fetchTodayVitals();
    } catch (e) {
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

      List<HealthDataPoint> healthData = [];
      try {
        healthData = await health.getHealthDataFromTypes(
          types: types,
          startTime: midnight,
          endTime: now,
        );
      } catch (e) {
        throw e;
      }

      int? currentHr;
      int? currentSpO2;
      int totalSteps = 0;
      double totalSleepMinutes = 0;
      int? currentRespRate;

      for (var point in healthData) {
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
