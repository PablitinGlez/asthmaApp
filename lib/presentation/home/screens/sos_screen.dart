import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vibration/vibration.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:avatar_glow/avatar_glow.dart';
import 'package:animate_do/animate_do.dart';

import '../../profile/providers/emergency_contacts_provider.dart';
import '../../action_plan/providers/action_plan_provider.dart';

class SosScreen extends ConsumerStatefulWidget {
  const SosScreen({super.key});

  @override
  ConsumerState<SosScreen> createState() => _SosScreenState();
}

class _SosScreenState extends ConsumerState<SosScreen> {
  @override
  void initState() {
    super.initState();
    _startVibration();
  }

  @override
  void dispose() {
    Vibration.cancel();
    super.dispose();
  }

  Future<void> _startVibration() async {
    if (kIsWeb) return;

    try {
      final hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator) {
        Vibration.vibrate(
          pattern: [500, 1000, 500, 2000],
          intensities: [0, 255, 0, 255],
          repeat: 0,
        );
      }
    } catch (e) {
      debugPrint('Vibration error: $e');
    }
  }

  Future<void> _makeEmergencyCall(String? phone) async {
    if (phone == null || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay un número de emergencia configurado.')),
      );
      return;
    }

    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phone,
    );
    
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo iniciar la llamada.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Obtenemos los contactos de emergencia y el plan de acción
    final contactsState = ref.watch(emergencyContactsProvider);
    final actionState = ref.watch(actionPlanProvider);
    
    // Buscar el contacto primario
    final primaryContact = contactsState.contacts.isNotEmpty 
        ? contactsState.contacts.firstWhere(
            (c) => c.isPrimary,
            orElse: () => contactsState.contacts.first,
          )
        : null;

    // Buscar la instrucción de la Zona Roja
    final redZoneStep = actionState.steps != null && actionState.steps!.isNotEmpty
        ? actionState.steps!.firstWhere(
            (step) => step.isCritical || step.stepTitle.toLowerCase().contains('roja') || step.stepOrder == 3,
            orElse: () => actionState.steps!.length >= 3 
                ? actionState.steps![2] 
                : actionState.steps!.last,
          )
        : null;

    final redZoneInstruction = (redZoneStep != null && redZoneStep.stepDescription.trim().isNotEmpty)
        ? redZoneStep.stepDescription
        : "Busca ayuda médica de inmediato. Aplica tu inhalador de rescate y acude a Urgencias.";

    final emergencyPhone = primaryContact?.phoneNumber;
    final emergencyContactName = primaryContact?.contactName ?? "Contacto de Emergencia";

    return Scaffold(
      backgroundColor: const Color(0xFFD90429), // Rojo SOS
      body: Stack(
        children: [
          // Fondo pulsante
          Positioned.fill(
            child: AvatarGlow(
              glowColor: Colors.white,
              duration: const Duration(milliseconds: 2000),
              repeat: true,
              child: Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.transparent,
                ),
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  FadeInDown(
                    duration: const Duration(milliseconds: 600),
                    child: const Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.white,
                      size: 80,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  FadeIn(
                    delay: const Duration(milliseconds: 300),
                    child: const Text(
                      'ESTADO DE CRISIS - ZONA ROJA',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Satoshi',
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  FadeIn(
                    delay: const Duration(milliseconds: 500),
                    child: Text(
                      'Se ha detectado un riesgo muy alto. Mantén la calma y ejecuta los pasos de emergencia.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.95),
                        fontSize: 15,
                        fontFamily: 'GeneralSans',
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Caja 1: recomendaciones de emergencia inmediatas
                  ZoomIn(
                    delay: const Duration(milliseconds: 600),
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.25),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.flash_on_rounded, color: Color(0xFFD90429), size: 22),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  'Acciones de Emergencia Inmediatas',
                                  style: TextStyle(
                                    color: Color(0xFF2B2D42),
                                    fontWeight: FontWeight.w800,
                                    fontFamily: 'Satoshi',
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 20, thickness: 1),
                          _buildStep(
                            num: '1',
                            text: 'Siéntate erguido y no te acuestes.',
                          ),
                          const SizedBox(height: 8),
                          _buildStep(
                            num: '2',
                            text: 'Inhala 2-4 pulsaciones de Salbutamol con espaciador.',
                          ),
                          const SizedBox(height: 8),
                          _buildStep(
                            num: '3',
                            text: 'Aguarda 5-10 minutos evaluando tu respiración.',
                          ),
                          const SizedBox(height: 8),
                          _buildStep(
                            num: '4',
                            text: 'Llama a urgencias si la opresión persiste.',
                            isCritical: true,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Caja 2: instrucción personalizada del médico (plan de crisis)
                  ZoomIn(
                    delay: const Duration(milliseconds: 750),
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E2C),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.medical_services_rounded, color: Color(0xFF4ECDC4), size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Plan de Crisis (Indicación Médica):',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.85),
                                    fontWeight: FontWeight.w700,
                                    fontFamily: 'Satoshi',
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            redZoneInstruction,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'GeneralSans',
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Botón de llamada
                  ElasticIn(
                    delay: const Duration(milliseconds: 900),
                    child: SizedBox(
                      width: double.infinity,
                      height: 64,
                      child: ElevatedButton.icon(
                        onPressed: () => _makeEmergencyCall(emergencyPhone),
                        icon: const Icon(Icons.phone_in_talk_rounded, size: 26),
                        label: Text(
                          'LLAMAR A $emergencyContactName'.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            fontFamily: 'Satoshi',
                            letterSpacing: 0.5,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFFD90429),
                          elevation: 8,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Botón para cancelar / estoy bien
                  FadeIn(
                    delay: const Duration(milliseconds: 1100),
                    child: TextButton(
                      onPressed: () {
                        context.pop();
                      },
                      child: const Text(
                        'Ya me siento mejor / Salir',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 15,
                          fontFamily: 'GeneralSans',
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep({
    required String num,
    required String text,
    bool isCritical = false,
  }) {
    return Row(
      children: [
        Container(
          width: 22,
          height: 22,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isCritical ? const Color(0xFFD90429) : const Color(0xFF2B2D42),
            shape: BoxShape.circle,
          ),
          child: Text(
            num,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: isCritical ? const Color(0xFFD90429) : const Color(0xFF2B2D42),
              fontSize: 13,
              fontWeight: isCritical ? FontWeight.w800 : FontWeight.w600,
              fontFamily: 'GeneralSans',
            ),
          ),
        ),
      ],
    );
  }
}
