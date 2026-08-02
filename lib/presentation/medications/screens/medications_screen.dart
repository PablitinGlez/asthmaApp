import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../providers/medications_provider.dart';
import '../../../domain/models/medication.dart';
import '../../../infrastructure/notifications/services/local_notification_service.dart';

class MedicationsScreen extends ConsumerWidget {
  const MedicationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(medicationsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        title: const Text(
          'Mis Medicamentos',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontFamily: 'Satoshi',
            color: Color(0xFF1D3557),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1D3557)),
          onPressed: () => context.pop(),
        ),
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.medications.isEmpty
              ? _buildEmptyState(context, ref)
              : _buildMedicationList(context, ref, state.medications),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddMedicationModal(context, ref),
        backgroundColor: const Color(0xFF023E8A),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'Añadir',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.medication_liquid_rounded, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'No tienes medicamentos registrados',
            style: TextStyle(
              fontSize: 18,
              fontFamily: 'Satoshi',
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Añade uno para empezar tu seguimiento',
            style: TextStyle(
              fontSize: 14,
              fontFamily: 'GeneralSans',
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicationList(BuildContext context, WidgetRef ref, List<Medication> medications) {
    return ReorderableListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      itemCount: medications.length,
      onReorder: (oldIndex, newIndex) {
        
      },
      itemBuilder: (context, index) {
        final med = medications[index];
        return _MedicationCard(key: ValueKey(med.id), medication: med);
      },
    );
  }

  void _showAddMedicationModal(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddMedicationModal(),
    );
  }
}

class _MedicationCard extends ConsumerStatefulWidget {
  final Medication medication;
  const _MedicationCard({required super.key, required this.medication});

  @override
  ConsumerState<_MedicationCard> createState() => _MedicationCardState();
}

class _MedicationCardState extends ConsumerState<_MedicationCard> {
  bool _isRegistering = false;

  @override
  Widget build(BuildContext context) {
    final medication = widget.medication;
    final nextDoseStr = medication.nextDose != null 
        ? DateFormat('HH:mm').format(medication.nextDose!) 
        : 'No programada';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Container(
                width: 6,
                color: const Color(0xFF023E8A),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              medication.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Satoshi',
                                color: Color(0xFF1D3557),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, color: Colors.grey),
                            onPressed: () => ref.read(medicationsProvider.notifier).deleteMedication(medication.id),
                          ),
                        ],
                      ),
                      if (medication.dosage != null)
                        Text(
                          medication.dosage!,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                            fontFamily: 'GeneralSans',
                          ),
                        ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(Icons.access_time_rounded, size: 16, color: Colors.blue.shade700),
                          const SizedBox(width: 4),
                          Text(
                            'Próxima: $nextDoseStr',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.blue.shade700,
                            ),
                          ),
                          const Spacer(),
                          if (medication.frequencyHours != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE3F2FD),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Cada ${medication.frequencyHours}h',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF023E8A),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isRegistering 
                            ? null 
                            : () async {
                              setState(() => _isRegistering = true);
                              await ref.read(medicationsProvider.notifier).registerDose(medication.id);
                              if (mounted) setState(() => _isRegistering = false);
                            },
                          icon: _isRegistering 
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.check_circle_outline_rounded, size: 18),
                          label: Text(_isRegistering ? 'Guardando...' : 'Registrar Toma'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF023E8A),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddMedicationModal extends ConsumerStatefulWidget {
  @override
  ConsumerState<_AddMedicationModal> createState() => _AddMedicationModalState();
}

class _AddMedicationModalState extends ConsumerState<_AddMedicationModal> {
  final _nameCtrl = TextEditingController();
  final _dosageCtrl = TextEditingController();
  final _freqCtrl = TextEditingController();
  TimeOfDay? _selectedTime = TimeOfDay.now();
  List<int> _selectedDays = []; 
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Añadir Medicamento',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Satoshi',
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildField('Nombre del medicamento', _nameCtrl, 'Ej: Salbutamol', enabled: !_isSaving),
            const SizedBox(height: 16),
            _buildField('Dosis', _dosageCtrl, 'Ej: 2 inhalaciones', enabled: !_isSaving),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildField(
                    'Frecuencia (horas)', 
                    _freqCtrl, 
                    'Ej: 8', 
                    keyboardType: TextInputType.number,
                    enabled: !_isSaving
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Hora primera toma', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: _isSaving ? null : () async {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.now(),
                          );
                          if (time != null) setState(() => _selectedTime = time);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: _isSaving ? Colors.grey.shade50 : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _selectedTime?.format(context) ?? '--:--',
                                style: TextStyle(fontSize: 15, color: _isSaving ? Colors.grey : Colors.black87),
                              ),
                              const Icon(Icons.access_time_rounded, size: 20, color: Colors.grey),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text('Días de repetición', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 12),
            SizedBox(
              height: 45,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: 7,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final dayIndex = index + 1;
                  final isSelected = _selectedDays.contains(dayIndex);
                  final dayName = ['L', 'M', 'M', 'J', 'V', 'S', 'D'][index];
                  
                  return InkWell(
                    onTap: _isSaving ? null : () {
                      setState(() {
                        if (isSelected) _selectedDays.remove(dayIndex);
                        else _selectedDays.add(dayIndex);
                      });
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 45,
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF023E8A) : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? const Color(0xFF023E8A) : Colors.transparent,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        dayName,
                        style: TextStyle(
                          color: isSelected ? Colors.white : const Color(0xFF1D3557),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _selectedDays.isEmpty ? 'Se recordará todos los días' : 'Días seleccionados: ${_selectedDays.length}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF023E8A),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: _isSaving
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text(
                      'Guardar Medicamento',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController ctrl, String hint, {TextInputType? keyboardType, bool enabled = true}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        const SizedBox(height: 8),
        TextField(
          controller: ctrl,
          keyboardType: keyboardType,
          enabled: enabled,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: enabled ? Colors.grey.shade100 : Colors.grey.shade50,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }

  void _submit() async {
    if (_nameCtrl.text.isEmpty) return;

    setState(() => _isSaving = true);

    final now = DateTime.now();
    DateTime? nextDose;
    if (_selectedTime != null) {
      nextDose = DateTime(now.year, now.month, now.day, _selectedTime!.hour, _selectedTime!.minute);
      if (nextDose.isBefore(now)) {
        nextDose = nextDose.add(const Duration(days: 1));
      }
    }

    final success = await ref.read(medicationsProvider.notifier).addMedication({
      'name': _nameCtrl.text.trim(),
      'dosage': _dosageCtrl.text.trim().isEmpty ? null : _dosageCtrl.text.trim(),
      'frequency_hours': int.tryParse(_freqCtrl.text),
      'days_of_week': _selectedDays.isEmpty ? null : _selectedDays.join(','),
      'next_dose': nextDose?.toIso8601String(),
    });

    if (success && mounted) {
      try {
        if (nextDose != null) {
          print(' Notifier: Scheduling notification...');
          await LocalNotificationService.scheduleMedicationReminder(
            id: now.millisecondsSinceEpoch % 100000000,
            name: _nameCtrl.text.trim(),
            scheduledDate: nextDose,
            daysOfWeek: _selectedDays,
          ).timeout(const Duration(seconds: 3));
        }
      } catch (e) {
        print(' Notifier: Error al programar notificación - $e');
      }
      if (mounted) Navigator.pop(context);
    } else if (mounted) {
      setState(() => _isSaving = false);
    }
  }
}
