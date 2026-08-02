import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import '../providers/permissions_provider.dart';

class PermissionsScreen extends ConsumerWidget {
  const PermissionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permissions = ref.watch(permissionsProvider);
    final notifier = ref.read(permissionsProvider.notifier);

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
          'Privacidad y Permisos',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.w600,
            fontFamily: 'Satoshi',
          ),
        ),
        centerTitle: true,
      ),
      body: permissions.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Transparencia total',
                    style: TextStyle(
                      fontFamily: 'Satoshi',
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Esta aplicación está diseñada pensando en tu privacidad. Revísanos: aquí te mostramos exactamente qué accesos tiene AsthmaApp a los sensores de tu teléfono.',
                    style: TextStyle(
                      fontFamily: 'GeneralSans',
                      fontSize: 15,
                      color: Colors.black54,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),
                  _PermissionTile(
                    title: 'Notificaciones',
                    description:
                        'Vital para recibir alertas de la IA si tus indicadores de asma entran en Zona Roja.',
                    icon: Icons.notifications_active_outlined,
                    status: permissions.notificationStatus,
                    onRequest: notifier.requestNotificationPermission,
                  ),
                  const SizedBox(height: 16),
                  _PermissionTile(
                    title: 'Ubicación Geográfica',
                    description:
                        'Se requiere para calcular el polen, la humedad y la calidad del aire de tu zona en el Radar.',
                    icon: Icons.location_on_outlined,
                    status: permissions.locationStatus,
                    onRequest: notifier.requestLocationPermission,
                  ),
                  const SizedBox(height: 16),
                  _PermissionTile(
                    title: 'Bluetooth y Dispositivos',
                    description:
                        'Necesario para encontrar e importar los datos de tu Smart Espirómetro médico.',
                    icon: Icons.bluetooth_connected_outlined,
                    status: permissions.bluetoothStatus,
                    onRequest: notifier.requestBluetoothPermission,
                  ),
                  const SizedBox(height: 16),
                  _PermissionTile(
                    title: 'Salud y Actividad',
                    description:
                        'Requerido para leer tu frecuencia cardíaca y SpO2 desde Google Fit / Apple Health de fondo.',
                    icon: Icons.favorite_border_rounded,
                    status: permissions.healthStatus,
                    onRequest: notifier.requestHealthPermission,
                  ),
                  const SizedBox(
                    height: 80,
                  ), 
                ],
              ),
            ),
    );
  }
}

class _PermissionTile extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final PermissionStatus status;
  final VoidCallback onRequest;

  const _PermissionTile({
    required this.title,
    required this.description,
    required this.icon,
    required this.status,
    required this.onRequest,
  });

  @override
  Widget build(BuildContext context) {
    final bool isGranted =
        status == PermissionStatus.granted ||
        status == PermissionStatus.limited;
    final bool isPermanentlyDenied =
        status == PermissionStatus.permanentlyDenied;

    
    final Color mainColor = isGranted
        ? Colors.green.shade600
        : Colors.grey.shade400;
    final Color bgColor = isGranted
        ? Colors.green.shade50
        : Colors.grey.shade50;
    final String statusText = isGranted ? 'HABILITADO' : 'DENEGADO';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isGranted ? Colors.green.shade200 : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isGranted ? Colors.green.shade100 : Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: mainColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: 'Satoshi',
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isGranted
                            ? Colors.green.shade600
                            : Colors.grey.shade600,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        statusText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (!isGranted)
                TextButton(
                  onPressed: () {
                    if (isPermanentlyDenied) {
                      openAppSettings();
                    } else {
                      onRequest();
                    }
                  },
                  child: Text(
                    isPermanentlyDenied ? 'Ajustes' : 'Activar',
                    style: TextStyle(
                      fontFamily: 'Satoshi',
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF023E8A),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: TextStyle(
              fontFamily: 'GeneralSans',
              fontSize: 14,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }
}
