import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/smartwatch_provider.dart';
import '../../providers/background_sync_provider.dart';
import 'smartwatch_linking_banner.dart';

class WatchCoreVitals extends ConsumerWidget {
  const WatchCoreVitals({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Escuchar errores del Smartwatch
    ref.listen<SmartwatchState>(smartwatchProvider, (previous, next) {
      if (next.errorMessage != null &&
          next.errorMessage != previous?.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    });

    final watchState = ref.watch(smartwatchProvider);
    final syncState = ref.watch(backgroundSyncProvider);
    final String lastSyncTimeFormatted = syncState.lastSyncTime != null
        ? '${syncState.lastSyncTime!.hour.toString().padLeft(2, '0')}:${syncState.lastSyncTime!.minute.toString().padLeft(2, '0')}'
        : 'Activo';

    final String spO2Text = watchState.spO2 != null
        ? '${watchState.spO2}%'
        : '--%';
    final String hrText = watchState.heartRate != null
        ? '${watchState.heartRate}'
        : '--';

    final String sleepText = watchState.sleepHours != null
        ? '${watchState.sleepHours!.floor()}h ${((watchState.sleepHours! % 1) * 60).round()}m'
        : '--';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Vitales del Reloj',
              style: TextStyle(
                fontFamily: 'Satoshi',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF023E8A).withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFF023E8A).withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    syncState.isSyncing
                        ? Icons.sync_rounded
                        : Icons.autorenew_rounded,
                    size: 14,
                    color: const Color(0xFF023E8A),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Auto: $lastSyncTimeFormatted',
                    style: const TextStyle(
                      fontFamily: 'Satoshi',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF023E8A),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (!watchState.isLinked)
          SmartwatchLinkingBanner(watchState: watchState, ref: ref)
        else
          Row(
            children: [
              Expanded(
                child: VitalCard(
                  label: 'Saturación',
                  value: spO2Text,
                  subValue: 'SpO2',
                  color: const Color(0xFFD90429),
                  trendData: const [0.8, 0.9, 0.85, 0.95, 0.9, 0.98, 0.97],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: VitalCard(
                  label: 'Ritmo Card.',
                  value: hrText,
                  subValue: 'bpm',
                  color: const Color(0xFFFF5D8F),
                  trendData: const [0.6, 0.7, 0.65, 0.8, 0.75, 0.7, 0.72],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: VitalCard(
                  label: 'Sueño',
                  value: sleepText,
                  subValue: 'Hoy',
                  color: const Color(0xFF7209B7),
                  trendData: const [0.4, 0.5, 0.6, 0.7, 0.75, 0.8, 0.85],
                ),
              ),
            ],
          ),
      ],
    );
  }
}

class VitalCard extends StatelessWidget {
  final String label;
  final String value;
  final String subValue;
  final Color color;
  final List<double> trendData;

  const VitalCard({
    super.key,
    required this.label,
    required this.value,
    required this.subValue,
    required this.color,
    required this.trendData,
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
          // MINI SPARKLINE (En lugar del icono)
          SizedBox(
            height: 24,
            width: double.infinity,
            child: CustomPaint(
              painter: _MiniSparklinePainter(data: trendData, color: color),
            ),
          ),
          const SizedBox(height: 12),
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

class _MiniSparklinePainter extends CustomPainter {
  final List<double> data;
  final Color color;

  _MiniSparklinePainter({required this.data, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    final dx = size.width / (data.length - 1);

    for (var i = 0; i < data.length; i++) {
      final x = i * dx;
      final y = size.height - (data[i] * size.height);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);

    final fillPath = Path.from(path);
    fillPath.lineTo(size.width, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();

    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [color.withOpacity(0.2), color.withOpacity(0.0)],
    );

    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = gradient.createShader(Offset.zero & size)
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
