import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/smartwatch_provider.dart';

class WatchPerformanceVitals extends ConsumerWidget {
  const WatchPerformanceVitals({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final watchState = ref.watch(smartwatchProvider);

    
    if (!watchState.isLinked) return const SizedBox.shrink();

    final String stepsText = watchState.steps != null
        ? NumberFormat('#,###').format(watchState.steps)
        : '--';

    final String respRateText = watchState.respiratoryRate != null
        ? '${watchState.respiratoryRate}'
        : '--';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Rendimiento y Reposo',
          style: TextStyle(
            fontFamily: 'Satoshi',
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _PerformanceCard(
                label: 'Actividad',
                value: stepsText,
                subValue: 'Pasos',
                color: const Color(0xFFFB8500),
                icon: Icons.directions_walk_rounded,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _PerformanceCard(
                label: 'Frec. Resp.',
                value: respRateText,
                subValue: 'rpm',
                color: const Color(0xFF219EBC),
                icon: Icons.air_rounded,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PerformanceCard extends StatelessWidget {
  final String label;
  final String value;
  final String subValue;
  final Color color;
  final IconData icon;

  const _PerformanceCard({
    required this.label,
    required this.value,
    required this.subValue,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [Icon(icon, color: color.withOpacity(0.6), size: 16)],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Satoshi',
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subValue,
            style: TextStyle(
              fontFamily: 'GeneralSans',
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color.withOpacity(0.7),
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
      ),
    );
  }
}
