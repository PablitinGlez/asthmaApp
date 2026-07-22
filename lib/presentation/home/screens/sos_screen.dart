import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vibration/vibration.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:avatar_glow/avatar_glow.dart';
import 'package:animate_do/animate_do.dart';

import '../providers/prediction_provider.dart';
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
      final hasVibrator = await Vibration.hasVibrator() ?? false;
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
    // Obtenemos los contactos de emergencia
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
    final redZoneInstruction = actionState.steps != null && actionState.steps!.isNotEmpty
        ? actionState.steps!.firstWhere(
            (step) => step.isCritical || step.stepTitle.toLowerCase().contains('roja'),
            orElse: () => actionState.steps!.length >= 3 
                ? actionState.steps![2] 
                : actionState.steps!.last,
          ).stepDescription
        : "Busca ayuda médica de inmediato. Sigue tu protocolo de crisis.";

    final emergencyPhone = primaryContact?.phoneNumber;
    final emergencyContactName = primaryContact?.contactName ?? "tu contacto";

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
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FadeInDown(
                    duration: const Duration(milliseconds: 600),
                    child: const Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.white,
                      size: 100,
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  FadeIn(
                    delay: const Duration(milliseconds: 300),
                    child: const Text(
                      'ESTADO DE CRISIS',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Satoshi',
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 10),
                  
                  FadeIn(
                    delay: const Duration(milliseconds: 500),
                    child: Text(
                      'La IA ha detectado un riesgo muy alto de ataque de asma.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 18,
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Caja de instrucciones médicas (Plan de Acción)
                  ZoomIn(
                    delay: const Duration(milliseconds: 700),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.medical_services, color: Color(0xFFD90429)),
                              const SizedBox(width: 10),
                              Text(
                                'Instrucción de tu Médico:',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            redZoneInstruction,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Color(0xFF2B2D42),
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 50),

                  // Botón de llamada
                  ElasticIn(
                    delay: const Duration(milliseconds: 1000),
                    child: SizedBox(
                      width: double.infinity,
                      height: 80,
                      child: ElevatedButton.icon(
                        onPressed: () => _makeEmergencyCall(emergencyPhone),
                        icon: const Icon(Icons.phone_in_talk_rounded, size: 30),
                        label: Text(
                          'LLAMAR A $emergencyContactName'.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFFD90429),
                          elevation: 10,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Botón para cancelar / estoy bien
                  FadeIn(
                    delay: const Duration(milliseconds: 1500),
                    child: TextButton(
                      onPressed: () {
                        // Aquí podríamos resetear el estado de la IA si fuera necesario
                        context.pop();
                      },
                      child: const Text(
                        'Ya me siento mejor / Cancelar',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
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
}
