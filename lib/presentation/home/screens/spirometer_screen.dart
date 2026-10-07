import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'dart:async';
import 'dart:typed_data';
import '../../auth/providers/auth_provider.dart';
import '../providers/measurements_provider.dart';
import '../providers/weekly_trend_provider.dart';
import '../providers/smartwatch_provider.dart';
import '../../profile/providers/personal_info_provider.dart';
import '../../../core/services/pef_analyzer.dart';
import '../../../core/services/pef_estimator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../infrastructure/services/pending_measurements_service.dart';

enum SimulationStep { choose, ready, blowing, symptoms }

class SpirometerScreen extends ConsumerStatefulWidget {
  const SpirometerScreen({super.key});

  @override
  ConsumerState<SpirometerScreen> createState() => _SpirometerScreenState();
}

class _SpirometerScreenState extends ConsumerState<SpirometerScreen>
    with SingleTickerProviderStateMixin {
  SimulationStep _currentStep = SimulationStep.choose;
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

  // ---- Medición por micrófono ----
  final AudioRecorder _recorder = AudioRecorder();
  StreamSubscription<Uint8List>? _pcmSub;
  Timer? _blowTimer;
  final PefBlowAnalyzer _analyzer = PefBlowAnalyzer();
  double _liveRms = 0;
  bool _recording = false;
  bool _micDenied = false;
  final List<int?> _blowValues = [];
  int _blowAttempt = 0;
  String? _invalidReason;
  double _isEncouraging = 0;
  late final AnimationController _pulseController;

  // Calibración personal: pico acústico que corresponde al mejor PEF personal.
  double? _calibrationPeak;
  bool _calibrating = false;
  int? _personalBestPef;
  int? _userId;

  static const int _defaultPersonalBest = 450;
  static const double _encourageRms = 2500; // soplo muy flojo

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    Future.microtask(_loadCalibration);
  }

  Future<void> _loadCalibration() async {
    final profile = ref.read(personalInfoProvider).profile;
    _personalBestPef = profile?.personalBestPef ?? _defaultPersonalBest;
    _userId = profile?.userId;
    final key = _calKey;
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getDouble(key);
    if (mounted) {
      setState(() {
        _calibrationPeak = saved;
        _calibrating = saved == null;
      });
    }
  }

  String get _calKey => 'pef_cal_peak_${_userId ?? 0}';

  Future<void> _saveCalibration(double peak) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_calKey, peak);
  }

  @override
  void dispose() {
    _pefController.dispose();
    _notesController.dispose();
    _pcmSub?.cancel();
    _blowTimer?.cancel();
    _pulseController.dispose();
    _shutdownRecorder();
    super.dispose();
  }

  Future<void> _shutdownRecorder() async {
    _stopRecorder();
    try {
      await _recorder.dispose();
    } catch (_) {}
  }

  Future<void> _stopRecorder() async {
    _pcmSub?.cancel();
    _pcmSub = null;
    _blowTimer?.cancel();
    _recording = false;
    _pulseController.stop();
    try {
      await _recorder.stop();
    } catch (_) {}
  }

  // ----- Selección de método -----
  void _chooseManual() => setState(() => _currentStep = SimulationStep.ready);
  void _chooseBlowing() =>
      setState(() => _currentStep = SimulationStep.blowing);

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

  // Inicia la captura PCM de UN intento de soplo.
  Future<void> _startBlow() async {
    if (_recording) return;

    final mic = await Permission.microphone.request();
    if (!mic.isGranted) {
      setState(() => _micDenied = true);
      return;
    }

    _analyzer.reset();
    setState(() {
      _micDenied = false;
      _recording = true;
      _liveRms = 0;
      _isEncouraging = 0;
      _invalidReason = null;
    });
    debugPrint('[PEF] INICIA soplo #${_blowValues.length + 1}/3 (calibrado=${_calibrationPeak != null})');
    _pulseController.repeat(reverse: true);

    try {
      final stream = await _recorder.startStream(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: 44100,
          numChannels: 1,
        ),
      );
      _pcmSub?.cancel();
      _pcmSub = stream.listen((chunk) {
        if (!mounted || !_recording) return;
        final rms = _analyzer.addPcmChunk(chunk);
        final encourage = rms > 0 && rms < _encourageRms && _analyzer.peakRms < 5000;
        setState(() {
          _liveRms = rms;
          _isEncouraging = encourage ? 1 : 0;
        });
      });
    } catch (_) {
      if (mounted) {
        setState(() => _recording = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo iniciar el micrófono')),
        );
      }
      return;
    }

    _blowTimer?.cancel();
    _blowTimer = Timer(const Duration(seconds: 4), () {
      _endBlow();
    });
  }

  void _recordAttempt(int? value, String? reason) {
    setState(() {
      _blowValues.add(value);
      _blowAttempt = _blowValues.length;
      _invalidReason = reason;
      _isEncouraging = 0;
    });
  }

  // Analiza el soplo con el DSP y lo convierte a PEF con el estimador.
  Future<void> _endBlow() async {
    if (!_recording) return;
    _stopRecorder();

    final result = _analyzer.analyze();
    debugPrint('[PEF] FIN soplo #${_blowValues.length}: valid=${result.isValid} peak=${result.acousticPeak.toStringAsFixed(0)} dur=${result.durationMs.toStringAsFixed(0)}ms zcr=${result.meanZcr.toStringAsFixed(3)} reason=${result.reason}');

    if (!mounted) return;

    if (!result.isValid) {
      _recordAttempt(null, result.reason ?? 'Intento inválido.');
    } else {
      // Convertimos el pico acústico a PEF solo cuando hay calibración.
      final estimator = PefEstimator(
        calibrationPeakRms: _calibrationPeak,
        personalBestPef: _personalBestPef ?? _defaultPersonalBest,
      );
      int value;
      if (estimator.isCalibrated) {
        value = estimator.estimate(PefFeatures(
          acousticPeak: result.acousticPeak,
          durationMs: result.durationMs,
          meanZcr: result.meanZcr,
        ));
      } else {
        // Sin calibración: el intento sirve para CALIBRAR. Guardamos su pico
        // acústico y lo anclamos al mejor PEF personal (=100%).
        value = _personalBestPef ?? _defaultPersonalBest;
      }
      debugPrint('[PEF] VALIDO: peak=${result.acousticPeak.toStringAsFixed(0)} -> pef=$value L/min (calibrando=${!estimator.isCalibrated})');
      _recordAttempt(value, null);
      // Guardar el pico acústico de este intento válido para la calibración.
      if (!estimator.isCalibrated) {
        // durante la primera medición (calibración) guardamos el MAYOR pico
        final currentBest = _bestAcousticPeakFromAttempts();
        final peakNow = result.acousticPeak;
        if (peakNow > currentBest) {
          _pendingCalibrationPeak = peakNow;
        }
      }
    }

    if (_blowValues.length >= 3) {
      final valid = _blowValues.whereType<int>().toList();
      if (valid.isEmpty) {
        debugPrint('[PEF] Sin intentos validos');
        if (mounted) setState(() {});
      } else {
        final best = valid.reduce((a, b) => a > b ? a : b);
        // Primera vez: persistimos la calibración con el mejor pico registrado.
        if (_calibrationPeak == null && _pendingCalibrationPeak != null) {
          _calibrationPeak = _pendingCalibrationPeak;
          await _saveCalibration(_pendingCalibrationPeak!);
          debugPrint('[PEF] CALIBRADO: peak=${_pendingCalibrationPeak} anclado a personalBest=${_personalBestPef}');
        }
        if (mounted) {
          setState(() {
            _simulatedPef = best;
            _currentStep = SimulationStep.symptoms;
          });
        }
      }
    }
  }

  double _bestAcousticPeakFromAttempts() => _pendingCalibrationPeak ?? 0;
  double? _pendingCalibrationPeak;

  void _retryLastAttempt() {
    _stopRecorder();
    if (!mounted) return;
    setState(() {
      if (_blowValues.isNotEmpty) {
        _blowValues.removeLast();
      }
      _blowAttempt = _blowValues.length;
      _invalidReason = null;
      _liveRms = 0;
    });
  }

  void _resetBlows() {
    _stopRecorder();
    if (!mounted) return;
    setState(() {
      _blowValues.clear();
      _blowAttempt = 0;
      _liveRms = 0;
      _invalidReason = null;
      _currentStep = SimulationStep.blowing;
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

    double? lat;
    double? lng;

    try {
      final dio = ref.read(dioClientProvider);
      final supabaseDs = ref.read(supabaseAuthDataSourceProvider);
      final token = await supabaseDs.getIdToken();
      if (token == null) throw Exception('No auth token');

      double? lat2;
      double? lng2;
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
          lat2 = position.latitude;
          lng2 = position.longitude;
        }
      } catch (e) {
        debugPrint('Error obteniendo ubicación: $e');
      }

      lat = lat2;
      lng = lng2;

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
      // Sin internet: guardamos la medición en la cola local para reenviarla
      // cuando vuelva la conexión (no se pierde la lectura del PEF).
      try {
        final watchState = ref.read(smartwatchProvider);
        final payload = {
          'pef': _simulatedPef,
          'symptoms': symptoms,
          'symptom_intensity': symptomIntensity,
          'spo2': watchState.spO2,
          'heart_rate': watchState.heartRate,
          'steps': watchState.steps,
          'sleep_hours': watchState.sleepHours,
          'respiratory_rate': watchState.respiratoryRate,
          'notes': notes,
          'measured_at': DateTime.now().toIso8601String(),
        };
        final Map<String, dynamic> q = {};
        if (lat != null && lng != null) {
          q['lat'] = lat;
          q['lng'] = lng;
        }
        final supabaseDs = ref.read(supabaseAuthDataSourceProvider);
        final token = await supabaseDs.getIdToken();
        await PendingMeasurementsService().enqueue(
          endpoint: '/api/measurements/spirometer',
          data: payload,
          queryParameters: q.isNotEmpty ? q : null,
          token: token,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Sin conexión. Tu medición quedó guardada y se enviará automáticamente.',
              ),
              backgroundColor: const Color(0xFF023E8A),
            ),
          );
        }
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al enviar: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
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
        child: switch (_currentStep) {
          SimulationStep.choose => _buildChoosePanel(),
          SimulationStep.ready => _buildManualFlow(),
          SimulationStep.blowing => _buildBlowingPanel(),
          SimulationStep.symptoms => _buildSymptomsPanel(),
        },
      ),
    );
  }

  Widget _buildChoosePanel() {
    return Center(
      key: const ValueKey('choose'),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.air_rounded,
              size: 80,
              color: Color(0xFF00B4D8),
            ),
            const SizedBox(height: 32),
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
              'Sopla por el micrófono de tu teléfono 3 veces y tomaremos el valor más alto.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 16,
                fontFamily: 'GeneralSans',
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _chooseBlowing,
                style: _primaryButtonStyle(),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.mic_rounded, size: 20),
                    SizedBox(width: 10),
                    Text(
                      'Soplar con el micrófono',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: OutlinedButton(
                onPressed: _chooseManual,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white70,
                  side: const BorderSide(color: Colors.white24),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Ingresar valor manual',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManualFlow() {
    return Center(
      key: const ValueKey('manual'),
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
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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
                suffixStyle: const TextStyle(
                  color: Colors.white54,
                  fontSize: 18,
                ),
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
                style: _primaryButtonStyle(),
                child: const Text(
                  'Siguiente',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBlowingPanel() {
    final valid = _blowValues.whereType<int>().toList();
    final best = valid.isEmpty ? 0 : valid.reduce((a, b) => a > b ? a : b);
    final done = _blowAttempt >= 3;
    final lastInvalid = _blowValues.isNotEmpty && _blowValues.last == null;

    return Center(
      key: const ValueKey('blowing'),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_calibrating) ...[
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF023E8A).withOpacity(0.35),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: const Color(0xFF00B4D8).withOpacity(0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.tune_rounded,
                        color: Color(0xFF00B4D8), size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Primera medición: sopla con tu MÁXIMA fuerza las 3 veces. Se calibrará con tu mejor PEF personal.',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.85),
                          fontSize: 12.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 170,
                  height: 170,
                  child: CircularProgressIndicator(
                    value: (_blowAttempt / 3).clamp(0.0, 1.0),
                    strokeWidth: 10,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF00B4D8),
                    ),
                    backgroundColor: Colors.white.withOpacity(0.08),
                    strokeCap: StrokeCap.round,
                  ),
                ),
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    final strength = _recording
                        ? (0.9 + _pulseController.value * 0.15)
                        : 1.0;
                    return Transform.scale(
                      scale: strength,
                      child: Icon(
                        Icons.mic_rounded,
                        size: 78,
                        color: _recording
                            ? const Color(0xFF00B4D8)
                            : Colors.white.withOpacity(0.35),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 28),
            Text(
              !done && _recording
                  ? '¡Sopla ahora!'
                  : done
                      ? 'Medición completada'
                      : 'Prepárate para soplar',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontFamily: 'Satoshi',
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            if (_isEncouraging == 1 && _recording)
              Text(
                'Sopla más fuerte',
                style: TextStyle(
                  color: Colors.amberAccent.shade100,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              )
            else
              Text(
                'Coloca el teléfono a la altura de tu boca y sopla fuerte por 3 segundos.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.55),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 30),
            if (_recording) ...[
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: (_liveRms / 16000).clamp(0.0, 1.0),
                  backgroundColor: Colors.white.withOpacity(0.1),
                  color: const Color(0xFF00B4D8),
                  minHeight: 10,
                ),
              ),
              const SizedBox(height: 24),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(3, (i) {
                final hasValue = i < _blowValues.length && _blowValues[i] != null;
                final invalid = i < _blowValues.length && _blowValues[i] == null;
                return _AttemptPill(
                  index: i,
                  value: i < _blowValues.length ? _blowValues[i] : null,
                  invalid: invalid,
                  isCurrent: i == _blowAttempt - 1 && _recording,
                );
              }),
            ),
            const SizedBox(height: 32),
            if (_micDenied) ...[
              Text(
                'Se negó el acceso al micrófono. Actívalo en ajustes e intenta de nuevo.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.redAccent, fontSize: 14),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _startBlow,
                child: const Text(
                  'Reintentar',
                  style: TextStyle(color: Color(0xFF00B4D8)),
                ),
              ),
            ] else if (lastInvalid && !_recording) ...[
              Text(
                _invalidReason ?? 'Intento inválido.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.amberAccent.shade100, fontSize: 14),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _startBlow,
                style: _primaryButtonStyle().copyWith(
                  minimumSize: const WidgetStatePropertyAll<Size?>(
                    Size.fromHeight(56),
                  ),
                ),
                child: Text(
                  'Reintentar intento ${_blowAttempt}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _resetBlows,
                child: Text(
                  'Reiniciar todo',
                  style: TextStyle(color: Colors.white.withOpacity(0.5)),
                ),
              ),
            ] else if (!done) ...[
              ElevatedButton(
                onPressed: _recording ? null : _startBlow,
                style: _primaryButtonStyle().copyWith(
                  minimumSize: const WidgetStatePropertyAll<Size?>(
                    Size.fromHeight(56),
                  ),
                ),
                child: Text(
                  _blowAttempt == 0
                      ? 'Comenzar'
                      : 'Soplar de nuevo (${_blowAttempt}/3)',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (_blowAttempt > 0) ...[
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _resetBlows,
                  child: Text(
                    'Reiniciar',
                    style: TextStyle(color: Colors.white.withOpacity(0.5)),
                  ),
                ),
              ],
            ] else if (valid.isEmpty) ...[
              Text(
                'No se pudo medir ningún soplo.',
                style: TextStyle(color: Colors.amberAccent.shade100, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                'Busca un lugar silencioso y vuelve a intentarlo.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _resetBlows,
                style: _primaryButtonStyle().copyWith(
                  minimumSize: const WidgetStatePropertyAll<Size?>(
                    Size.fromHeight(56),
                  ),
                ),
                child: const Text(
                  'Volver a intentar',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ] else ...[
              Text(
                'Mejor resultado: $best L/min',
                style: const TextStyle(
                  color: Color(0xFF00B4D8),
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Satoshi',
                ),
              ),
              const SizedBox(height: 6),
              _ResultSummary(
                pef: best,
                personalBest: _personalBestPef ?? _defaultPersonalBest,
              ),
              const SizedBox(height: 6),
              Text(
                'Es una estimación por micrófono calibrada con tu mejor PEF personal; no reemplaza un espirómetro médico.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.45),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => setState(() {
                    _simulatedPef = best;
                    _currentStep = SimulationStep.symptoms;
                  }),
                  style: _primaryButtonStyle(),
                  child: const Text(
                    'Continuar',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: _resetBlows,
                child: Text(
                  'Repetir medición',
                  style: TextStyle(color: Colors.white.withOpacity(0.5)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  ButtonStyle _primaryButtonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF023E8A),
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                  onPressed: () => setState(() {
                    _blowValues.clear();
                    _blowAttempt = 0;
                    _currentStep = SimulationStep.choose;
                  }),
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
              onPressed: _isSendingWithoutSymptoms
                  ? null
                  : () => _sendMeasurement(isWithSymptoms: false),
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

class _AttemptPill extends StatelessWidget {
  final int index;
  final int? value;
  final bool isCurrent;
  final bool invalid;

  const _AttemptPill({
    required this.index,
    required this.value,
    this.isCurrent = false,
    this.invalid = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: value != null
            ? const Color(0xFF023E8A).withOpacity(0.9)
            : invalid
                ? const Color(0xFFD90429).withOpacity(0.15)
                : Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isCurrent
              ? const Color(0xFF00B4D8)
              : invalid
                  ? const Color(0xFFD90429)
                  : Colors.white.withOpacity(0.1),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Text(
            'Intento ${index + 1}',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            invalid
                ? '✗'
                : value?.toString() ?? '--',
            style: TextStyle(
              color: invalid ? const Color(0xFFD90429) : Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              fontFamily: 'Satoshi',
            ),
          ),
          Text(
            value != null ? 'L/min' : '',
            style: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 9),
          ),
        ],
      ),
    );
  }
}

/// Resumen clínico: % del mejor PEF personal + semáforo GINA.
class _ResultSummary extends StatelessWidget {
  final int pef;
  final int personalBest;

  const _ResultSummary({required this.pef, required this.personalBest});

  @override
  Widget build(BuildContext context) {
    final pct = personalBest > 0 ? (pef / personalBest) * 100.0 : 0.0;
    final String zone;
    final Color color;
    if (pct >= 80) {
      zone = 'Verde';
      color = const Color(0xFF4CAF50);
    } else if (pct >= 50) {
      zone = 'Amarillo';
      color = const Color(0xFFFF9800);
    } else {
      zone = 'Rojo';
      color = const Color(0xFFD90429);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            '${pct.toStringAsFixed(0)}% de tu mejor PEF · Zona $zone',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}