import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:geolocator/geolocator.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/measurements_provider.dart';
import '../providers/weekly_trend_provider.dart';
import '../providers/smartwatch_provider.dart';

enum SimulationStep { ready, blowing, result, symptoms }

class SpirometerScreen extends ConsumerStatefulWidget {
  const SpirometerScreen({super.key});

  @override
  ConsumerState<SpirometerScreen> createState() => _SpirometerScreenState();
}

class _SpirometerScreenState extends ConsumerState<SpirometerScreen> {
  SimulationStep _currentStep = SimulationStep.ready;
  int? _simulatedPef;
  final TextEditingController _pefController = TextEditingController();
  bool _isSendingWithSymptoms = false;
  bool _isSendingWithoutSymptoms = false;

  
  final List<String> _symptomOptions = [
    'Tos',
    'Sibilancias',
    'Disnea',
    'Opresión',
    'Fatiga',
    'Flema',
  ];
  final Set<String> _selectedSymptoms = {};
  String _selectedIntensity = 'Moderada'; 
  final TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _pefController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _proceedToSymptoms() {
    final value = int.tryParse(_pefController.text);
    if (value == null || value <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor ingresa un valor válido de PEF')),
      );
      return;
    }
    setState(() {
      _simulatedPef = value;
      _currentStep = SimulationStep.symptoms;
    });
  }

  Future<void> _sendMeasurement({
    String? symptoms,
    String? symptomIntensity,
    String? notes,
    bool isWithSymptoms = false,
  }) async {
    if (_simulatedPef == null) return;
    setState(() {
      if (isWithSymptoms) {
        _isSendingWithSymptoms = true;
      } else {
        _isSendingWithoutSymptoms = true;
      }
    });

    try {
      final dio = ref.read(dioClientProvider);
      final supabaseDs = ref.read(supabaseAuthDataSourceProvider);
      final token = await supabaseDs.getIdToken();
      if (token == null) throw Exception('No auth token');

      
      double? lat;
      double? lng;
      try {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        if (permission == LocationPermission.always ||
            permission == LocationPermission.whileInUse) {
          final position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
            timeLimit: const Duration(seconds: 15),
          );
          lat = position.latitude;
          lng = position.longitude;
        }
      } catch (e) {
        debugPrint('Error obteniendo ubicación: $e');
      }

      final queryParams = <String, dynamic>{};
      if (lat != null && lng != null) {
        queryParams['lat'] = lat;
        queryParams['lng'] = lng;
      }

      final watchState = ref.read(smartwatchProvider);

      await dio.post(
        '/api/measurements/spirometer',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
        data: {
          'pef': _simulatedPef,
          'fev1': (_simulatedPef! / 100) * 0.8,
          'symptoms': symptoms,
          'symptom_intensity': symptomIntensity,
          'spo2': watchState.spO2,
          'heart_rate': watchState.heartRate,
          'steps': watchState.steps,
          'sleep_hours': watchState.sleepHours,
          'respiratory_rate': watchState.respiratoryRate,
          'notes': notes,
          'measured_at': DateTime.now().toIso8601String(),
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      
      
      ref.read(measurementsProvider.notifier).silentRefresh(checkRisk: true);
      ref
          .read(weeklyTrendProvider.notifier)
          .fetchWeeklyTrend(isSilentRefresh: true);

      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al enviar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSendingWithSymptoms = false;
          _isSendingWithoutSymptoms = false;
        });
      }
    }
  }

  void _onSendWithSymptoms() {
    final symptomsStr = _selectedSymptoms.join(', ');
    final notes = _notesController.text.trim();
    _sendMeasurement(
      symptoms: symptomsStr.isEmpty ? null : symptomsStr,
      symptomIntensity: _selectedSymptoms.isNotEmpty ? _selectedIntensity : null,
      notes: notes.isEmpty ? null : notes,
      isWithSymptoms: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF011627),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Registro de PEF',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Satoshi',
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 350),
        child: _currentStep == SimulationStep.symptoms
            ? _buildSymptomsPanel()
            : _buildMainFlow(),
      ),
    );
  }

  
  Widget _buildMainFlow() {
    return Center(
      key: const ValueKey('main'),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.air_rounded,
              size: 80,
              color: Color(0xFF00B4D8),
            ),
            const SizedBox(height: 40),
            const Text(
              'Registra tu PEF',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontFamily: 'Satoshi',
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Sopla en tu espirómetro manual e ingresa el valor obtenido aquí debajo.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 16,
                fontFamily: 'GeneralSans',
              ),
            ),
            const SizedBox(height: 40),
            TextField(
              controller: _pefController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              autofocus: true,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 48,
                fontWeight: FontWeight.bold,
                fontFamily: 'Satoshi',
              ),
              decoration: InputDecoration(
                hintText: '000',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.1)),
                suffixText: 'L/min',
                suffixStyle: const TextStyle(color: Colors.white54, fontSize: 18),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                ),
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF00B4D8), width: 2),
                ),
              ),
            ),
            const SizedBox(height: 60),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _proceedToSymptoms,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF023E8A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Siguiente',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  
  Widget _buildSymptomsPanel() {
    return SingleChildScrollView(
      key: const ValueKey('symptoms'),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Row(
              children: [
                const Icon(Icons.air, color: Color(0xFF00B4D8), size: 26),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PEF registrado',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      '$_simulatedPef L/min',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontFamily: 'Satoshi',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.white38, size: 20),
                  onPressed: () => setState(() => _currentStep = SimulationStep.ready),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          const Text(
            '¿Cómo te sentiste?',
            style: TextStyle(
              color: Colors.white,
              fontFamily: 'Satoshi',
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Selecciona los síntomas que experimentaste.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 20),
          
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _symptomOptions.map((symptom) {
              final isSelected = _selectedSymptoms.contains(symptom);
              return GestureDetector(
                onTap: () => setState(() {
                  if (isSelected) {
                    _selectedSymptoms.remove(symptom);
                  } else {
                    _selectedSymptoms.add(symptom);
                  }
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF023E8A)
                        : Colors.white.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF00B4D8)
                          : Colors.white.withOpacity(0.12),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isSelected) ...[
                        const Icon(Icons.check, color: Colors.white, size: 14),
                        const SizedBox(width: 6),
                      ],
                      Text(
                        symptom,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.white70,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w400,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          
          if (_selectedSymptoms.isNotEmpty) ...[
            Text(
              'Intensidad',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                for (final level in ['Leve', 'Moderada', 'Severa']) ...[
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedIntensity = level),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _selectedIntensity == level
                              ? _intensityColor(level).withOpacity(0.2)
                              : Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _selectedIntensity == level
                                ? _intensityColor(level)
                                : Colors.white.withOpacity(0.12),
                            width: 1.5,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          level,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _selectedIntensity == level
                                ? _intensityColor(level)
                                : Colors.white54,
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (level != 'Severa') const SizedBox(width: 8),
                ],
              ],
            ),
            const SizedBox(height: 24),
          ] else
            const SizedBox(height: 20),
          
          Text(
            'Notas adicionales',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _notesController,
            maxLines: 3,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Ej: me costó un poco antes de dormir...',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFF00B4D8)),
              ),
            ),
          ),
          const SizedBox(height: 32),
          
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _isSendingWithSymptoms ? null : _onSendWithSymptoms,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _isSendingWithSymptoms
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.send_rounded, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Enviar con Síntomas',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 10),
          
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton(
              onPressed: _isSendingWithoutSymptoms ? null : () => _sendMeasurement(isWithSymptoms: false),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white54,
                side: const BorderSide(color: Colors.white24),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _isSendingWithoutSymptoms
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white54,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text('Enviar sin síntomas'),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  
  Color _intensityColor(String level) {
    switch (level) {
      case 'Leve':
        return const Color(0xFF4CAF50);
      case 'Severa':
        return const Color(0xFFD90429);
      default:
        return const Color(0xFFFF9800); 
    }
  }
}
