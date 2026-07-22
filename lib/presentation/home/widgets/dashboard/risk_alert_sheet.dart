import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vibration/vibration.dart';
import '../../../action_plan/providers/action_plan_provider.dart';
import '../../../auth/providers/auth_provider.dart';

/// Nivel de riesgo calculado con la última lectura
enum PefRiskLevel { red, yellow }

/// Muestra el bottom sheet de alerta + vibración.
/// Llámalo con: showRiskAlertSheet(context, ref, pef)
Future<void> showRiskAlertSheet(
  BuildContext context,
  WidgetRef ref,
  int pef,
) async {
  final risk = _classifyPef(pef);
  // —— Registro en el backend (Asíncrono sin bloquear la alerta) ——
  Future.microtask(() async {
    debugPrint('🔔 [ALERTA] Intentando registrar alerta en el backend: PEF=$pef, Nivel=${risk == PefRiskLevel.red ? 'red' : 'yellow'}');
    try {
      final dioClient = ref.read(dioClientProvider);
      
      final response = await dioClient.post(
        '/api/patient-alerts',
        data: {
          'pef_value': pef,
          'risk_level': risk == PefRiskLevel.red ? 'red' : 'yellow',
        },
      );
      
      debugPrint('✅ [ALERTA] ÉXITO al registrar alerta en backend. Código: ${response.statusCode}');
      debugPrint('✅ [ALERTA] Datos de respuesta: ${response.data}');
    } catch (e, stackTrace) {
      debugPrint('❌ [ALERTA FATAL] Error al registrar alerta en backend:');
      debugPrint('❌ [ALERTA FATAL] Excepción: $e');
      debugPrint('❌ [ALERTA FATAL] Detalle del objeto de error: ${e.toString()}');
      debugPrint('❌ [ALERTA FATAL] Stacktrace: $stackTrace');
    }
  });

  // —— Vibración real según severidad ———————————————————————
  final canVibrate = await Vibration.hasVibrator() ?? false;
  if (canVibrate) {
    if (risk == PefRiskLevel.red) {
      // ~8 segundos de vibración INTENSA y casi continua (zona crítica)
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
      // ~6 segundos de vibración constante (zona amarilla)
      Vibration.vibrate(
        pattern: [0, 800, 100, 800, 100, 800, 100, 800, 100, 800, 100, 800],
        intensities: [0, 220, 0, 220, 0, 220, 0, 220, 0, 220, 0, 220],
      );
    }
  } else {
    // Fallback háptico si el dispositivo no tiene vibrador dedicado
    HapticFeedback.mediumImpact();
  }

  if (!context.mounted) return;

  await showModalBottomSheet(
    context: context,
    isDismissible: risk == PefRiskLevel.yellow, // Rojo solo cierra con botón
    enableDrag: risk == PefRiskLevel.yellow,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _RiskAlertSheet(risk: risk!, pef: pef),
  );
}

PefRiskLevel? _classifyPef(int pef) {
  if (pef < 200) return PefRiskLevel.red;
  if (pef < 350) return PefRiskLevel.yellow;
  return null; // Verde
}

// ─────────────────────────────────────────────────────────
class _RiskAlertSheet extends ConsumerWidget {
  final PefRiskLevel risk;
  final int pef;

  const _RiskAlertSheet({required this.risk, required this.pef});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isRed = risk == PefRiskLevel.red;
    final hasPlan = ref.watch(actionPlanProvider.select((s) => s.hasPlan));

    final Color accentColor = isRed
        ? const Color(0xFFE53935)
        : const Color(0xFFF57F17);
    final Color bgColor = isRed
        ? const Color(0xFF1A0A0A)
        : const Color(0xFF1A1500);
    final IconData icon = isRed
        ? Icons.warning_amber_rounded
        : Icons.info_outline_rounded;
    final String title = isRed
        ? '⚠️ Riesgo Crítico Detectado'
        : '⚠️ Zona de Precaución';
    final String subtitle = isRed
        ? 'Tu PEF ($pef L/min) está en zona roja. Actúa de inmediato.'
        : 'Tu PEF ($pef L/min) está por debajo del umbral seguro. Mantente atento.';

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.4),
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Ícono pulsante ──────────────────────────
            _PulsingIcon(color: accentColor, icon: icon),
            const SizedBox(height: 20),

            // ── Título ──────────────────────────────────
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Satoshi',
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: accentColor,
              ),
            ),
            const SizedBox(height: 8),

            // ── Subtítulo ───────────────────────────────
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'GeneralSans',
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.75),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),

            // ── CTA principal ───────────────────────────
            if (hasPlan)
              _ActionButton(
                label: 'Ver mi Plan de Acción',
                icon: Icons.health_and_safety_rounded,
                color: accentColor,
                onTap: () {
                  Navigator.of(context).pop();
                  context.push('/action-plan', extra: true);
                },
              )
            else
              _ActionButton(
                label: 'Configura tu Plan de Acción',
                icon: Icons.add_circle_outline_rounded,
                color: accentColor,
                onTap: () {
                  Navigator.of(context).pop();
                  context.push('/action-plan');
                },
              ),

            const SizedBox(height: 12),

            // ── Botón secundario ────────────────────────
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Entendido, cerrar',
                style: TextStyle(
                  fontFamily: 'GeneralSans',
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.45),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Botón de acción ──────────────────────────────────────
class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(
          label,
          style: const TextStyle(
            fontFamily: 'Satoshi',
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
      ),
    );
  }
}

// ── Ícono pulsante animado ───────────────────────────────
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
