import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../auth/providers/auth_provider.dart';
import 'smartwatch_provider.dart';
import 'environmental_provider.dart';
import 'measurements_provider.dart';
import '../../profile/providers/personal_info_provider.dart';

class PredictionState {
  final int crisis;
  final double probability;
  final String riskLevel;
  final bool isLoading;
  final String? errorMessage;
  final Map<String, dynamic>? simulationData;
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
    ref.listen(smartwatchProvider, (_, __) => _debouncedPredict());
    ref.listen(environmentalProvider, (_, __) => _debouncedPredict());
    ref.listen(measurementsProvider, (_, __) => _debouncedPredict());
    
    return PredictionState();
  }

  bool _isPredicting = false;

  Future<void> _debouncedPredict() async {
    if (_isPredicting) return;
    _isPredicting = true;
    
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
    
    Map<String, dynamic> payload;

    if (state.isSimulationActive && state.simulationData != null) {
      final sim = Map<String, dynamic>.from(state.simulationData!);
      final double pefPorc = (sim['pef_porcentaje'] ?? sim['pef_percent'] ?? 100.0).toDouble();

      payload = {
        'spo2': (sim['spo2'] ?? 98.0).toDouble(),
        'bpm': (sim['bpm'] ?? 75.0).toDouble(),
        'pasos': (sim['pasos'] ?? 0.0).toDouble(),
        'horas_sueno': (sim['horas_sueno'] ?? 8.0).toDouble(),
        'pef_porcentaje': pefPorc,
        'aqi': (sim['aqi'] ?? env.aqi ?? 50).toDouble(),
        'humedad': (sim['humedad'] ?? env.humidity ?? 65).toDouble(),
        'temperatura': (sim['temperatura'] ?? env.temperature ?? 22.0).toDouble(),
      };
    } else {
      final latestMeasurement = historyState?.allItems.firstOrNull;
      final double pefValue = latestMeasurement?.pef?.toDouble() ?? personalBest.toDouble();
      final double pefPorcentaje = (personalBest > 0) ? (pefValue / personalBest) * 100 : 100.0;

      payload = {
        'spo2': (watch.spO2 ?? 98).toDouble(),
        'bpm': (watch.heartRate ?? 75).toDouble(),
        'pasos': (watch.steps ?? 0).toDouble(),
        'horas_sueno': (watch.sleepHours ?? 8.0).toDouble(),
        'pef_porcentaje': pefPorcentaje,
        'aqi': (env.aqi ?? 50).toDouble(),
        'humedad': (env.humidity ?? 65).toDouble(),
        'temperatura': (env.temperature ?? 22.0).toDouble(),
      };
    }

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final dio = ref.read(dioClientProvider);
      final token = await ref.read(supabaseAuthDataSourceProvider).getIdToken();

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
        
        state = state.copyWith(
          crisis: data['crisis'] ?? 0,
          probability: (data['probability'] ?? 0.0).toDouble(),
          riskLevel: data['risk_level'] ?? 'green',
          isLoading: false,
        );
      }
    } catch (e) {
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
