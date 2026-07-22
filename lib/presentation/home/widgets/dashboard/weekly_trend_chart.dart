import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/weekly_trend_provider.dart';

class WeeklyTrendChart extends StatelessWidget {
  final WeeklyTrendState state;

  const WeeklyTrendChart({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    if (state.isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    final dataPoints = state.data?.dailyData ?? [];
    final bool isEmpty = dataPoints.isEmpty;

    final int maxVal = state.data?.maxPef ?? 0;
    final int minVal = state.data?.minPef ?? 0;
    final int avgVal = state.data?.avgPef ?? 0;

    double topY = ((maxVal / 100).ceil() * 100).toDouble() + 100;
    if (topY < 500) topY = 500.0;
    final double bottomY = 0.0;

    final now = DateTime.now();
    final startOfWeek = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - 1));

    final dayNames = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
    final Map<int, String> xLabels = {};
    for (int i = 0; i <= 6; i++) {
      xLabels[i] = dayNames[i];
    }

    final List<FlSpot> spots = [];
    if (!isEmpty) {
      final Map<int, List<double>> groupedVals = {};

      for (var point in dataPoints) {
        final localDate = point.date.toLocal();

        final ptDate = DateTime(localDate.year, localDate.month, localDate.day);
        final diff = ptDate.difference(startOfWeek).inDays;

        if (diff >= 0 && diff <= 6) {
          groupedVals.putIfAbsent(diff, () => []).add(point.value.toDouble());
        }
      }

      groupedVals.forEach((dayIndex, values) {
        spots.add(FlSpot(dayIndex.toDouble(), values.last));
      });

      spots.sort((a, b) => a.x.compareTo(b.x));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Tendencia Semanal',
              style: TextStyle(
                fontFamily: 'Satoshi',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade800,
              ),
            ),
            Text(
              'Esta semana',
              style: TextStyle(
                fontFamily: 'GeneralSans',
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          height: 180,
          width: double.infinity,
          padding: const EdgeInsets.only(
            top: 16,
            right: 16,
            left: 0,
            bottom: 0,
          ),
          decoration: isEmpty
              ? BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade100),
                )
              : null,
          child: isEmpty
              ? Center(
                  child: Text(
                    'No hay mediciones esta semana',
                    style: TextStyle(
                      fontFamily: 'GeneralSans',
                      fontSize: 13,
                      color: Colors.grey.shade400,
                    ),
                  ),
                )
              : LineChart(
                  key: ValueKey(state.data.hashCode),
                  LineChartData(
                    minX: 0,
                    maxX: 6,
                    minY: bottomY,
                    maxY: topY,
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: 100,
                      getDrawingHorizontalLine: (value) {
                        return FlLine(
                          color: Colors.grey.shade200,
                          strokeWidth: 1,
                          dashArray: [5, 5],
                        );
                      },
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: 1,
                          reservedSize: 22,
                          getTitlesWidget: (value, meta) {
                            final int xIndex = value.toInt();
                            final text = xLabels[xIndex] ?? '';
                            return Padding(
                              padding: const EdgeInsets.only(top: 6.0),
                              child: Text(
                                text,
                                style: TextStyle(
                                  fontFamily: 'Satoshi',
                                  color: Colors.grey.shade400,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: 100,
                          reservedSize: 34,
                          getTitlesWidget: (value, meta) {
                            if (value == bottomY || value == topY) {
                              return const SizedBox.shrink();
                            }
                            return Padding(
                              padding: const EdgeInsets.only(right: 6.0),
                              child: Text(
                                '${value.toInt()}',
                                style: TextStyle(
                                  fontFamily: 'GeneralSans',
                                  color: Colors.grey.shade400,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                                textAlign: TextAlign.right,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        color: const Color(0xFF023E8A),
                        barWidth: 3,
                        isStrokeCapRound: true,
                        dotData: FlDotData(
                          show: true,
                          getDotPainter: (spot, percent, barData, index) {
                            return FlDotCirclePainter(
                              radius: 4,
                              color: const Color(0xFF023E8A),
                              strokeWidth: 2,
                              strokeColor: Colors.white,
                            );
                          },
                        ),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              const Color(0xFF023E8A).withOpacity(0.15),
                              const Color(0xFF023E8A).withOpacity(0.0),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
        if (!isEmpty) ...[
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _TrendStat(label: 'Máximo', value: '${maxVal} L/m'),
              _TrendStat(label: 'Mínimo', value: '${minVal} L/m'),
              _TrendStat(label: 'Promedio', value: '${avgVal} L/m'),
            ],
          ),
        ],
      ],
    );
  }
}

class _TrendStat extends StatelessWidget {
  final String label;
  final String value;

  const _TrendStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'GeneralSans',
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade500,
            letterSpacing: 0.5,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Satoshi',
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Colors.grey.shade800,
          ),
        ),
      ],
    );
  }
}
