import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vibration/vibration.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../action_plan/providers/action_plan_provider.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../profile/providers/emergency_contacts_provider.dart';
import '../../../../infrastructure/models/action_plan_model.dart';

enum PefRiskLevel { red, yellow }

Future<void> showRiskAlertSheet(
  BuildContext context,
  WidgetRef ref,
  int pef,
) async {
  final risk = _classifyPef(pef);
  
  Future.microtask(() async {
    debugPrint(
      '[ALERTA] Intentando registrar alerta en backend: PEF=$pef, Nivel=${risk == PefRiskLevel.red ? 'red' : 'yellow'}',
    );
    try {
      final dioClient = ref.read(dioClientProvider);

      final response = await dioClient.post(
        '/api/patient-alerts',
        data: {
          'pef_value': pef,
          'risk_level': risk == PefRiskLevel.red ? 'red' : 'yellow',
        },
      );

      debugPrint(
        '[ALERTA] ÉXITO al registrar alerta en backend. Código: ${response.statusCode}',
      );
      debugPrint('[ALERTA] Datos de respuesta: ${response.data}');
    } catch (e, stackTrace) {
      debugPrint('[ALERTA FATAL] Error al registrar alerta en backend:');
      debugPrint('[ALERTA FATAL] Excepción: $e');
      debugPrint('[ALERTA FATAL] Stacktrace: $stackTrace');
    }
  });

  
  final canVibrate = await Vibration.hasVibrator();
  if (canVibrate) {
    if (risk == PefRiskLevel.red) {
      
      Vibration.vibrate(
        pattern: [
          0,
          1000,
          50,
          1000,
          50,
          1000,
          50,
          1000,
          50,
          1000,
          50,
          1000,
          50,
          1000,
          50,
          1000,
        ],
        intensities: [
          0,
          255,
          0,
          255,
          0,
          255,
          0,
          255,
          0,
          255,
          0,
          255,
          0,
          255,
          0,
          255,
        ],
      );
    } else {
      
      Vibration.vibrate(
        pattern: [0, 800, 100, 800, 100, 800, 100, 800, 100, 800, 100, 800],
        intensities: [0, 220, 0, 220, 0, 220, 0, 220, 0, 220, 0, 220],
      );
    }
  } else {
    HapticFeedback.mediumImpact();
  }

  if (!context.mounted) return;

  await showModalBottomSheet(
    context: context,
    isDismissible: risk == PefRiskLevel.yellow, 
    enableDrag: risk == PefRiskLevel.yellow,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _RiskAlertSheet(risk: risk!, pef: pef),
  );
}

PefRiskLevel? _classifyPef(int pef) {
  if (pef < 200) return PefRiskLevel.red;
  if (pef < 350) return PefRiskLevel.yellow;
  return null; 
}

class _RiskAlertSheet extends ConsumerWidget {
  final PefRiskLevel risk;
  final int pef;

  const _RiskAlertSheet({required this.risk, required this.pef});

