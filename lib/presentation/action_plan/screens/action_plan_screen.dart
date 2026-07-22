import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../../common/widgets/snackbar_helper.dart';
import '../providers/action_plan_provider.dart';
import '../../../infrastructure/models/action_plan_model.dart';

class ActionPlanScreen extends ConsumerStatefulWidget {
  final bool isReadOnly;
  const ActionPlanScreen({super.key, this.isReadOnly = false});

  @override
  ConsumerState<ActionPlanScreen> createState() => _ActionPlanScreenState();
}

class _ActionPlanScreenState extends ConsumerState<ActionPlanScreen> {
  final _formKey = GlobalKey<FormState>();
  final _greenController = TextEditingController();
  final _yellowController = TextEditingController();
  final _redController = TextEditingController();

  @override
  void initState() {
    super.initState();

    if (widget.isReadOnly) {
      // 1. Intentar poblar inmediatamente si ya tenemos la data en el provider
      final currentSteps = ref.read(actionPlanProvider).steps;
      if (currentSteps != null && currentSteps.isNotEmpty) {
        _populateControllers(currentSteps);
      }

      // 2. Forzar recarga fresca del plan
      Future.microtask(
        () => ref.read(actionPlanProvider.notifier).loadActionPlan(),
      );
    }

    // 3. Escuchar reactivamente cuando llegan los datos (o cambian)
    ref.listenManual(actionPlanProvider, (previous, next) {
      // Si llegan steps nuevos y estamos en modo lectura, poblamos
      if (widget.isReadOnly &&
          next.steps != null &&
          next.steps!.isNotEmpty &&
          (previous?.steps == null || previous!.steps!.isEmpty)) {
        _populateControllers(next.steps!);
      }

      if (next.errorMessage != null &&
          !next.isLoading &&
          previous?.errorMessage != next.errorMessage) {
        SnackBarHelper.showError(context, next.errorMessage!);
      }
      if (next.isSuccess && !next.isLoading) {
        ref.read(actionPlanProvider.notifier).resetState();
        _showPermissionDialog();
      }
    });
  }

  void _populateControllers(List<ActionStepModel> steps) {
    _greenController.text = steps
        .firstWhere(
          (s) => s.stepOrder == 1,
          orElse: () =>
              ActionStepModel(stepOrder: 1, stepTitle: '', stepDescription: ''),
        )
        .stepDescription;
    _yellowController.text = steps
        .firstWhere(
          (s) => s.stepOrder == 2,
          orElse: () =>
              ActionStepModel(stepOrder: 2, stepTitle: '', stepDescription: ''),
        )
        .stepDescription;
    _redController.text = steps
        .firstWhere(
          (s) => s.stepOrder == 3,
          orElse: () =>
              ActionStepModel(stepOrder: 3, stepTitle: '', stepDescription: ''),
        )
        .stepDescription;
  }

  void _showPermissionDialog() {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Permisos',
      barrierColor: Colors.black.withOpacity(0.6),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: anim1, curve: Curves.easeOutBack),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF023E8A).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.verified_user_rounded,
                          color: Color(0xFF023E8A),
                          size: 48,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        '¡Plan Médico Guardado!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Satoshi',
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Te sugerimos activar las alertas para avisarte oportunamente de cualquier riesgo.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'GeneralSans',
                          fontSize: 15,
                          color: Colors.black54,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () async {
                            final messaging = FirebaseMessaging.instance;
                            NotificationSettings settings = await messaging
                                .requestPermission(
                                  alert: true,
                                  badge: true,
                                  sound: true,
                                );

                            if (context.mounted) {
                              Navigator.pop(context); // Cierra dialogo
                              context.pop(); // Vuelve al home

                              if (settings.authorizationStatus ==
                                  AuthorizationStatus.authorized) {
                                SnackBarHelper.showSuccess(
                                  context,
                                  'Alertas habilitadas. ¡Estás protegido!',
                                );
                              } else {
                                SnackBarHelper.showError(
                                  context,
                                  'Permisos denegados. Actívalos en Ajustes para protegerte.',
                                );
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF023E8A),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Activar Alertas',
                            style: TextStyle(
                              fontFamily: 'Satoshi',
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          context.pop();
                        },
                        child: const Text(
                          'Ahora no',
                          style: TextStyle(
                            fontFamily: 'Satoshi',
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final actionState = ref.watch(actionPlanProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Plan de Acción Médico',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.w700,
            fontFamily: 'Satoshi',
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Transcribe las indicaciones de tu médico para saber qué medicina tomar en cada zona de riesgo de tu asma.',
                  style: TextStyle(
                    fontFamily: 'GeneralSans',
                    fontSize: 15,
                    color: Colors.black54,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),

                // ZONA VERDE
                _ZoneCard(
                  title: 'Zona Verde - Todo en orden',
                  subtitle: 'Medicamentos de mantenimiento',
                  color: const Color(0xFF2ECC71),
                  controller: _greenController,
                  hint: 'Ej: Tomar Montelukast 1 vez al día',
                  isReadOnly: widget.isReadOnly,
                ),
                const SizedBox(height: 24),

                // ZONA AMARILLA
                _ZoneCard(
                  title: 'Zona Amarilla - Precaución',
                  subtitle: 'Medicamentos de rescate',
                  color: const Color(0xFFF1C40F),
                  controller: _yellowController,
                  hint: 'Ej: Salbutamol 2 disparos cada 8 horas',
                  isReadOnly: widget.isReadOnly,
                ),
                const SizedBox(height: 24),

                // ZONA ROJA
                _ZoneCard(
                  title: 'Zona Roja - Emergencia',
                  subtitle: 'Protocolo de crisis',
                  color: const Color(0xFFE74C3C),
                  controller: _redController,
                  hint: 'Ej: Salbutamol 4 disparos y acudir a Urgencias',
                  isReadOnly: widget.isReadOnly,
                ),

                const SizedBox(height: 48),

                // BOTÓN GUARDAR
                if (!widget.isReadOnly)
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: actionState.isLoading
                          ? null
                          : () {
                              if (_formKey.currentState!.validate()) {
                                ref
                                    .read(actionPlanProvider.notifier)
                                    .saveActionPlan(
                                      _greenController.text.trim(),
                                      _yellowController.text.trim(),
                                      _redController.text.trim(),
                                    );
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF023E8A),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey.shade300,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: actionState.isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 3,
                              ),
                            )
                          : const Text(
                              'Guardar Plan',
                              style: TextStyle(
                                fontFamily: 'Satoshi',
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ZoneCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color color;
  final TextEditingController controller;
  final String hint;
  final bool isReadOnly;

  const _ZoneCard({
    required this.title,
    required this.subtitle,
    required this.color,
    required this.controller,
    required this.hint,
    this.isReadOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header (Color Ribbon)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.shield_rounded, color: color, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontFamily: 'Satoshi',
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: color == const Color(0xFFF1C40F)
                              ? Colors.orange.shade800
                              : color,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontFamily: 'GeneralSans',
                          fontSize: 12,
                          color: Colors.black54,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Body (Input form)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextFormField(
              controller: controller,
              readOnly: isReadOnly,
              maxLines: 3,
              style: const TextStyle(
                fontFamily: 'GeneralSans',
                fontSize: 15,
                color: Colors.black87,
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                border: InputBorder.none,
                focusedBorder: InputBorder.none,
                enabledBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Por favor ingresa las indicaciones médicas';
                }
                return null;
              },
            ),
          ),
        ],
      ),
    );
  }
}
