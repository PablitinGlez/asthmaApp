import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../common/widgets/snackbar_helper.dart';
import '../../auth/providers/auth_provider.dart';
import '../../home/providers/measurements_provider.dart';

class RegisterSymptomScreen extends ConsumerStatefulWidget {
  const RegisterSymptomScreen({super.key});

  @override
  ConsumerState<RegisterSymptomScreen> createState() =>
      _RegisterSymptomScreenState();
}

class _RegisterSymptomScreenState extends ConsumerState<RegisterSymptomScreen> {
  final List<String> _symptoms = [
    'Tos',
    'Sibilancias',
    'Disnea',
    'Opresión',
    'Fatiga',
    'Flema',
  ];
  final List<String> _selectedSymptoms = [];
  String _intensity = 'Moderada';
  final TextEditingController _notesController = TextEditingController();
  bool _isSaving = false;
  int? _linkedMeasurementId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadRecentMeasurement();
    });
  }

  void _loadRecentMeasurement() {
    final history = ref.read(measurementsProvider).value;
    if (history == null || history.allItems.isEmpty) return;

    final now = DateTime.now();
    final currentHour = DateTime(now.year, now.month, now.day, now.hour);
    final recentReadings = history.allItems.where((h) {
      final local = h.measuredAt.toLocal();
      final rh = DateTime(local.year, local.month, local.day, local.hour);
      return rh == currentHour;
    }).toList();

    if (recentReadings.isNotEmpty) {
      recentReadings.sort((a, b) => b.measuredAt.compareTo(a.measuredAt));
      final item = recentReadings.first;
      _linkedMeasurementId = item.id;

      setState(() {
        if (item.symptoms != null && item.symptoms!.isNotEmpty) {
          final parts = item.symptoms!.split('|');
          final symps = parts[0]
              .split(',')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty && e != 'Ninguno');
          _selectedSymptoms.addAll(symps);
          if (parts.length > 1) {
            _intensity = parts[1];
          }
        }
        if (item.notes != null) {
          _notesController.text = item.notes!;
        }
      });
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_selectedSymptoms.isEmpty && _notesController.text.trim().isEmpty) {
      SnackBarHelper.showError(context, 'Mete al menos un síntoma o nota');
      return;
    }

    setState(() => _isSaving = true);

    try {
      if (_linkedMeasurementId == null) {
        throw Exception(
          'Debes hacer una medición antes de registrar síntomas sueltos.',
        );
      }

      final dio = ref.read(dioClientProvider);
      final supabaseDs = ref.read(supabaseAuthDataSourceProvider);
      final token = await supabaseDs.getIdToken();
      if (token == null) throw Exception('Sin token');

      final sympStr = _selectedSymptoms.join(', ');
      final notesStr = _notesController.text.trim();

      await dio.patch(
        '/api/measurements/spirometer/$_linkedMeasurementId/symptoms',
        data: {
          'symptoms': sympStr.isEmpty ? '' : sympStr,
          'symptom_intensity': _intensity,
          'notes': notesStr.isEmpty ? '' : notesStr,
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      ref.read(measurementsProvider.notifier).silentRefresh();

      if (mounted) {
        SnackBarHelper.showSuccess(
          context,
          '✅ Síntomas vinculados a tu última medición',
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showError(
          context,
          e.toString().replaceAll('Exception: ', ''),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.black87,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Registrar Síntomas',
          style: TextStyle(
            color: Colors.black87,
            fontFamily: 'Satoshi',
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '¿Qué síntomas sientes hoy?',
              style: TextStyle(
                fontFamily: 'Satoshi',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _symptoms.map((symptom) {
                final isSelected = _selectedSymptoms.contains(symptom);
                return FilterChip(
                  label: Text(symptom),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedSymptoms.add(symptom);
                      } else {
                        _selectedSymptoms.remove(symptom);
                      }
                    });
                  },
                  selectedColor: const Color(0xFF023E8A).withOpacity(0.1),
                  checkmarkColor: const Color(0xFF023E8A),
                  labelStyle: TextStyle(
                    fontFamily: 'GeneralSans',
                    color: isSelected
                        ? const Color(0xFF023E8A)
                        : Colors.grey.shade600,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                  backgroundColor: Colors.grey.shade50,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: isSelected
                          ? const Color(0xFF023E8A)
                          : Colors.grey.shade200,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),
            const Text(
              'Intensidad',
              style: TextStyle(
                fontFamily: 'Satoshi',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: ['Leve', 'Moderada', 'Severa'].map((level) {
                final isSelected = _intensity == level;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _intensity = level),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? _getColorForIntensity(level).withOpacity(0.1)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? _getColorForIntensity(level)
                              : Colors.grey.shade200,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          level,
                          style: TextStyle(
                            fontFamily: 'Satoshi',
                            fontWeight: FontWeight.w700,
                            color: isSelected
                                ? _getColorForIntensity(level)
                                : Colors.grey.shade400,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),
            const Text(
              'Notas adicionales',
              style: TextStyle(
                fontFamily: 'Satoshi',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _notesController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Describe cómo te sientes...',
                hintStyle: TextStyle(
                  fontFamily: 'GeneralSans',
                  color: Colors.grey.shade400,
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF023E8A),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Guardar Registro',
                        style: TextStyle(
                          fontFamily: 'Satoshi',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getColorForIntensity(String intensity) {
    switch (intensity) {
      case 'Leve':
        return const Color(0xFF4CAF50);
      case 'Moderada':
        return const Color(0xFFFFC107);
      case 'Severa':
        return const Color(0xFFF44336);
      default:
        return Colors.blue;
    }
  }
}
