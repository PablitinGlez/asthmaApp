import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import '../providers/permissions_provider.dart';

/// Guía paso a paso para activar cada permiso que la app necesita.
/// Cada paso muestra qué hace el permiso, por qué es importante y un botón
/// para activarlo directamente (o abrir Ajustes si fue denegado para siempre).
class PermissionGuideScreen extends ConsumerStatefulWidget {
  const PermissionGuideScreen({super.key});

  @override
  ConsumerState<PermissionGuideScreen> createState() =>
      _PermissionGuideScreenState();
}

class _PermissionGuideScreenState extends ConsumerState<PermissionGuideScreen> {
  late final PageController _pageController;
  int _currentStep = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  List<_PermissionStep> _buildSteps(PermissionsState p) => [
        _PermissionStep(
          title: 'Notificaciones',
          subtitle: 'Alertas de la IA',
          description:
              'Recibirás alertas si tu asma entra en Zona Roja, recordatorios de medicación y avisos de tu médico.',
          icon: Icons.notifications_active_outlined,
          color: const Color(0xFFF59E0B),
          isGranted: p.notificationStatus == PermissionStatus.granted ||
              p.notificationStatus == PermissionStatus.limited,
          onRequest: () => ref
              .read(permissionsProvider.notifier)
              .requestNotificationPermission(),
        ),
        _PermissionStep(
          title: 'Ubicación',
          subtitle: 'Radar Ambiental',
          description:
              'Calcula el polen, la humedad y la calidad del aire de tu zona para predecir tu riesgo.',
          icon: Icons.location_on_outlined,
          color: const Color(0xFF06B6D4),
          isGranted: p.locationStatus == PermissionStatus.granted ||
              p.locationStatus == PermissionStatus.limited,
          onRequest: () =>
              ref.read(permissionsProvider.notifier).requestLocationPermission(),
        ),
        _PermissionStep(
          title: 'Salud y Actividad',
          subtitle: 'Smartwatch',
          description:
              'Lee tu frecuencia cardíaca, SpO2 y pasos desde Health Connect para tus mediciones.',
          icon: Icons.favorite_border_rounded,
          color: const Color(0xFFEC4899),
          isGranted: p.healthStatus == PermissionStatus.granted ||
              p.healthStatus == PermissionStatus.limited,
          onRequest: () =>
              ref.read(permissionsProvider.notifier).requestHealthPermission(),
        ),
        _PermissionStep(
          title: 'Monitoreo en segundo plano',
          subtitle: 'Sincronización continua',
          description:
              'Permite que la app vigile tus signos y sincronice aunque la pantalla esté apagada. Incluye ubicación "siempre" y exención de batería.',
          icon: Icons.battery_saver_outlined,
          color: const Color(0xFF10B981),
          isGranted: p.batteryOptimizationExempt,
          onRequest: () => ref
              .read(permissionsProvider.notifier)
              .requestBackgroundMonitoring(),
        ),
        _PermissionStep(
          title: 'Micrófono',
          subtitle: 'Medición de PEF',
          description:
              'Necesario para medir tu PEF soplando al micrófono del teléfono en el espirómetro.',
          icon: Icons.mic_none_rounded,
          color: const Color(0xFF6366F1),
          isGranted: true, // se pide de forma contextual al medir
          onRequest: () {},
        ),
      ];

  @override
  Widget build(BuildContext context) {
    final permissions = ref.watch(permissionsProvider);
    final steps = _buildSteps(permissions);
    final step = steps[_currentStep];

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
          'Activa tus permisos',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.w600,
            fontFamily: 'Satoshi',
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Row(
              children: List.generate(steps.length, (i) {
                final isCurrent = i == _currentStep;
                final isDone = i < _currentStep;
                return Expanded(
                  child: Container(
                    height: 5,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: isDone
                          ? const Color(0xFF023E8A)
                          : isCurrent
                              ? const Color(0xFF0077B6)
                              : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                );
              }),
            ),
          ),
          Expanded(
            child: PageView.builder(
              itemCount: steps.length,
              controller: _pageController,
              onPageChanged: (i) => setState(() => _currentStep = i),
              itemBuilder: (context, index) => _StepCard(
                step: steps[index],
                stepNumber: index + 1,
                totalSteps: steps.length,
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
          child: Row(
            children: [
              if (_currentStep > 0) ...[
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _pageController.previousPage(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOut,
                    ),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                      side: const BorderSide(color: Color(0xFF023E8A)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Atrás',
                      style: TextStyle(color: Color(0xFF023E8A)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    if (_currentStep < steps.length - 1) {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOut,
                      );
                    } else {
                      context.pop();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF023E8A),
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    _currentStep == steps.length - 1 ? '¡Listo!' : 'Siguiente',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
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

class _StepCard extends StatelessWidget {
  final _PermissionStep step;
  final int stepNumber;
  final int totalSteps;

  const _StepCard({
    required this.step,
    required this.stepNumber,
    required this.totalSteps,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: step.color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(step.icon, color: step.color, size: 40),
          ),
          const SizedBox(height: 24),
          Text(
            step.title,
            style: const TextStyle(
              fontFamily: 'Satoshi',
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: Color(0xFF03045E),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            step.subtitle,
            style: TextStyle(
              fontFamily: 'GeneralSans',
              fontSize: 14,
              color: step.color,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            step.description,
            style: TextStyle(
              fontFamily: 'GeneralSans',
              fontSize: 15,
              color: Colors.grey.shade700,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          if (stepNumber < totalSteps) ...[
            _InfoRow(
              icon: Icons.lock_outline_rounded,
              text: 'Tus datos nunca salen de tu dispositivo sin tu permiso.',
            ),
            const SizedBox(height: 10),
            _InfoRow(
              icon: Icons.settings_outlined,
              text:
                  'Puedes cambiar estos permisos en cualquier momento desde Ajustes.',
            ),
            const SizedBox(height: 24),
            step.isGranted
                ? Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle_rounded, color: Colors.green),
                        SizedBox(width: 8),
                        Text(
                          'Permiso activado',
                          style: TextStyle(
                            color: Colors.green,
                            fontFamily: 'Satoshi',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  )
                : ElevatedButton.icon(
                    onPressed: step.onRequest,
                    icon: const Icon(Icons.touch_app_outlined, size: 20),
                    label: Text('Activar ${step.title.toLowerCase()}'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: step.color,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
          ] else ...[
            _InfoRow(
              icon: Icons.info_outline_rounded,
              text:
                  'Este permiso se pide automáticamente cuando inicias una medición de PEF soplando al micrófono. No necesitas activarlo ahora.',
            ),
          ],
          const SizedBox(height: 24),
          Text(
            'Paso $stepNumber de $totalSteps',
            style: TextStyle(
              fontFamily: 'GeneralSans',
              fontSize: 13,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: const Color(0xFF023E8A)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontFamily: 'GeneralSans',
              fontSize: 13,
              color: Colors.grey.shade600,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

class _PermissionStep {
  final String title;
  final String subtitle;
  final String description;
  final IconData icon;
  final Color color;
  final bool isGranted;
  final VoidCallback onRequest;

  const _PermissionStep({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.color,
    required this.isGranted,
    required this.onRequest,
  });
}
