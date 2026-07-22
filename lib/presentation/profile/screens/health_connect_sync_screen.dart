import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../home/providers/smartwatch_provider.dart';

class HealthConnectSyncScreen extends ConsumerWidget {
  const HealthConnectSyncScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final watchState = ref.watch(smartwatchProvider);
    final bool isLinked = watchState.isLinked;

    final lastSync = watchState.lastSyncTime;
    final lastSyncLabel = lastSync == null
        ? 'Nunca'
        : _formatRelativeTime(lastSync);

    // Build a count of total data points fetched today
    int readCount = 0;
    if (watchState.steps != null) readCount++;
    if (watchState.heartRate != null) readCount++;
    if (watchState.spO2 != null) readCount++;
    if (watchState.sleepHours != null) readCount++;
    if (watchState.respiratoryRate != null) readCount++;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Sincronización Health Connect',
          style: TextStyle(
            fontFamily: 'Satoshi',
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.black87,
            size: 18,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Estado General ---
            _buildStatusCard(isLinked, lastSyncLabel, readCount),

            const SizedBox(height: 28),

            // --- Permisos ---
            const Text(
              'Permisos Otorgados',
              style: TextStyle(
                fontFamily: 'Satoshi',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Datos que AsthmaApp puede leer de tu bóveda de salud (solo lectura).',
              style: TextStyle(
                fontFamily: 'GeneralSans',
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 16),

            _buildPermissionRow(
              icon: Icons.favorite_outline,
              label: 'Frecuencia Cardíaca',
              description: 'Latidos por minuto durante el día',
              granted: isLinked,
              color: Colors.red,
            ),
            _buildPermissionRow(
              icon: Icons.water_drop_outlined,
              label: 'Oxígeno en Sangre (SpO2)',
              description: 'Porcentaje de oxigenación en tiempo real',
              granted: isLinked,
              color: Colors.blue,
            ),
            _buildPermissionRow(
              icon: Icons.directions_walk_outlined,
              label: 'Pasos y Actividad',
              description: 'Conteo de pasos diarios y distancia',
              granted: isLinked,
              color: Colors.green,
            ),
            _buildPermissionRow(
              icon: Icons.bedtime_outlined,
              label: 'Horas de Sueño',
              description: 'Sesiones y calidad del sueño nocturno',
              granted: isLinked,
              color: Colors.indigo,
            ),
            _buildPermissionRow(
              icon: Icons.air,
              label: 'Frecuencia Respiratoria',
              description: 'Respiraciones por minuto',
              granted: isLinked,
              color: Colors.teal,
            ),

            const SizedBox(height: 28),

            // --- Estadísticas de Hoy ---
            if (isLinked) ...[
              const Text(
                'Estadísticas de Hoy',
                style: TextStyle(
                  fontFamily: 'Satoshi',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              _buildStatsGrid(watchState),
              const SizedBox(height: 28),
            ],

            // --- Botón de Ajustes ---
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => openAppSettings(),
                icon: const Icon(Icons.settings_outlined, size: 18),
                label: const Text('Administrar en Ajustes de Android'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  foregroundColor: const Color(0xFF023E8A),
                  side: const BorderSide(color: Color(0xFF023E8A)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(
                    fontFamily: 'Satoshi',
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // --- Botón Desvincular ---
            if (isLinked)
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => _showUnlinkDialog(context, ref),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    foregroundColor: Colors.red.shade600,
                  ),
                  child: const Text(
                    'Desvincular Health Connect',
                    style: TextStyle(
                      fontFamily: 'Satoshi',
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 32),

            // --- Descripción técnica ---
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.blue.shade600,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'AsthmaApp no se conecta directamente a tu reloj. Todos los datos se leen de la Bóveda de Salud de Android (Health Connect), que actúa como intermediario seguro y privado.',
                      style: TextStyle(
                        fontFamily: 'GeneralSans',
                        fontSize: 12,
                        color: Colors.blue.shade800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(bool isLinked, String lastSyncLabel, int readCount) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isLinked
              ? [const Color(0xFF023E8A), const Color(0xFF0077B6)]
              : [Colors.grey.shade600, Colors.grey.shade500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isLinked ? Icons.health_and_safety : Icons.sync_disabled,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isLinked ? 'Conectado' : 'No Conectado',
                  style: const TextStyle(
                    fontFamily: 'Satoshi',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isLinked
                      ? 'Última sync: $lastSyncLabel'
                      : 'Vincula un reloj para comenzar',
                  style: TextStyle(
                    fontFamily: 'GeneralSans',
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
                if (isLinked) ...[
                  const SizedBox(height: 8),
                  Text(
                    '$readCount / 5 métricas sincronizadas hoy',
                    style: TextStyle(
                      fontFamily: 'GeneralSans',
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionRow({
    required IconData icon,
    required String label,
    required String description,
    required bool granted,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: granted
                  ? color.withValues(alpha: 0.1)
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: granted ? color : Colors.grey.shade400,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Satoshi',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: granted ? Colors.black87 : Colors.grey.shade500,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontFamily: 'GeneralSans',
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            granted ? Icons.check_circle : Icons.radio_button_unchecked,
            color: granted ? Colors.green : Colors.grey.shade400,
            size: 22,
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(SmartwatchState state) {
    final stats = [
      if (state.steps != null)
        _StatItem(
          label: 'Pasos',
          value: '${state.steps}',
          icon: Icons.directions_walk,
          color: Colors.green,
        ),
      if (state.heartRate != null)
        _StatItem(
          label: 'BPM',
          value: '${state.heartRate}',
          icon: Icons.favorite,
          color: Colors.red,
        ),
      if (state.spO2 != null)
        _StatItem(
          label: 'SpO2',
          value: '${state.spO2}%',
          icon: Icons.water_drop,
          color: Colors.blue,
        ),
      if (state.sleepHours != null)
        _StatItem(
          label: 'Sueño',
          value: '${state.sleepHours!.toStringAsFixed(1)}h',
          icon: Icons.bedtime,
          color: Colors.indigo,
        ),
      if (state.respiratoryRate != null)
        _StatItem(
          label: 'Resp/min',
          value: '${state.respiratoryRate}',
          icon: Icons.air,
          color: Colors.teal,
        ),
    ];

    if (stats.isEmpty) {
      return Text(
        'Sin datos disponibles para hoy. Intenta caminar unos pasos o medir tu pulso.',
        style: TextStyle(
          fontFamily: 'GeneralSans',
          fontSize: 13,
          color: Colors.grey.shade600,
        ),
      );
    }

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: stats.map((s) => _buildStatCard(s)).toList(),
    );
  }

  Widget _buildStatCard(_StatItem item) {
    return Container(
      width: 100,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: item.color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: item.color.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(item.icon, color: item.color, size: 18),
          const SizedBox(height: 8),
          Text(
            item.value,
            style: TextStyle(
              fontFamily: 'Satoshi',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          Text(
            item.label,
            style: TextStyle(
              fontFamily: 'GeneralSans',
              fontSize: 11,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  void _showUnlinkDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Desvincular Health Connect',
          style: TextStyle(fontFamily: 'Satoshi', fontWeight: FontWeight.w600),
        ),
        content: const Text(
          'Esto revocará el acceso de la app a la bóveda de Android. Tendrás que volver a vincular para ver tus vitales.',
          style: TextStyle(fontFamily: 'GeneralSans', fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'Cancelar',
              style: TextStyle(fontFamily: 'Satoshi'),
            ),
          ),
          TextButton(
            onPressed: () {
              ref.read(smartwatchProvider.notifier).unlinkSmartwatch();
              Navigator.of(ctx).pop();
              if (context.mounted) Navigator.of(context).pop();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text(
              'Desvincular',
              style: TextStyle(
                fontFamily: 'Satoshi',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatRelativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'Hace unos segundos';
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Hace ${diff.inHours} h';
    return 'Hace ${diff.inDays} días';
  }
}

class _StatItem {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
}
