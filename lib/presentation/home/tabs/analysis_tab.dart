import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import '../../home/providers/weekly_trend_provider.dart';
import '../../../domain/models/weekly_trend.dart';

class AnalysisTab extends ConsumerWidget {
  const AnalysisTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trendState = ref.watch(weeklyTrendProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.only(
        left: 24.0,
        right: 24.0,
        bottom: 100.0,
        top: kToolbarHeight + 48.0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StatsHeader(trendState: trendState),
          const SizedBox(height: 32),
          const _AIInsightsCard(),
          const SizedBox(height: 32),
          _WeeklyComparisonSection(trendState: trendState),
          const SizedBox(height: 32),
          _AdherenceCalendar(trendState: trendState),
        ],
      ),
    );
  }
}

// Header con estadísticas reales
class _StatsHeader extends StatelessWidget {
  final WeeklyTrendState trendState;
  const _StatsHeader({required this.trendState});

  @override
  Widget build(BuildContext context) {
    final data = trendState.data;
    final avgPef = data?.avgPef;
    final maxPef = data?.maxPef;
    final minPef = data?.minPef;

    // Calcular puntuación basada en el PEF promedio (scale 0-100)
    double score = 0.0;
    String scoreText = '--';
    String scoreLabel = 'Sin datos aún';

    if (avgPef != null && avgPef > 0) {
      // PEF saludable para adulto ~400-600 L/min → 100 puntos
      score = (avgPef / 500.0).clamp(0.0, 1.0);
      scoreText = (score * 100).round().toString();
      if (score >= 0.8) {
        scoreLabel = '¡Excelente control esta semana!';
      } else if (score >= 0.6) {
        scoreLabel = 'Control aceptable. Sigue adelante.';
      } else {
        scoreLabel = 'Tu control necesita atención.';
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SizedBox(
              width: 100,
              height: 100,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size(100, 100),
                    painter: _CircularProgressPainter(
                      progress: score,
                      color: const Color(0xFF023E8A),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      trendState.isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              scoreText,
                              style: const TextStyle(
                                fontFamily: 'Satoshi',
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF023E8A),
                              ),
                            ),
                      Text(
                        'Puntos',
                        style: TextStyle(
                          fontFamily: 'GeneralSans',
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Control Semanal',
                    style: TextStyle(
                      fontFamily: 'Satoshi',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    scoreLabel,
                    style: TextStyle(
                      fontFamily: 'GeneralSans',
                      fontSize: 13,
                      color: Colors.grey.shade600,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (data != null && !trendState.isLoading) ...[
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatChip(
                label: 'Máx.',
                value: '${maxPef ?? '--'} L/min',
                color: const Color(0xFF48CAE4),
              ),
              _StatChip(
                label: 'Prom.',
                value: '${avgPef ?? '--'} L/min',
                color: const Color(0xFF023E8A),
              ),
              _StatChip(
                label: 'Mín.',
                value: '${minPef ?? '--'} L/min',
                color: Colors.orange,
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Satoshi',
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'GeneralSans',
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
}

// Tarjeta de insights (estática por ahora)
class _AIInsightsCard extends StatelessWidget {
  const _AIInsightsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF023E8A), Color(0xFF0077B6)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF023E8A).withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.bar_chart_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Resumen de tu semana',
                style: TextStyle(
                  fontFamily: 'Satoshi',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Aquí verás un resumen automático de tu rendimiento pulmonar a medida que acumules más mediciones. ¡Sigue midiendo cada día para obtener mejores análisis!',
            style: TextStyle(
              fontFamily: 'GeneralSans',
              fontSize: 13,
              color: Colors.white,
              height: 1.6,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

// Comparativa semanal con datos reales
class _WeeklyComparisonSection extends StatelessWidget {
  final WeeklyTrendState trendState;
  const _WeeklyComparisonSection({required this.trendState});

  @override
  Widget build(BuildContext context) {
    final data = trendState.data;

    // Calcular promedios de esta semana y la semana pasada
    double thisWeekAvg = 0;
    double lastWeekAvg = 0;
    int thisWeekCount = 0;
    int lastWeekCount = 0;

    if (data != null) {
      final now = DateTime.now();
      final weekAgo = now.subtract(const Duration(days: 7));
      final twoWeeksAgo = now.subtract(const Duration(days: 14));

      for (final point in data.dailyData) {
        if (point.date.isAfter(weekAgo)) {
          thisWeekAvg += point.value;
          thisWeekCount++;
        } else if (point.date.isAfter(twoWeeksAgo)) {
          lastWeekAvg += point.value;
          lastWeekCount++;
        }
      }

      if (thisWeekCount > 0) thisWeekAvg /= thisWeekCount;
      if (lastWeekCount > 0) lastWeekAvg /= lastWeekCount;
    }

    final maxVal = math.max(thisWeekAvg, lastWeekAvg);
    final hasData = thisWeekAvg > 0 || lastWeekAvg > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Comparativa Semanal',
              style: TextStyle(
                fontFamily: 'Satoshi',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            Text(
              'PEF (L/min)',
              style: TextStyle(
                fontFamily: 'GeneralSans',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade400,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        if (trendState.isLoading)
          const Center(child: CircularProgressIndicator())
        else if (!hasData)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text(
                'Aún no hay mediciones suficientes.\nMide al menos 2 días para ver la comparativa.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'GeneralSans',
                  color: Colors.grey.shade400,
                  fontSize: 13,
                ),
              ),
            ),
          )
        else
          SizedBox(
            height: 140,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _ComparisonBar(
                  label: 'Sem. Pasada',
                  value: lastWeekAvg,
                  maxValue: maxVal > 0 ? maxVal : 500,
                  color: Colors.grey.shade200,
                ),
                _ComparisonBar(
                  label: 'Esta Semana',
                  value: thisWeekAvg,
                  maxValue: maxVal > 0 ? maxVal : 500,
                  color: const Color(0xFF00B4D8),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _ComparisonBar extends StatelessWidget {
  final String label;
  final double value;
  final double maxValue;
  final Color color;

  const _ComparisonBar({
    required this.label,
    required this.value,
    required this.maxValue,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final heightFactor = maxValue > 0
        ? (value / maxValue).clamp(0.05, 1.0)
        : 0.05;

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          value > 0 ? value.toInt().toString() : '--',
          style: const TextStyle(
            fontFamily: 'Satoshi',
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 48,
          height: heightFactor * 80,
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'GeneralSans',
            fontSize: 10,
            color: Colors.grey.shade500,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// Calendario de adherencia con datos reales
class _AdherenceCalendar extends StatelessWidget {
  final WeeklyTrendState trendState;
  const _AdherenceCalendar({required this.trendState});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final monthName = DateFormat('MMMM', 'es_ES').format(now);
    final year = now.year;

    // Construir set de días donde hubo medición este mes
    final Set<int> measuredDays = {};
    if (trendState.data != null) {
      for (final point in trendState.data!.dailyData) {
        if (point.date.month == now.month && point.date.year == now.year) {
          measuredDays.add(point.date.day);
        }
      }
    }

    // Días en el mes
    final daysInMonth = DateUtils.getDaysInMonth(now.year, now.month);
    // Primer día de la semana del mes (1=Lun...7=Dom en Dart)
    final firstWeekday = DateTime(now.year, now.month, 1).weekday;
    // Número de celdas vacías al inicio
    final leadingBlanks = firstWeekday - 1;
    final totalCells = leadingBlanks + daysInMonth;

    final adherencePct = daysInMonth > 0
        ? ((measuredDays.length / now.day) * 100).round()
        : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Constancia (Adherencia)',
              style: TextStyle(
                fontFamily: 'Satoshi',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${monthName.toUpperCase()} $year',
                  style: const TextStyle(
                    fontFamily: 'Satoshi',
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF023E8A),
                  ),
                ),
                Text(
                  '$adherencePct% del mes',
                  style: TextStyle(
                    fontFamily: 'GeneralSans',
                    fontSize: 10,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: Column(
            children: [
              // Cabecera días de la semana
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: ['L', 'M', 'M', 'J', 'V', 'S', 'D'].map((d) {
                  return SizedBox(
                    width: 30,
                    child: Center(
                      child: Text(
                        d,
                        style: TextStyle(
                          fontFamily: 'GeneralSans',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade400,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 4),
              GridView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                ),
                itemCount: totalCells,
                itemBuilder: (context, index) {
                  if (index < leadingBlanks) {
                    return const SizedBox.shrink();
                  }

                  final dayNum = index - leadingBlanks + 1;
                  final isToday = dayNum == now.day;
                  final isFuture = dayNum > now.day;
                  final hasMeasurement = measuredDays.contains(dayNum);

                  Color bgColor;
                  Color borderColor;
                  Color textColor;

                  if (isFuture) {
                    bgColor = Colors.grey.shade50;
                    borderColor = Colors.transparent;
                    textColor = Colors.grey.shade200;
                  } else if (hasMeasurement) {
                    bgColor = const Color(0xFF48CAE4).withOpacity(0.2);
                    borderColor = const Color(0xFF48CAE4).withOpacity(0.5);
                    textColor = const Color(0xFF0077B6);
                  } else {
                    bgColor = Colors.grey.shade50;
                    borderColor = Colors.grey.shade100;
                    textColor = Colors.grey.shade300;
                  }

                  return Container(
                    decoration: BoxDecoration(
                      color: isToday ? const Color(0xFF023E8A) : bgColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isToday ? Colors.transparent : borderColor,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '$dayNum',
                        style: TextStyle(
                          fontFamily: 'Satoshi',
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: isToday ? Colors.white : textColor,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Leyenda
        Row(
          children: [
            _Legend(
              color: const Color(0xFF48CAE4).withOpacity(0.5),
              label: 'Con medición',
            ),
            const SizedBox(width: 16),
            _Legend(color: const Color(0xFF023E8A), label: 'Hoy'),
            const SizedBox(width: 16),
            _Legend(color: Colors.grey.shade200, label: 'Sin medición'),
          ],
        ),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  const _Legend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'GeneralSans',
            fontSize: 10,
            color: Colors.grey.shade500,
          ),
        ),
      ],
    );
  }
}

// Pintor del círculo de progreso
class _CircularProgressPainter extends CustomPainter {
  final double progress;
  final Color color;

  _CircularProgressPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const strokeWidth = 10.0;

    final trackPaint = Paint()
      ..color = Colors.grey.shade100
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius - strokeWidth / 2, trackPaint);

    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
