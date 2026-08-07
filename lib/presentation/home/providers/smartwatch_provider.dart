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

  String _userId = '';

  @override
  SmartwatchState build() {
    WidgetsBinding.instance.addObserver(this);
    ref.onDispose(() {
      _refreshTimer?.cancel();
      WidgetsBinding.instance.removeObserver(this);
    });

    final authState = ref.watch(authStateProvider);
    final user = authState.value;
    _userId = user?.id ?? '';

    if (user == null) {
      return SmartwatchState(isLinked: false, isLoading: false);
    }

    health.configure();
    Future.microtask(checkLocalPermissionsAndFetch);
    return SmartwatchState();
  }

  /// Deriva un identificador MAC estable a partir del id de la cuenta.
  /// Cada cuenta registra su propio dispositivo, evitando colisiones cuando
  /// el mismo reloj se vincula desde distintos perfiles.
  String _deviceIdentifier() {
    final raw = _userId.isEmpty ? '000000000000' : _userId.replaceAll('-', '');
    final hex = raw.toUpperCase().padRight(12, '0').substring(0, 12);
    return '${hex.substring(0, 2)}:${hex.substring(2, 4)}:'
        '${hex.substring(4, 6)}:${hex.substring(6, 8)}:'
        '${hex.substring(8, 10)}:${hex.substring(10, 12)}';
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
    state = SmartwatchState(
      isLinked: false,
      isLoading: false,
      isPermanentlyDenied: state.isPermanentlyDenied,
    );
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

      final hcStatus = Platform.isAndroid
          ? await health.getHealthConnectSdkStatus()
          : HealthConnectSdkStatus.sdkAvailable;

      if (Platform.isAndroid &&
          hcStatus != HealthConnectSdkStatus.sdkAvailable) {
        state = state.copyWith(
          isLoading: false,
          errorMessage:
              'Health Connect no está disponible en tu dispositivo. '
              'Abre Health Connect desde Google Play o actualízalo e '
              'inténtalo de nuevo.',
        );
        return;
      }

      _addLog('[INFO] Estado del SDK de Health Connect: $hcStatus');

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
        final String deviceMac = _deviceIdentifier();

        final Map<String, dynamic> devicePayload = {
          "device_type": "smartwatch",
          "device_brand": Platform.isAndroid ? "Google Fit" : "Apple Health",
          "device_model": "Simulación / API nativa",
          "device_mac_address": deviceMac,
        };

        try {
          await dioClient.post(
            '/api/devices',
            data: devicePayload,
            options: Options(headers: {'Authorization': 'Bearer $token'}),
          );
          _addLog('[OK] Dispositivo registrado con MAC $deviceMac');
        } on DioException catch (dioErr) {
          final status = dioErr.response?.statusCode;
          final body = dioErr.response?.data?.toString() ?? '';

          final alreadyRegistered = status == 400 ||
              status == 409 ||
              status == 422;
          final alreadyMessage = body.toLowerCase().contains('registrad') ||
              body.toLowerCase().contains('ya existe') ||
              body.toLowerCase().contains('duplic') ||
              body.toLowerCase().contains('en uso') ||
              body.toLowerCase().contains('exist');

          if (alreadyRegistered && alreadyMessage) {
            _addLog(
              '[OK] El dispositivo ya estaba registrado en el sistema. Continuando.',
            );
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
        errorMessage: 'No fue posible vincular el reloj. Verifica los '
            'permisos de Health Connect e inténtalo de nuevo. ($e)',
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
