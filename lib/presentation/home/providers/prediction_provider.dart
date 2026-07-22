import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../auth/providers/auth_provider.dart';
import 'smartwatch_provider.dart';
import 'environmental_provider.dart';
import 'measurements_provider.dart';
import '../../profile/providers/personal_info_provider.dart';

class PredictionState {
  final int crisis; // 0 o 1
  final double probability; // 0.0 a 1.0
  final String riskLevel; // "green", "yellow", "red"
  final bool isLoading;
  final String? errorMessage;
  final Map<String, dynamic>? simulationData; // Escenario inyectado
  final bool isSimulationActive;

  PredictionState({
    this.crisis = 0,
    this.probability = 0.0,
    this.riskLevel = 'green',
    this.isLoading = false,
    this.errorMessage,
    this.simulationData,
    this.isSimulationActive = false,
  });

  PredictionState copyWith({
    int? crisis,
    double? probability,
    String? riskLevel,
    bool? isLoading,
    String? errorMessage,
    Map<String, dynamic>? simulationData,
    bool? isSimulationActive,
  }) {
    return PredictionState(
      crisis: crisis ?? this.crisis,
      probability: probability ?? this.probability,
      riskLevel: riskLevel ?? this.riskLevel,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      simulationData: simulationData ?? this.simulationData,
      isSimulationActive: isSimulationActive ?? this.isSimulationActive,
    );
  }
}

class PredictionNotifier extends Notifier<PredictionState> {
  @override
  PredictionState build() {
    // Escuchar cambios en otros providers para auto-gatillar predicción
    ref.listen(smartwatchProvider, (_, __) => _debouncedPredict());
    ref.listen(environmentalProvider, (_, __) => _debouncedPredict());
    ref.listen(measurementsProvider, (_, __) => _debouncedPredict());
    
    return PredictionState();
  }

  // Debouncing para evitar ráfagas de peticiones si varios vitales cambian a la vez
  bool _isPredicting = false;

  Future<void> _debouncedPredict() async {
    if (_isPredicting) return;
    _isPredicting = true;
    
    // Esperar un poco para agrupar cambios
    await Future.delayed(const Duration(seconds: 1));
    await runPrediction();
    
    _isPredicting = false;
  }

  void setSimulationMode(bool active, {Map<String, dynamic>? data}) {
    state = state.copyWith(
      isSimulationActive: active,
      simulationData: data,
    );
    if (active) runPrediction();
  }

  Future<void> runPrediction() async {
    final watch = ref.read(smartwatchProvider);
    final env = ref.read(environmentalProvider);
    final historyState = ref.read(measurementsProvider).value;
    final profile = ref.read(personalInfoProvider).profile;

    final int personalBest = profile?.personalBestPef ?? 500;
    
    // 📊 PREPARAR PAYLOAD (Simulado o Real)
    Map<String, dynamic> payload;

    if (state.isSimulationActive && state.simulationData != null) {
      payload = Map<String, dynamic>.from(state.simulationData!);
      // Convertimos el pef_percent del simulador a pef_porcentaje para el backend
      if (payload.containsKey('pef_percent')) {
        payload['pef_porcentaje'] = payload['pef_percent'];
        payload.remove('pef_percent');
      }
    } else {
      // Si no hay datos críticos reales y no estamos simulando, abortamos
      if (watch.heartRate == null && env.aqi == null) return;
      
      final latestMeasurement = historyState?.allItems.firstOrNull;
      final double pefValue = latestMeasurement?.pef?.toDouble() ?? personalBest.toDouble();
      final double pefPorcentaje = (pefValue / personalBest) * 100;

      payload = {
        'spo2': (watch.spO2 ?? 98).toDouble(),
        'bpm': (watch.heartRate ?? 75).toDouble(),
        'pasos': (watch.steps ?? 0).toDouble(),
        'horas_sueno': (watch.sleepHours ?? 8.0).toDouble(),
        'pef_porcentaje': pefPorcentaje,
        'aqi': (env.aqi ?? 50).toDouble(),
        'humedad': (env.humidity ?? 50).toDouble(),
        'temperatura': (env.temperature ?? 22.0).toDouble(),
      };
    }

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      print('--- 🧠 IA: INICIO DE PREDICCIÓN ---');
      print('🚀 Modo Simulación: ${state.isSimulationActive}');
      
      if (!state.isSimulationActive) {
        print('📊 Datos del Smartwatch:');
        print('   - SpO2: ${watch.spO2 != null ? "${watch.spO2}% (REAL)" : "98% (DEFAULT)"}');
        print('   - BPM: ${watch.heartRate != null ? "${watch.heartRate} (REAL)" : "75 (DEFAULT)"}');
        print('   - Pasos: ${watch.steps != null ? "${watch.steps} (REAL)" : "0 (DEFAULT)"}');
        print('   - Sueño: ${watch.sleepHours != null ? "${watch.sleepHours}h (REAL)" : "8.0h (DEFAULT)"}');
        
        print('🌍 Datos Ambientales:');
        print('   - AQI: ${env.aqi != null ? "${env.aqi} (REAL)" : "50 (DEFAULT)"}');
        print('   - Humedad: ${env.humidity != null ? "${env.humidity}% (REAL)" : "50% (DEFAULT)"}');
        print('   - Temperatura: ${env.temperature != null ? "${env.temperature}°C (REAL)" : "22.0°C (DEFAULT)"}');
        
        print('📈 Pulmones (PEF):');
        print('   - Personal Best: $personalBest');
        final latestMeasurement = historyState?.allItems.firstOrNull;
        if (latestMeasurement != null) {
          print('   - Último PEF: ${latestMeasurement.pef} (REAL - ${latestMeasurement.measuredAt})');
        } else {
          print('   - Último PEF: $personalBest (DEFAULT - No hay historial)');
        }
        print('   - PEF % Calculado: ${payload['pef_porcentaje']?.toStringAsFixed(1)}%');
      } else {
        print('🧪 Payload SIMULADO: $payload');
      }

      final dio = ref.read(dioClientProvider);
      final token = await ref.read(supabaseAuthDataSourceProvider).getIdToken();

      print('📡 Enviando a Backend...');
      final response = await dio.post(
        '/api/predict',
        data: payload,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        print('✅ [IA] Respuesta del Servidor:');
        print('   - Riesgo: ${data['risk_level']?.toString().toUpperCase()}');
        print('   - Probabilidad: ${(data['probability'] * 100).toStringAsFixed(1)}%');
        print('   - ¿Crisis Detectada?: ${data['crisis'] == 1 ? "SÍ" : "NO"}');
        
        state = state.copyWith(
          crisis: data['crisis'] ?? 0,
          probability: (data['probability'] ?? 0.0).toDouble(),
          riskLevel: data['risk_level'] ?? 'green',
          isLoading: false,
        );
      }
    } catch (e) {
      print('❌ [PREDICT] Error: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error en predicción: $e',
      );
    }
  }
}

final predictionProvider = NotifierProvider<PredictionNotifier, PredictionState>(
  PredictionNotifier.new,
);
