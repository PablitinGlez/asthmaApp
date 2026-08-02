import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/prediction_provider.dart';

class AISimulatorPanel extends ConsumerWidget {
  const AISimulatorPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final predictionState = ref.watch(predictionProvider);
    final notifier = ref.read(predictionProvider.notifier);

    if (!predictionState.isSimulationActive) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: OutlinedButton.icon(
          onPressed: () => notifier.setSimulationMode(true, data: _scenarios['healthy']),
          icon: const Icon(Icons.science_outlined),
          label: const Text('Activar Simulador IA'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.blueGrey,
            side: const BorderSide(color: Colors.blueGrey),
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24.0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                ' MODO SIMULACIÓN',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () => notifier.setSimulationMode(false),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ScenarioButton(
                label: 'Sano',
                color: Colors.green,
                onTap: () => notifier.setSimulationMode(true, data: _scenarios['healthy']),
              ),
              _ScenarioButton(
                label: 'Aire Tóxico',
                color: Colors.amber,
                onTap: () => notifier.setSimulationMode(true, data: _scenarios['air_risk']),
              ),
              _ScenarioButton(
                label: 'Hipoxia/BPM',
                color: Colors.orange,
                onTap: () => notifier.setSimulationMode(true, data: _scenarios['vitals_risk']),
              ),
              _ScenarioButton(
                label: 'CRISIS TOTAL',
                color: Colors.red,
                onTap: () => notifier.setSimulationMode(true, data: _scenarios['critical']),
              ),
            ],
          ),
          if (predictionState.isLoading)
            const Padding(
              padding: EdgeInsets.only(top: 8.0),
              child: LinearProgressIndicator(minHeight: 2),
            ),
        ],
      ),
    );
  }

  static const _scenarios = {
    'healthy': {
      'spo2': 99.0,
      'bpm': 70.0,
      'pasos': 1200.0,
      'horas_sueno': 8.0,
      'pef_percent': 100.0,
      'aqi': 20.0,
      'humedad': 50.0,
      'temperatura': 22.0,
    },
    'air_risk': {
      'spo2': 98.0,
      'bpm': 75.0,
      'pasos': 500.0,
      'horas_sueno': 7.0,
      'pef_percent': 85.0,
      'aqi': 250.0, 
      'humedad': 85.0,
      'temperatura': 30.0,
    },
    'vitals_risk': {
      'spo2': 88.0, 
      'bpm': 130.0, 
      'pasos': 0.0,
      'horas_sueno': 4.0,
      'pef_percent': 70.0,
      'aqi': 40.0,
      'humedad': 55.0,
      'temperatura': 20.0,
    },
    'critical': {
      'spo2': 82.0,
      'bpm': 145.0,
      'pasos': 0.0,
      'horas_sueno': 3.0,
      'pef_percent': 40.0, 
      'aqi': 350.0,
      'humedad': 90.0,
      'temperatura': 35.0,
    },
  };
}

class _ScenarioButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ScenarioButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
      ),
      child: Text(label),
    );
  }
}
