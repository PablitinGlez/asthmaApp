import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../providers/monitored_patients_provider.dart';
import '../dashboard/dashboard_greeting.dart';
import 'patient_location_map_sheet.dart';

class GuardianView extends ConsumerWidget {
  const GuardianView({super.key});

  void _showLinkModal(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _LinkPatientModal(controller: controller),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    final userName = user?.fullName.split(' ').first ?? "Familiar";
    final patientsAsync = ref.watch(monitoredPatientsProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.only(
        left: 24.0,
        right: 24.0,
        bottom: 80.0,
        top: kToolbarHeight + 48.0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DashboardGreeting(
            userName: userName,
            helpButtonKey: GlobalKey(),
            onHelpTap: () {}, // Tutorial próximamente
          ),
          const SizedBox(height: 32),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Personas a mi cuidado',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1D3557),
                ),
              ),
              TextButton.icon(
                onPressed: () => _showLinkModal(context, ref),
                icon: const Icon(Icons.add_circle_outline, size: 20),
                label: const Text('Vincular'),
                style: TextButton.styleFrom(foregroundColor: const Color(0xFF023E8A)),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          patientsAsync.when(
            data: (patients) {
              if (patients.isEmpty) {
                return _EmptyPatientsView(onLinkTap: () => _showLinkModal(context, ref));
              }
              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: patients.length,
                separatorBuilder: (context, index) => const SizedBox(height: 16),
                itemBuilder: (context, index) => _PatientCard(patient: patients[index]),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
          ),
        ],
      ),
    );
  }
}

class _EmptyPatientsView extends StatelessWidget {
  final VoidCallback onLinkTap;
  const _EmptyPatientsView({required this.onLinkTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100, width: 2),
      ),
      child: Column(
        children: [
          Icon(Icons.family_restroom_rounded, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text(
            'Aún no cuidas de nadie',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black54),
          ),
          const SizedBox(height: 8),
          const Text(
            'Pídele a tu familiar paciente su código de vinculación para empezar a monitorear su salud.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: onLinkTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF023E8A),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Vincular Familiar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _PatientCard extends StatelessWidget {
  final dynamic patient;
  const _PatientCard({required this.patient});

  @override
  Widget build(BuildContext context) {
    final bool hasGps = patient.latitude != null && patient.longitude != null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: Color(
                  int.parse('FF${patient.avatarBackground}', radix: 16),
                ),
                child: ClipOval(
                  child: SvgPicture.network(
                    'https://api.dicebear.com/9.x/initials/svg?seed=${patient.avatarSeed}&backgroundColor=${patient.avatarBackground}',
                    width: 56,
                    height: 56,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      patient.fullName,
                      style: const TextStyle(
                        fontFamily: 'Satoshi',
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'Estado: Monitoreo Activo',
                          style: TextStyle(
                            fontFamily: 'GeneralSans',
                            fontSize: 13,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, thickness: 1),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => showPatientLocationMapSheet(context, patient),
                  icon: Icon(
                    hasGps ? Icons.location_on_rounded : Icons.map_outlined,
                    size: 18,
                    color: hasGps ? const Color(0xFFD90429) : const Color(0xFF023E8A),
                  ),
                  label: Text(
                    hasGps ? 'Ver Ubicación GPS' : 'Ver Mapa de Ubicación',
                    style: TextStyle(
                      fontFamily: 'Satoshi',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: hasGps ? const Color(0xFFD90429) : const Color(0xFF023E8A),
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: hasGps
                          ? const Color(0xFFD90429).withValues(alpha: 0.5)
                          : const Color(0xFF023E8A).withValues(alpha: 0.3),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LinkPatientModal extends ConsumerStatefulWidget {
  final TextEditingController controller;
  const _LinkPatientModal({required this.controller});

  @override
  ConsumerState<_LinkPatientModal> createState() => _LinkPatientModalState();
}

class _LinkPatientModalState extends ConsumerState<_LinkPatientModal> {
  bool _isLoading = false;

  void _submit() async {
    final code = widget.controller.text.trim();
    if (code.length < 6) return;

    setState(() => _isLoading = true);
    try {
      await ref.read(monitoredPatientsProvider.notifier).linkPatient(code);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡Vinculación exitosa!')),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 24),
            const Text('Vincular a un familiar', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            const Text('Ingresa el código de 6 dígitos que aparece en la aplicación de tu familiar.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 32),
            TextField(
              controller: widget.controller,
              textAlign: TextAlign.center,
              maxLength: 10,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 4),
              decoration: InputDecoration(
                hintText: 'ASMA-XXXX',
                counterText: '',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF023E8A),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white) 
                  : const Text('Activar Monitoreo', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
