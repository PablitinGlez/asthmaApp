import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../profile/providers/permissions_provider.dart';

/// Tarjeta de aviso que aparece en el dashboard mientras haya permisos
/// pendientes de activar. Muestra cuántos faltan y un botón que abre la
/// guía paso a paso.
class PermissionsReminderCard extends ConsumerWidget {
  const PermissionsReminderCard({super.key});

  bool _isGranted(PermissionStatus s) =>
      s == PermissionStatus.granted || s == PermissionStatus.limited;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(permissionsProvider);

    if (p.isLoading) return const SizedBox.shrink();

    final missing = <String>[
      if (!_isGranted(p.notificationStatus)) 'notificaciones',
      if (!_isGranted(p.locationStatus)) 'ubicación',
      if (!_isGranted(p.healthStatus)) 'salud y actividad',
      if (!p.batteryOptimizationExempt) 'monitoreo en segundo plano',
    ];

    if (missing.isEmpty) return const SizedBox.shrink();

    final label = missing.length == 1
        ? 'Falta activar el permiso de ${missing.first}'
        : 'Faltan ${missing.length} permisos por activar';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFB74D)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: Color(0xFFFFF8E1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              color: Color(0xFFE65100),
              size: 26,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Activa tus permisos',
                  style: TextStyle(
                    fontFamily: 'Satoshi',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFE65100),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$label para el correcto funcionamiento de la app.',
                  style: const TextStyle(
                    fontFamily: 'GeneralSans',
                    fontSize: 12.5,
                    color: Color(0xFF8D6E63),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => context.push('/permissions-guide'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFE65100),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Configurar',
                style: TextStyle(
                  fontFamily: 'Satoshi',
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
