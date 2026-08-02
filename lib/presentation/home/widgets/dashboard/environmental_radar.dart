import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/environmental_provider.dart';

class EnvironmentalRadar extends ConsumerWidget {
  const EnvironmentalRadar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final envState = ref.watch(environmentalProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Radar Ambiental',
                  style: TextStyle(
                    fontFamily: 'Satoshi',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade800,
                  ),
                ),
                if (envState.locationName != null)
                  Text(
                    envState.locationName!,
                    style: TextStyle(
                      fontFamily: 'GeneralSans',
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Colors.blue.shade700,
                    ),
                  ),
              ],
            ),
            if (envState.isLoading)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.grey.shade100),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: _buildRadarContent(context, ref, envState),
        ),
      ],
    );
  }

  Widget _buildRadarContent(
    BuildContext context,
    WidgetRef ref,
    EnvironmentalState envState,
  ) {
    if (envState.status == EnvironmentalStatus.missingPermission) {
      return _buildPermissionPrompt(
        title: 'Radar Desactivado',
        subtitle: 'Activa tu ubicación para ver el clima y predecir riesgos.',
        buttonText: 'Activar Ubicación',
        onPressed: () =>
            ref.read(environmentalProvider.notifier).requestPermission(),
        icon: Icons.location_off_outlined,
      );
    }

    if (envState.status == EnvironmentalStatus.serviceDisabled) {
      return _buildPermissionPrompt(
        title: 'Sensor Apagado',
        subtitle:
            'Tu antena GPS está apagada. Enciéndela para ver el aire local.',
        buttonText: 'Encender GPS',
        onPressed: () =>
            ref.read(environmentalProvider.notifier).openLocationSettings(),
        icon: Icons.gps_off_rounded,
      );
    }

    if (envState.status == EnvironmentalStatus.deniedForever) {
      return _buildPermissionPrompt(
        title: 'Acceso Denegado',
        subtitle:
            'Habilita los permisos de ubicación en los ajustes para usar el Radar.',
        buttonText: 'Abrir Ajustes',
        onPressed: () => ref
            .read(environmentalProvider.notifier)
            .openAppPermissionSettings(),
        icon: Icons.settings_applications_outlined,
      );
    }

    if (envState.errorMessage != null) {
      return Column(
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Error: ${envState.errorMessage}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'GeneralSans',
                  fontSize: 12,
                  color: Colors.red.shade400,
                ),
              ),
            ),
          ),
          TextButton.icon(
            onPressed: () => ref.read(environmentalProvider.notifier).checkCurrentStatus(),
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Reintentar'),
          ),
        ],
      );
    }

    
    return Row(
      children: [
        Expanded(
          child: _EnvironmentalSegment(
            label: 'Aire (ICA)',
            value: envState.aqi?.toString() ?? '',
            status: envState.airStatus ?? '',
            icon: Icons.air,
            color: _getAirColor(envState.airStatus),
          ),
        ),
        const _VerticalDivider(),
        Expanded(
          child: _EnvironmentalSegment(
            label: 'Polen',
            value: envState.pollenStatus ?? '',
            status: envState.pollenStatus ?? '',
            icon: Icons.park_outlined,
            color: _getPollenColor(envState.pollenStatus),
          ),
        ),
        const _VerticalDivider(),
        Expanded(
          child: _EnvironmentalSegment(
            label: 'Humedad',
            value: envState.humidity != null ? '${envState.humidity}%' : '',
            status: envState.humidityStatus ?? '',
            icon: Icons.water_drop_outlined,
            color: _getHumidityColor(envState.humidityStatus),
          ),
        ),
      ],
    );
  }

  Widget _buildPermissionPrompt({
    required String title,
    required String subtitle,
    required String buttonText,
    required VoidCallback onPressed,
    required IconData icon,
  }) {
    return Column(
      children: [
        Icon(icon, size: 40, color: Colors.blue.shade200),
        const SizedBox(height: 12),
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Satoshi',
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'GeneralSans',
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0D47A1),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: Text(
            buttonText,
            style: const TextStyle(
              fontFamily: 'Satoshi',
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Color _getAirColor(String? status) {
    if (status == 'Peligroso') return const Color(0xFFF44336);
    if (status == 'Sensible') return const Color(0xFFFF9800);
    if (status == 'Moderado') return const Color(0xFFFFC107);
    return const Color(0xFF4CAF50); 
  }

  Color _getPollenColor(String? status) {
    if (status == 'Alto' || status == 'Muy Alto' || status == 'Peligroso')
      return const Color(0xFFF44336);
    if (status == 'Medio' || status == 'Precaución')
      return const Color(0xFFFFC107);
    return const Color(0xFF8BC34A); 
  }

  Color _getHumidityColor(String? status) {
    if (status == 'Seco') return const Color(0xFFFF9800);
    if (status == 'Alta' || status == 'Peligroso')
      return const Color(0xFFF44336);
    return const Color(0xFF03A9F4); 
  }
}

class _EnvironmentalSegment extends StatelessWidget {
  final String label;
  final String value;
  final String status;
  final IconData icon;
  final Color color;

  const _EnvironmentalSegment({
    required this.label,
    required this.value,
    required this.status,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(height: 10),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Satoshi',
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Colors.black87,
            height: 1.0,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'GeneralSans',
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade500,
          ),
        ),
      ],
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  const _VerticalDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      width: 1,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      color: Colors.grey.shade100,
    );
  }
}

extension ColorDarken on Color {
  Color darken([double amount = .1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }
}
