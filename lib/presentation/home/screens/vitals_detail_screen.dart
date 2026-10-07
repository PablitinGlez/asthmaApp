import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../providers/measurements_provider.dart';
import '../../../domain/measurements/entities/measurement_history_item.dart';

enum _PeriodMode { day, month, year }

class VitalsDetailScreen extends ConsumerStatefulWidget {
  const VitalsDetailScreen({super.key});

  @override
  ConsumerState<VitalsDetailScreen> createState() =>
      _VitalsDetailScreenState();
}

class _VitalsDetailScreenState extends ConsumerState<VitalsDetailScreen> {
  _PeriodMode _mode = _PeriodMode.day;
  DateTime _anchor = DateTime.now();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted && ref.read(measurementsProvider).value == null) {
        ref.read(measurementsProvider.notifier).refresh();
      }
    });
  }

  void _shift(int days) {
    setState(() {
      switch (_mode) {
        case _PeriodMode.day:
          _anchor = _anchor.add(Duration(days: days));
          break;
        case _PeriodMode.month:
          _anchor = DateTime(_anchor.year, _anchor.month + days, 1);
          break;
        case _PeriodMode.year:
          _anchor = DateTime(_anchor.year + days, _anchor.month, 1);
          break;
      }
    });
  }

  bool _inRange(DateTime t) {
    switch (_mode) {
      case _PeriodMode.day:
        return t.year == _anchor.year &&
            t.month == _anchor.month &&
            t.day == _anchor.day;
      case _PeriodMode.month:
        return t.year == _anchor.year && t.month == _anchor.month;
      case _PeriodMode.year:
        return t.year == _anchor.year;
    }
  }

  String get _subtitle {
    switch (_mode) {
      case _PeriodMode.day:
        final today = DateTime.now();
        if (_anchor.year == today.year &&
            _anchor.month == today.month &&
            _anchor.day == today.day) {
          return 'Hoy';
        }
        return DateFormat('EEEE d MMMM', 'es').format(_anchor);
      case _PeriodMode.month:
        final now = DateTime.now();
        if (_anchor.year == now.year && _anchor.month == now.month) {
          return 'Este mes';
        }
        return DateFormat('MMMM yyyy', 'es').format(_anchor);
      case _PeriodMode.year:
        return _anchor.year == DateTime.now().year
            ? 'Este año'
            : '${_anchor.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final measurements = ref.watch(measurementsProvider).value?.allItems ?? [];
    final filtered = measurements.where((m) => _inRange(m.measuredAt)).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text(
          'Detalle de Vitales',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.w600,
            fontFamily: 'Satoshi',
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: measurements.isEmpty
                ? const _EmptyState()
                : ListView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                    children: [
                      _PeriodSelector(
                        mode: _mode,
                        subtitle: _subtitle,
                        onModeChanged: (m) => setState(() => _mode = m),
                        onPrev: () => _shift(-1),
                        onNext: () => _shift(1),
                        canNext: _mode == _PeriodMode.day &&
                            !(_anchor.year == DateTime.now().year &&
                                _anchor.month == DateTime.now().month &&
                                _anchor.day == DateTime.now().day) ||
                            _mode == _PeriodMode.month &&
                                !(_anchor.year == DateTime.now().year &&
                                    _anchor.month == DateTime.now().month) ||
                            _mode == _PeriodMode.year &&
                                _anchor.year != DateTime.now().year,
                      ),
                      const SizedBox(height: 16),
                      if (filtered.isEmpty)
                        Text(
                          'No hay registros en este rango',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'GeneralSans',
                            fontSize: 13,
                            color: Colors.grey.shade500,
                          ),
                        )
                      else ...[
                        _MetricCard(
                          title: 'Ritmo Cardíaco',
                          unit: ' bpm',
                          color: const Color(0xFFFF5D8F),
                          icon: Icons.monitor_heart_outlined,
                          minValue: _aggregate(filtered, (m) {
                            final h = m.heartRate?.toDouble();
                            return h;
                          }, min: true),
                          avgValue: _aggregate(filtered, (m) {
                            return m.heartRate?.toDouble();
                          }),
                          maxValue: _aggregate(filtered, (m) {
                            final h = m.heartRate?.toDouble();
                            return h;
                          }, max: true),
                          spots: _buildSpots(filtered, (m) {
                            return m.heartRate?.toDouble();
                          }),
                        ),
                        const SizedBox(height: 12),
                        _MetricCard(
                          title: 'Saturación SpO2',
                          unit: ' %',
                          color: const Color(0xFFD90429),
                          icon: Icons.bloodtype_outlined,
                          minValue: _aggregate(filtered, (m) {
                            final s = m.spo2?.toDouble();
                            return s;
                          }, min: true),
                          avgValue: _aggregate(filtered, (m) {
                            return m.spo2?.toDouble();
                          }),
                          maxValue: _aggregate(filtered, (m) {
                            final s = m.spo2?.toDouble();
                            return s;
                          }, max: true),
                          spots: _buildSpots(filtered, (m) {
                            return m.spo2?.toDouble();
                          }),
                        ),
                        const SizedBox(height: 12),
                        _MetricCard(
                          title: 'Horas de Sueño',
                          unit: ' h',
                          color: const Color(0xFF7209B7),
                          icon: Icons.bedtime_outlined,
                          minValue: _aggregate(filtered, (m) {
                            return m.sleepHours;
                          }, min: true),
                          avgValue: _aggregate(filtered, (m) {
                            return m.sleepHours;
                          }),
                          maxValue: _aggregate(filtered, (m) {
                            return m.sleepHours;
                          }, max: true),
                          spots: _buildSpots(filtered, (m) {
                            return m.sleepHours;
                          }),
                        ),
                        const SizedBox(height: 12),
                        _MetricCard(
                          title: 'Tasa Respiratoria',
                          unit: ' rpm',
                          color: const Color(0xFF219EBC),
                          icon: Icons.air_rounded,
                          minValue: _aggregate(filtered, (m) {
                            return m.respiratoryRate?.toDouble();
                          }, min: true),
                          avgValue: _aggregate(filtered, (m) {
                            return m.respiratoryRate?.toDouble();
                          }),
                          maxValue: _aggregate(filtered, (m) {
                            return m.respiratoryRate?.toDouble();
                          }, max: true),
                          spots: _buildSpots(filtered, (m) {
                            return m.respiratoryRate?.toDouble();
                          }),
                        ),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  double? _aggregate(
    List<MeasurementHistoryItem> items,
    double? Function(MeasurementHistoryItem) extract, {
    bool min = false,
    bool max = false,
  }) {
    final values = items
        .map(extract)
        .whereType<double>()
        .toList();
    if (values.isEmpty) return null;
    if (min) return values.reduce((a, b) => a < b ? a : b);
    if (max) return values.reduce((a, b) => a > b ? a : b);
    return values.reduce((a, b) => a + b) / values.length;
  }

  List<FlSpot> _buildSpots(
    List<MeasurementHistoryItem> items,
    double? Function(MeasurementHistoryItem) extract,
  ) {
    final spots = <FlSpot>[];
    final entries = items
        .map((m) => (m.measuredAt, extract(m)))
        .where((e) => e.$2 != null)
        .toList();

    if (entries.isEmpty) return spots;

    switch (_mode) {
      case _PeriodMode.day:
        final start = DateTime(entries.first.$1.year, entries.first.$1.month,
            entries.first.$1.day);
        for (var i = 0; i < entries.length; i++) {
          final minutes = entries[i].$1.difference(start).inMinutes;
          spots.add(FlSpot(minutes / 60.0, entries[i].$2!));
        }
        break;
      case _PeriodMode.month:
        final grouped = <int, List<double>>{};
        for (final e in entries) {
          grouped.putIfAbsent(e.$1.day, () => []).add(e.$2!);
        }
        grouped.forEach((day, vals) {
          final avg = vals.reduce((a, b) => a + b) / vals.length;
          spots.add(FlSpot(day.toDouble() - 1, avg));
        });
        spots.sort((a, b) => a.x.compareTo(b.x));
        break;
      case _PeriodMode.year:
        final grouped = <int, List<double>>{};
        for (final e in entries) {
          grouped.putIfAbsent(e.$1.month, () => []).add(e.$2!);
        }
        grouped.forEach((month, vals) {
          final avg = vals.reduce((a, b) => a + b) / vals.length;
          spots.add(FlSpot((month - 1).toDouble(), avg));
        });
        spots.sort((a, b) => a.x.compareTo(b.x));
        break;
    }
    return spots;
  }
}

class _PeriodSelector extends StatelessWidget {
  final _PeriodMode mode;
  final String subtitle;
  final ValueChanged<_PeriodMode> onModeChanged;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final bool canNext;

  const _PeriodSelector({
    required this.mode,
    required this.subtitle,
    required this.onModeChanged,
    required this.onPrev,
    required this.onNext,
    required this.canNext,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SegmentedButton<_PeriodMode>(
              segments: const [
                ButtonSegment(
                  value: _PeriodMode.day,
                  label: Text('Día'),
                  icon: Icon(Icons.calendar_view_day_outlined, size: 16),
                ),
                ButtonSegment(
                  value: _PeriodMode.month,
                  label: Text('Mes'),
                  icon: Icon(Icons.calendar_view_month_outlined, size: 16),
                ),
                ButtonSegment(
                  value: _PeriodMode.year,
                  label: Text('Año'),
                  icon: Icon(Icons.calendar_today_outlined, size: 16),
                ),
              ],
              selected: {mode},
              onSelectionChanged: (s) => onModeChanged(s.first),
              showSelectedIcon: false,
              style: ButtonStyle(
                visualDensity: VisualDensity.compact,
                foregroundColor: WidgetStateProperty.resolveWith((states) {
                  return states.contains(WidgetState.selected)
                      ? Colors.white
                      : Colors.grey.shade700;
                }),
                backgroundColor: WidgetStateProperty.resolveWith((states) {
                  return states.contains(WidgetState.selected)
                      ? const Color(0xFF023E8A)
                      : Colors.white;
                }),
                side: WidgetStateProperty.all(
                  BorderSide(color: Colors.grey.shade300),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _NavButton(
              icon: Icons.chevron_left_rounded,
              onTap: onPrev,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Satoshi',
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
            ),
            const SizedBox(width: 8),
            _NavButton(
              icon: Icons.chevron_right_rounded,
              onTap: canNext ? onNext : null,
            ),
          ],
        ),
      ],
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _NavButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: onTap == null ? Colors.grey.shade100 : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: onTap == null
                ? Colors.grey.shade200
                : Colors.grey.shade300,
          ),
        ),
        child: Icon(
          icon,
          size: 20,
          color: onTap == null ? Colors.grey.shade300 : const Color(0xFF023E8A),
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String unit;
  final Color color;
  final IconData icon;
  final double? minValue;
  final double? avgValue;
  final double? maxValue;
  final List<FlSpot> spots;

  const _MetricCard({
    required this.title,
    required this.unit,
    required this.color,
    required this.icon,
    required this.minValue,
    required this.avgValue,
    required this.maxValue,
    required this.spots,
  });

  String _fmt(double? v) => v == null
      ? '--'
      : v % 1 == 0
          ? '${v.toInt()}'
          : v.toStringAsFixed(1);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Satoshi',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 90,
            width: double.infinity,
            child: spots.isEmpty
                ? Center(
                    child: Text(
                      'Sin datos en este rango',
                      style: TextStyle(
                        fontFamily: 'GeneralSans',
                        fontSize: 12,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  )
                : LineChart(
                    key: ValueKey('$title-${spots.hashCode}'),
                    LineChartData(
                      minX: spots.first.x,
                      maxX: spots.last.x,
                      minY: 0,
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: Colors.grey.shade200,
                          strokeWidth: 1,
                          dashArray: [4, 4],
                        ),
                      ),
                      titlesData: const FlTitlesData(
                        show: true,
                        topTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          color: color,
                          barWidth: 2.5,
                          isStrokeCapRound: true,
                          dotData: FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                color.withOpacity(0.15),
                                color.withOpacity(0.0),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _Stat(label: 'Mín', value: '${_fmt(minValue)}$unit'),
              _Stat(label: 'Avg', value: '${_fmt(avgValue)}$unit'),
              _Stat(label: 'Máx', value: '${_fmt(maxValue)}$unit'),
            ],
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;

  const _Stat({required this.label, required this.value});

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
          style: const TextStyle(
            fontFamily: 'Satoshi',
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.monitor_heart_outlined,
            size: 56,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 12),
          Text(
            'Aún no hay mediciones',
            style: TextStyle(
              fontFamily: 'Satoshi',
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Cuando sincronices tu smartwatch o registres un PEF,\nverás aquí tu detalle por día, mes y año.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'GeneralSans',
              fontSize: 12.5,
              color: Colors.grey.shade400,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}