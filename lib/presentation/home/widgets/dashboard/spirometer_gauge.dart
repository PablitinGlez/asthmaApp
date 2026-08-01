import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/prediction_provider.dart';

class MainGaugeSection extends ConsumerWidget {
  const MainGaugeSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prediction = ref.watch(predictionProvider);
    
    final double riskScore = prediction.probability * 100;

    return Stack(
      alignment: Alignment.center,
      children: [
        _RiskGauge(
          score: riskScore,
          isLoading: prediction.isLoading,
          statusTextOverride: prediction.riskLevel == 'red' 
              ? "Riesgo de Crisis" 
              : (prediction.riskLevel == 'yellow' ? "Precaución" : "Estable"),
          simulationData: prediction.simulationData,
          isSimulationActive: prediction.isSimulationActive,
        ),
        Positioned(
          top: 0,
          right: 20,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: prediction.isSimulationActive 
                  ? Colors.orange.withOpacity(0.1)
                  : const Color(0xFF023E8A).withOpacity(0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: prediction.isSimulationActive 
                    ? Colors.orange.withOpacity(0.3)
                    : const Color(0xFF023E8A).withOpacity(0.1),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  prediction.isSimulationActive ? Icons.science : Icons.auto_awesome,
                  size: 14,
                  color: prediction.isSimulationActive ? Colors.orange : const Color(0xFF023E8A),
                ),
                const SizedBox(width: 6),
                Text(
                  prediction.isSimulationActive ? 'Simulación IA Activa' : 'Análisis por IA',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: prediction.isSimulationActive ? Colors.orange.shade800 : const Color(0xFF023E8A),
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _RiskGauge extends StatelessWidget {
  final double score;
  final bool isLoading;
  final String? statusTextOverride;
  final Map<String, dynamic>? simulationData;
  final bool isSimulationActive;

  const _RiskGauge({
    required this.score,
    this.isLoading = false,
    this.statusTextOverride,
    this.simulationData,
    this.isSimulationActive = false,
  });

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    String statusText = statusTextOverride ?? "";

    if (score <= 30) {
      statusColor = const Color(0xFF4CAF50);
      if (statusText.isEmpty) statusText = "Estable";
    } else if (score <= 70) {
      statusColor = const Color(0xFFFFC107);
      if (statusText.isEmpty) statusText = "Precaución";
    } else {
      statusColor = const Color(0xFFF44336);
      if (statusText.isEmpty) statusText = "Riesgo de Crisis";
    }

    final bool isEmpty = score == 0 && !isLoading && statusText.isEmpty;
    
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: score),
      duration: const Duration(milliseconds: 1500),
      curve: Curves.easeOutCubic,
      builder: (context, animatedScore, child) {
        return Column(
          children: [
            SizedBox(
              width: 280,
              height: 140,
              child: CustomPaint(
                painter: _GaugePainter(
                  score: animatedScore,
                  showNeedle: !isEmpty,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Column(
              children: [
                Text(
                  isEmpty ? "Calculando..." : "${animatedScore.toInt()}%",
                  style: TextStyle(
                    fontFamily: 'Satoshi',
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                    color: statusColor,
                    height: 1.0,
                  ),
                ),
                Text(
                  statusText,
                  style: TextStyle(
                    fontFamily: 'GeneralSans',
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            if (isSimulationActive && simulationData != null) ...[
              const SizedBox(height: 18),
              Container(
                width: 280,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.orange.withOpacity(0.15)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.bar_chart_outlined, size: 12, color: Colors.orange.shade800),
                        const SizedBox(width: 4),
                        Text(
                          "Entradas de simulación:",
                          style: TextStyle(
                            fontFamily: 'GeneralSans',
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.orange.shade800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildMetricMiniItem(
                          "PEF", 
                          "${(simulationData!['pef_percent'] ?? simulationData!['pef_porcentaje'] ?? 100.0).toInt()}%"
                        ),
                        _buildMetricMiniItem(
                          "SpO2", 
                          "${simulationData!['spo2']?.toInt()}%"
                        ),
                        _buildMetricMiniItem(
                          "BPM", 
                          "${simulationData!['bpm']?.toInt()}"
                        ),
                        _buildMetricMiniItem(
                          "AQI", 
                          "${simulationData!['aqi']?.toInt()}"
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildMetricMiniItem(String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Satoshi',
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'GeneralSans',
            fontSize: 9,
            color: Colors.grey.shade500,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double score;
  final bool showNeedle;

  _GaugePainter({required this.score, this.showNeedle = true});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height);
    final radius = size.width / 2;
    final strokeWidth = 25.0;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    const startAngle = math.pi;
    const sweepAngle = math.pi;

    paint.color = Colors.grey.shade200;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
      startAngle,
      sweepAngle,
      false,
      paint,
    );

    if (!showNeedle) {
      paint.color = Colors.grey.shade200;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
      paint.shader = null;

      final needleAngle = math.pi;
      final needleLength = radius - 10;
      final needlePaint = Paint()
        ..color = Colors.grey.shade300
        ..style = PaintingStyle.fill
        ..strokeWidth = 4;

      final needleEnd = Offset(
        center.dx + needleLength * math.cos(needleAngle),
        center.dy + needleLength * math.sin(needleAngle),
      );

      canvas.drawLine(center, needleEnd, needlePaint);
      canvas.drawCircle(center, 8, needlePaint..color = Colors.grey.shade300);
      canvas.drawCircle(center, 4, Paint()..color = Colors.white);
      return;
    }

    const gradient = LinearGradient(
      colors: [Color(0xFF4CAF50), Color(0xFFFFC107), Color(0xFFF44336)],
      stops: [0.0, 0.5, 1.0],
    );

    paint.shader = gradient.createShader(
      Rect.fromCircle(center: center, radius: radius),
    );

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
      startAngle,
      sweepAngle,
      false,
      paint,
    );
    paint.shader = null;

    if (showNeedle) {
      final needleAngle = math.pi + (score / 100) * math.pi;
      final needleLength = radius - 10;
      final needlePaint = Paint()
        ..color = Colors.black87
        ..style = PaintingStyle.fill
        ..strokeWidth = 4;

      final needleEnd = Offset(
        center.dx + needleLength * math.cos(needleAngle),
        center.dy + needleLength * math.sin(needleAngle),
      );

      canvas.drawLine(center, needleEnd, needlePaint);
      canvas.drawCircle(center, 8, needlePaint..color = Colors.black87);
      canvas.drawCircle(center, 4, Paint()..color = Colors.white);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