  Future<void> _makeEmergencyCall(BuildContext context, String? phone) async {
    if (phone == null || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No tienes un número de emergencia configurado.'),
        ),
      );
      return;
    }

    final Uri launchUri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo iniciar la llamada.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isRed = risk == PefRiskLevel.red;
    final actionState = ref.watch(actionPlanProvider);
    final contactsState = ref.watch(emergencyContactsProvider);

    final primaryContact = contactsState.contacts.isNotEmpty
        ? contactsState.contacts.firstWhere(
            (c) => c.isPrimary,
            orElse: () => contactsState.contacts.first,
          )
        : null;

    final Color accentColor = isRed
        ? const Color(0xFFE53935)
        : const Color(0xFFF57F17);
    final Color bgColor = isRed
        ? const Color(0xFF140707)
        : const Color(0xFF141100);
    final IconData icon = isRed
        ? Icons.warning_amber_rounded
        : Icons.info_outline_rounded;
    final String title = isRed
        ? ' Riesgo Crítico - Zona Roja'
        : ' Zona de Precaución';
    final String subtitle = isRed
        ? 'Tu PEF ($pef L/min) indica un flujo espiratorio muy bajo. Sigue el protocolo de crisis inmediatamente.'
        : 'Tu PEF ($pef L/min) está por debajo del rango normal. Revisa las indicaciones preventivas.';

    
    ActionStepModel? targetStep;
    if (actionState.steps != null && actionState.steps!.isNotEmpty) {
      if (isRed) {
        targetStep = actionState.steps!.firstWhere(
          (step) =>
              step.isCritical ||
              step.stepTitle.toLowerCase().contains('roja') ||
              step.stepOrder == 3,
          orElse: () => actionState.steps!.last,
        );
      } else {
        targetStep = actionState.steps!.firstWhere(
          (step) =>
              step.stepTitle.toLowerCase().contains('amarilla') ||
              step.stepOrder == 2,
          orElse: () => actionState.steps!.first,
        );
      }
    }

    final hasDoctorInstruction =
        targetStep != null && targetStep.stepDescription.trim().isNotEmpty;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.5),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.25),
            blurRadius: 24,
            spreadRadius: 2,
          ),
        ],
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              
              Center(child: _PulsingIcon(color: accentColor, icon: icon)),
              const SizedBox(height: 16),

              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Satoshi',
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: accentColor,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),

              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'GeneralSans',
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.8),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),

              
              _EmergencyRecommendationsCard(isRed: isRed, accentColor: accentColor),

              const SizedBox(height: 20),

              
              _DoctorCrisisPlanCard(
                isRed: isRed,
                accentColor: accentColor,
                hasPlan: actionState.hasPlan,
                hasDoctorInstruction: hasDoctorInstruction,
                instructionText: targetStep?.stepDescription,
                onConfigureTap: () {
                  Navigator.of(context).pop();
                  context.push('/action-plan');
                },
              ),

              const SizedBox(height: 24),

              
              if (isRed && primaryContact != null) ...[
                ElevatedButton.icon(
                  onPressed: () => _makeEmergencyCall(
                    context,
                    primaryContact.phoneNumber,
                  ),
                  icon: const Icon(Icons.phone_in_talk_rounded, size: 20),
                  label: Text(
                    'LLAMAR A ${primaryContact.contactName.toUpperCase()}',
                    style: const TextStyle(
                      fontFamily: 'Satoshi',
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD90429),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                  ),
                ),
                const SizedBox(height: 12),
              ],

              if (isRed) ...[
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    context.push('/sos');
                  },
                  icon: const Icon(Icons.emergency_rounded, size: 18),
                  label: const Text(
                    'Abrir Modo SOS de Emergencia',
                    style: TextStyle(
                      fontFamily: 'Satoshi',
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(color: accentColor.withValues(alpha: 0.8)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Entendido, cerrar alerta',
                  style: TextStyle(
                    fontFamily: 'GeneralSans',
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.5),
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

class _EmergencyRecommendationsCard extends StatelessWidget {
  final bool isRed;
  final Color accentColor;

  const _EmergencyRecommendationsCard({
    required this.isRed,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.flash_on_rounded, color: accentColor, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Recomendaciones de Emergencia Inmediatas',
                  style: TextStyle(
                    fontFamily: 'Satoshi',
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Colors.white.withValues(alpha: 0.95),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildStepRow(
            number: '1',
            icon: Icons.airline_seat_recline_normal_rounded,
            title: 'Posición Erguida',
            detail: 'Siéntate derecho y mantén la calma. Evita acostarte.',
          ),
          const SizedBox(height: 10),
          _buildStepRow(
            number: '2',
            icon: Icons.medical_services_outlined,
            title: 'Inhalador de Rescate',
            detail: 'Aplica 2 a 4 inhalaciones de Salbutamol / Albuterol con espaciador.',
          ),
          const SizedBox(height: 10),
          _buildStepRow(
            number: '3',
            icon: Icons.timer_outlined,
            title: 'Reposo (5-10 min)',
            detail: 'Respira lentamente y evalúa si la opresión o tos disminuyen.',
          ),
          const SizedBox(height: 10),
          _buildStepRow(
            number: '4',
            icon: Icons.local_hospital_rounded,
            title: 'Solicita Auxilio',
            detail: isRed
                ? 'Si los síntomas empeoran o no hay mejoría, acude a urgencias inmediatamente.'
                : 'Si los síntomas no mejoran tras 20 min, repite dosis y consulta a tu médico.',
            isCriticalStep: isRed,
          ),
        ],
      ),
    );
  }

  Widget _buildStepRow({
    required String number,
    required IconData icon,
    required String title,
    required String detail,
    bool isCriticalStep = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isCriticalStep
                ? const Color(0xFFD90429)
                : Colors.white.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Text(
            number,
            style: const TextStyle(
              fontFamily: 'Satoshi',
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(
                fontFamily: 'GeneralSans',
                fontSize: 13,
                color: Colors.white70,
                height: 1.35,
              ),
              children: [
                TextSpan(
                  text: '$title: ',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: isCriticalStep
                        ? const Color(0xFFFF6B6B)
                        : Colors.white.withValues(alpha: 0.9),
                  ),
                ),
                TextSpan(text: detail),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DoctorCrisisPlanCard extends StatelessWidget {
  final bool isRed;
  final Color accentColor;
  final bool hasPlan;
  final bool hasDoctorInstruction;
  final String? instructionText;
  final VoidCallback onConfigureTap;

  const _DoctorCrisisPlanCard({
    required this.isRed,
    required this.accentColor,
    required this.hasPlan,
    required this.hasDoctorInstruction,
    this.instructionText,
    required this.onConfigureTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: hasDoctorInstruction
              ? Colors.green.shade400.withValues(alpha: 0.5)
              : Colors.amber.shade400.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                hasDoctorInstruction
                    ? Icons.verified_user_rounded
                    : Icons.assignment_late_outlined,
                color: hasDoctorInstruction
                    ? Colors.green.shade400
                    : Colors.amber.shade300,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  hasDoctorInstruction
                      ? 'Plan de Crisis (Zona ${isRed ? "Roja" : "Amarilla"})'
                      : 'Plan de Crisis Médico',
                  style: const TextStyle(
                    fontFamily: 'Satoshi',
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
              if (hasDoctorInstruction)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.green.shade500.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.green.shade400.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(
                    'Asignado por tu Médico',
                    style: TextStyle(
                      fontFamily: 'Satoshi',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.green.shade300,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (hasDoctorInstruction) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
              child: Text(
                instructionText!,
                style: const TextStyle(
                  fontFamily: 'GeneralSans',
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  height: 1.4,
                ),
              ),
            ),
          ] else ...[
            Text(
              'Aún no registras las instrucciones de tu médico para la Zona ${isRed ? "Roja (Emergencia)" : "Amarilla (Precaución)"}.',
              style: TextStyle(
                fontFamily: 'GeneralSans',
                fontSize: 13,
                color: Colors.white.withValues(alpha: 0.7),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onConfigureTap,
                icon: const Icon(Icons.add_circle_outline_rounded, size: 16),
                label: const Text(
                  'Transcribir Indicaciones del Médico',
                  style: TextStyle(
                    fontFamily: 'Satoshi',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.amber.shade300,
                  side: BorderSide(color: Colors.amber.shade300.withValues(alpha: 0.6)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PulsingIcon extends StatefulWidget {
  final Color color;
  final IconData icon;
  const _PulsingIcon({required this.color, required this.icon});

  @override
  State<_PulsingIcon> createState() => _PulsingIconState();
}

class _PulsingIconState extends State<_PulsingIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _scale = Tween<double>(
      begin: 0.95,
      end: 1.08,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.color.withValues(alpha: 0.12),
          border: Border.all(
            color: widget.color.withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        child: Icon(widget.icon, color: widget.color, size: 38),
      ),
    );
  }
}
