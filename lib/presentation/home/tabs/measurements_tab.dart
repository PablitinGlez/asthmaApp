import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'package:asthmaapp/core/storage/storage_service.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:flutter_sticky_header/flutter_sticky_header.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../domain/measurements/entities/measurement_history_item.dart';
import '../providers/measurements_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../profile/providers/personal_info_provider.dart';

class MeasurementsTab extends ConsumerStatefulWidget {
  final GlobalKey? exportKey;
  const MeasurementsTab({super.key, this.exportKey});

  @override
  ConsumerState<MeasurementsTab> createState() => _MeasurementsTabState();
}

class _MeasurementsTabState extends ConsumerState<MeasurementsTab> {
  String _selectedSymptom = 'Todos';
  final ScrollController _scrollController = ScrollController();

  late TutorialCoachMark tutorialCoachMark;
  List<TargetFocus> targets = [];
  bool _isTutorialRunning = false; // Guardia para evitar solapamientos

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Ya no cargamos más por scroll, usamos paginación manual
  }

  Future<void> _checkShowTutorial() async {
    final storage = StorageService();
    final hasSeenTour = await storage.getValue('measurements_tour_seen');

    if (hasSeenTour != 'true' && !_isTutorialRunning) {
      _isTutorialRunning = true; // Bloquear nuevas llamadas de inmediato

      // Marcar como visto antes del delay para evitar colisiones de hilos
      await storage.saveValue('measurements_tour_seen', 'true');

      // Retrasar el inicio del tour para permitir que la UI se asiente y evitar "flicker"
      Future.delayed(const Duration(milliseconds: 500), () {
        if (!mounted) {
          _isTutorialRunning = false;
          return;
        }
        _initTargets();
        _showTutorial();
      });
    }
  }

  void _initTargets() {
    targets.clear();
    if (widget.exportKey != null) {
      targets.add(
        TargetFocus(
          identify: "ExportTarget",
          keyTarget: widget.exportKey,
          alignSkip: Alignment.bottomRight,
          contents: [
            TargetContent(
              align: ContentAlign.bottom,
              builder: (context, controller) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      "Exporta tu progreso",
                      style: TextStyle(
                        fontFamily: 'Satoshi',
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 20,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      "Genera un reporte PDF profesional en segundos para enviárselo a tu médico por WhatsApp o correo.",
                      style: TextStyle(
                        fontFamily: 'GeneralSans',
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
          shape: ShapeLightFocus.Circle,
        ),
      );
    }
  }

  void _showTutorial() {
    _initTargets();
    tutorialCoachMark = TutorialCoachMark(
      targets: targets,
      colorShadow: const Color(0xFF023E8A),
      opacityShadow:
          0.7, // Reducido para mayor fluidez en dispositivos como Poco M4
      paddingFocus: 10,
      textSkip: "SALTAR",
      textStyleSkip: const TextStyle(
        fontFamily: 'GeneralSans',
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      onSkip: () {
        _isTutorialRunning = false;
        return true;
      },
      onFinish: () {
        _isTutorialRunning = false;
      },
    )..show(context: context);
  }

  Map<String, List<_MeasurementData>> _groupMeasurements(
    List<MeasurementHistoryItem> history,
    double pb,
  ) {
    final Map<String, List<_MeasurementData>> groups = {};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    // Convert to UI model
    final List<_MeasurementData> mapped = history.map((h) {
      _Zone zone = _Zone.green;
      double pefValue = (h.pef ?? 0).toDouble();

      // Personal Best Real (Desde el perfil)
      if (pefValue > 0) {
        if (pefValue >= pb * 0.8)
          zone = _Zone.green;
        else if (pefValue >= pb * 0.5)
          zone = _Zone.yellow;
        else
          zone = _Zone.red;
      }

      List<String> symptomList = [];
      String? parsedIntensity;

      if (h.symptoms != null && h.symptoms!.isNotEmpty) {
        final parts = h.symptoms!.split('|');
        symptomList = parts[0]
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();

        if (parts.length > 1) {
          parsedIntensity = parts[1];
        }
      } else {
        symptomList = ['Ninguno'];
      }

      return _MeasurementData(
        id: h.id,
        value: pefValue,
        unit: 'L/min',
        dateTime: h.measuredAt.toLocal(),
        zone: zone,
        symptoms: symptomList.isEmpty ? ['Ninguno'] : symptomList,
        intensity: h.symptomIntensity ?? parsedIntensity,
        spo2: h.spo2,
        heartRate: h.heartRate,
        steps: h.steps,              // New
        sleepHours: h.sleepHours,      // New
        respiratoryRate: h.respiratoryRate, // New
        notes: h.notes,
        aqi: h.aqi,
        temperature: h.temperature,
        humidity: h.humidity,
        pollenLevel: h.pollenLevel,
        locationName: h.locationName,
      );
    }).toList();

    final filtered = mapped.where((m) {
      if (_selectedSymptom == 'Todos') return true;
      if (_selectedSymptom == 'Sin síntomas') {
        return m.symptoms.first == 'Ninguno';
      }
      if (_selectedSymptom == 'Con Tos') {
        return m.symptoms.contains('Tos');
      }
      if (_selectedSymptom == 'Crisis (Severa)') {
        return m.intensity == 'Severa' || m.zone == _Zone.red;
      }
      if (_selectedSymptom == 'Opresión') {
        return m.symptoms.contains('Opresión');
      }
      return m.symptoms.contains(_selectedSymptom);
    }).toList();

    for (var m in filtered) {
      final date = DateTime(m.dateTime.year, m.dateTime.month, m.dateTime.day);
      String label;
      if (date == today) {
        label = "Hoy";
      } else if (date == yesterday) {
        label = "Ayer";
      } else {
        label = DateFormat('d MMMM', 'es').format(date);
      }

      if (!groups.containsKey(label)) {
        groups[label] = [];
      }
      groups[label]!.add(m);
    }
    return groups;
  }

  @override
  Widget build(BuildContext context) {
    final asyncMeasurements = ref.watch(measurementsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: VisibilityDetector(
        key: const Key('measurements_tab_visibility'),
        onVisibilityChanged: (visibilityInfo) {
          final visiblePercentage = visibilityInfo.visibleFraction * 100;
          if (visiblePercentage == 100) {
            _checkShowTutorial();
          }
        },
        child: RefreshIndicator(
          onRefresh: () => ref.read(measurementsProvider.notifier).refresh(),
          child: asyncMeasurements.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) =>
                Center(child: Text('Error al cargar mediciones: $err')),
            data: (state) {
              // Obtenemos el perfil para usar el Personal Best Real
              final profile = ref.watch(personalInfoProvider).profile;
              final double pb = (profile?.personalBestPef ?? 450).toDouble();

              final groupedData = _groupMeasurements(state.visibleItems, pb);

              return CustomScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.only(
                      left: 24.0,
                      right: 24.0,
                      top: kToolbarHeight + 48.0,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _SummaryHeader(
                            onHelpPress: _showTutorial,
                            history: state
                                .allItems, // Calculamos sobre TODO el historial
                          ),
                          const SizedBox(height: 24),
                          _SymptomFilters(
                            selectedSymptom: _selectedSymptom,
                            onSelected: (val) =>
                                setState(() => _selectedSymptom = val),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                  if (groupedData.isEmpty)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: _EmptyState(),
                    )
                  else
                    ...groupedData.entries.map((entry) {
                      return SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        sliver: SliverStickyHeader(
                          header: Container(
                            height: 40.0,
                            color: Colors.white,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              entry.key,
                              style: const TextStyle(
                                fontFamily: 'Satoshi',
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.black45,
                              ),
                            ),
                          ),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate((
                              context,
                              index,
                            ) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _MeasurementCard(
                                  data: entry.value[index],
                                ),
                              );
                            }, childCount: entry.value.length),
                          ),
                        ),
                      );
                    }).toList(),
                  if (state.allItems.isNotEmpty)
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 24,
                        horizontal: 24,
                      ),
                      sliver: SliverToBoxAdapter(
                        child: _PaginationFooter(
                          currentPage: state.currentPage,
                          totalPages: state.totalPages,
                          hasNext: state.hasNext,
                          hasPrevious: state.hasPrevious,
                          isLoading: state.isLoadingMore,
                          onNext: () {
                            ref.read(measurementsProvider.notifier).nextPage();
                            _scrollController.animateTo(
                              0,
                              duration: const Duration(milliseconds: 500),
                              curve: Curves.easeInOut,
                            );
                          },
                          onPrevious: () {
                            ref
                                .read(measurementsProvider.notifier)
                                .previousPage();
                            _scrollController.animateTo(
                              0,
                              duration: const Duration(milliseconds: 500),
                              curve: Curves.easeInOut,
                            );
                          },
                        ),
                      ),
                    ),
                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              );
            },
          ),
        ),
      ),
      floatingActionButton: SpeedDial(
        icon: Icons.add,
        activeIcon: Icons.close,
        backgroundColor: const Color(0xFF023E8A),
        foregroundColor: Colors.white,
        overlayColor: Colors.black,
        overlayOpacity: 0.4,
        spacing: 12,
        spaceBetweenChildren: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        children: [
          SpeedDialChild(
            backgroundColor: Colors.white,
            label: 'Soplar (Espirómetro)',
            labelStyle: const TextStyle(
              fontFamily: 'Satoshi',
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
            onTap: () => context.push('/spirometer'),
          ),
          SpeedDialChild(
            backgroundColor: Colors.white,
            label: 'Registrar Síntomas',
            labelStyle: const TextStyle(
              fontFamily: 'Satoshi',
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
            onTap: () {
              final history = ref.read(measurementsProvider).value?.allItems;
              if (history == null || history.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'No hay mediciones recientes para añadir síntomas.',
                    ),
                  ),
                );
                return;
              }
              final now = DateTime.now();
              final currentHour = DateTime(
                now.year,
                now.month,
                now.day,
                now.hour,
              );
              final recentReadings = history.where((h) {
                final local = h.measuredAt.toLocal();
                final rh = DateTime(
                  local.year,
                  local.month,
                  local.day,
                  local.hour,
                );
                return rh == currentHour;
              }).toList();

              if (recentReadings.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'No hay medición en la última hora. Haz una medición primero.',
                    ),
                  ),
                );
                return;
              }

              recentReadings.sort(
                (a, b) => b.measuredAt.compareTo(a.measuredAt),
              );
              final item = recentReadings.first;
              final profile = ref.read(personalInfoProvider).profile;
              final double pb = (profile?.personalBestPef ?? 450).toDouble();
              final pefValue = (item.pef ?? 0).toDouble();
              _Zone zone;
              if (pefValue >= pb * 0.8)
                zone = _Zone.green;
              else if (pefValue >= pb * 0.5)
                zone = _Zone.yellow;
              else
                zone = _Zone.red;

              Color zoneColor;
              switch (zone) {
                case _Zone.green:
                  zoneColor = const Color(0xFF4CAF50);
                case _Zone.yellow:
                  zoneColor = const Color(0xFFFFC107);
                case _Zone.red:
                  zoneColor = const Color(0xFFD90429);
              }

              final rawSymptoms = item.symptoms ?? '';
              final parts = rawSymptoms.split('|');
              final symList = parts[0]
                  .split(',')
                  .map((e) => e.trim())
                  .where((e) => e.isNotEmpty)
                  .toList();

              final data = _MeasurementData(
                id: item.id,
                value: pefValue,
                unit: 'L/min',
                dateTime: item.measuredAt.toLocal(),
                zone: zone,
                symptoms: symList.isEmpty ? ['Ninguno'] : symList,
                spo2: item.spo2,
                heartRate: item.heartRate,
                notes: item.notes,
                aqi: item.aqi,
                temperature: item.temperature,
                humidity: item.humidity,
                pollenLevel: item.pollenLevel,
                locationName: item.locationName,
              );

              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => _MeasurementDetailsModal(
                  data: data,
                  existingIntensity: parts.length > 1 ? parts[1] : 'Moderada',
                  zoneColor: zoneColor,
                  onSaved: () =>
                      ref.read(measurementsProvider.notifier).silentRefresh(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SummaryHeader extends ConsumerWidget {
  final VoidCallback onHelpPress;
  final List<MeasurementHistoryItem> history;

  const _SummaryHeader({required this.onHelpPress, required this.history});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Buscar el mejor PEF de hoy
    final now = DateTime.now();
    final todayHistory = history.where((h) {
      final localDate = h.measuredAt.toLocal();
      return h.pef != null &&
          localDate.year == now.year &&
          localDate.month == now.month &&
          localDate.day == now.day;
    }).toList();

    int bestToday = 0;
    if (todayHistory.isNotEmpty) {
      bestToday = todayHistory
          .map((h) => h.pef!)
          .reduce((a, b) => a > b ? a : b);
    }

    // â”€â”€ LÃ“GICA DE ESTADO INTELIGENTE â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    // Personal Best Real (Desde el perfil)
    final profile = ref.watch(personalInfoProvider).profile;
    final double pb = (profile?.personalBestPef ?? 450).toDouble();

    String statusLabel;
    Color statusColor;
    IconData statusIcon;

    if (bestToday <= 0) {
      statusLabel = 'S/D';
      statusColor = Colors.grey.shade400;
      statusIcon = Icons.remove_circle_outline_rounded;
    } else if (bestToday >= pb * 0.8) {
      // â‰¥ 360 L/min  â†’ Zona Verde
      statusLabel = 'Controlado';
      statusColor = const Color(0xFF4CAF50);
      statusIcon = Icons.check_circle_outline_rounded;
    } else if (bestToday >= pb * 0.5) {
      // 225â€“359 L/min â†’ Zona Amarilla
      statusLabel = 'Precaución';
      statusColor = const Color(0xFFFFC107);
      statusIcon = Icons.warning_amber_rounded;
    } else {
      // < 225 L/min  â†’ Zona Roja
      statusLabel = 'Riesgo';
      statusColor = const Color(0xFFF44336);
      statusIcon = Icons.dangerous_outlined;
    }
    // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Resumen Diario',
              style: TextStyle(
                fontFamily: 'Satoshi',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.help_outline_rounded,
                color: Colors.grey.shade400,
                size: 20,
              ),
              onPressed: onHelpPress,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                title: 'Mejor hoy',
                value: bestToday > 0 ? bestToday.toString() : '--',
                unit: 'L/min',
                color: const Color(0xFF023E8A),
                trendData: const [0.5, 0.7, 0.6, 0.8, 0.75, 0.9, 0.85],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SummaryCard(
                title: 'Estado Gral.',
                value: statusLabel,
                unit: '',
                color: statusColor,
                trendData: const [],
                icon: statusIcon,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final String unit;
  final Color color;
  final List<double> trendData;
  final IconData? icon;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.unit,
    required this.color,
    required this.trendData,
    this.icon,
  });

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
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 24,
            width: double.infinity,
            child: icon != null
                ? Align(
                    alignment: Alignment.topLeft,
                    child: Icon(icon, color: color, size: 24),
                  )
                : CustomPaint(
                    painter: _SparklinePainter(data: trendData, color: color),
                  ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontFamily: 'GeneralSans',
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontFamily: 'Satoshi',
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                ),
              ),
              if (unit.isNotEmpty) ...[
                const SizedBox(width: 4),
                Text(
                  unit,
                  style: TextStyle(
                    fontFamily: 'GeneralSans',
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade400,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _SymptomFilters extends StatelessWidget {
  final String selectedSymptom;
  final ValueChanged<String> onSelected;

  const _SymptomFilters({
    required this.selectedSymptom,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final options = [
      'Todos',
      'Sin síntomas',
      'Con Tos',
      'Opresión',
      'Crisis (Severa)',
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: options.map((opt) {
          final isSelected = selectedSymptom == opt;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(opt),
              selected: isSelected,
              onSelected: (selected) => onSelected(opt),
              backgroundColor: Colors.grey.shade50,
              selectedColor: const Color(0xFF023E8A).withValues(alpha: 0.1),
              labelStyle: TextStyle(
                fontFamily: 'GeneralSans',
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? const Color(0xFF023E8A) : Colors.black54,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: isSelected
                      ? const Color(0xFF023E8A).withValues(alpha: 0.3)
                      : Colors.grey.shade200,
                ),
              ),
              showCheckmark: false,
            ),
          );
        }).toList(),
      ),
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
          const SizedBox(height: 60),
          // Usamos una ilustración sutil si existe, o un icono premium
          Icon(Icons.air_rounded, size: 80, color: Colors.grey.shade200),
          const SizedBox(height: 24),
          const Text(
            "Parece que hoy no has soplado...",
            style: TextStyle(
              fontFamily: 'Satoshi',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "¡Vamos a ello! Registra tu primera medición.",
            style: TextStyle(
              fontFamily: 'GeneralSans',
              fontSize: 14,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<double> data;
  final Color color;

  _SparklinePainter({required this.data, required this.color});

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

enum _Zone { green, yellow, red }

class _MeasurementData {
  final int? id;
  final double value;
  final String unit;
  final DateTime dateTime;
  final _Zone zone;
  final List<String> symptoms;
  final String? intensity;
  final int? spo2;
  final int? heartRate;
  final int? steps;
  final double? sleepHours;
  final int? respiratoryRate;
  final String? notes;
  final int? aqi;
  final double? temperature;
  final int? humidity;
  final String? pollenLevel;
  final String? locationName;

  _MeasurementData({
    this.id,
    required this.value,
    required this.unit,
    required this.dateTime,
    required this.zone,
    required this.symptoms,
    this.intensity,
    this.spo2,
    this.heartRate,
    this.steps,
    this.sleepHours,
    this.respiratoryRate,
    this.notes,
    this.aqi,
    this.temperature,
    this.humidity,
    this.pollenLevel,
    this.locationName,
  });
}

class _MeasurementCard extends ConsumerStatefulWidget {
  final _MeasurementData data;
  const _MeasurementCard({required this.data});

  @override
  ConsumerState<_MeasurementCard> createState() => _MeasurementCardState();
}

class _MeasurementCardState extends ConsumerState<_MeasurementCard> {
  Color _getZoneColor() {
    switch (widget.data.zone) {
      case _Zone.green:
        return const Color(0xFF4CAF50);
      case _Zone.yellow:
        return const Color(0xFFFFC107);
      case _Zone.red:
        return const Color(0xFFD90429);
    }
  }

  String _getZoneLabel() {
    switch (widget.data.zone) {
      case _Zone.green:
        return 'Controlado';
      case _Zone.yellow:
        return 'Precaución';
      case _Zone.red:
        return 'Riesgo';
    }
  }

  bool get _hasSymptoms =>
      widget.data.symptoms.isNotEmpty &&
      widget.data.symptoms.first != 'Ninguno';

  void _openModal(BuildContext context) {
    if (widget.data.id == null) return;

    final zoneColor = _getZoneColor();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _MeasurementDetailsModal(
        data: widget.data,
        existingIntensity: widget.data.intensity ?? 'Moderada',
        zoneColor: zoneColor,
        onSaved: () async {
          await ref.read(measurementsProvider.notifier).silentRefresh();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('hh:mm a');
    final zoneColor = _getZoneColor();

    return GestureDetector(
      onTap: () => _openModal(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
        child: Row(
          children: [
            Container(
              width: 4,
              height: 40,
              decoration: BoxDecoration(
                color: zoneColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${widget.data.value.toInt()} ${widget.data.unit}',
                        style: const TextStyle(
                          fontFamily: 'Satoshi',
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        timeFormat.format(widget.data.dateTime),
                        style: const TextStyle(
                          fontFamily: 'GeneralSans',
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Colors.black38,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        _getZoneLabel(),
                        style: TextStyle(
                          fontFamily: 'GeneralSans',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: zoneColor,
                        ),
                      ),
                      if (widget.data.spo2 != null ||
                          widget.data.heartRate != null ||
                          widget.data.steps != null) ...[
                        const SizedBox(width: 12),
                        Container(
                          width: 1,
                          height: 10,
                          color: Colors.grey.shade200,
                        ),
                        const SizedBox(width: 12),
                        if (widget.data.spo2 != null)
                          _VitalBadge(
                            icon: Icons.bloodtype_outlined,
                            value: '${widget.data.spo2}%',
                            color: Colors.grey.shade600,
                          ),
                        if (widget.data.heartRate != null) ...[
                          const SizedBox(width: 8),
                          _VitalBadge(
                            icon: Icons.favorite_outline_rounded,
                            value: '${widget.data.heartRate}',
                            color: Colors.grey.shade600,
                          ),
                        ],
                        if (widget.data.steps != null) ...[
                          const SizedBox(width: 8),
                          _VitalBadge(
                            icon: Icons.directions_walk_rounded,
                            value: '${widget.data.steps}',
                            color: Colors.grey.shade600,
                          ),
                        ],
                      ],
                      if (_hasSymptoms) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: zoneColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.medical_services_outlined,
                                size: 10,
                                color: zoneColor,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                'Síntomas',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: zoneColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.grey.shade300,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

//  MODAL DE DETALLES
class _MeasurementDetailsModal extends ConsumerStatefulWidget {
  final _MeasurementData data;
  final String existingIntensity;
  final Color zoneColor;
  final Future<void> Function() onSaved;

  const _MeasurementDetailsModal({
    required this.data,
    required this.existingIntensity,
    required this.zoneColor,
    required this.onSaved,
  });

  @override
  ConsumerState<_MeasurementDetailsModal> createState() =>
      _MeasurementDetailsModalState();
}

class _MeasurementDetailsModalState
    extends ConsumerState<_MeasurementDetailsModal>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const _options = [
    'Tos',
    'Sibilancias',
    'Disnea',
    'Opresión',
    'Fatiga',
    'Flema',
  ];

  late Set<String> _selected;
  late String _selectedIntensity;
  late TextEditingController _notes;
  bool _isSaving = false;

  Color _intensityColor(String level) {
    switch (level) {
      case 'Leve':
        return const Color(0xFF4CAF50);
      case 'Severa':
        return const Color(0xFFD90429);
      default:
        return const Color(0xFFFF9800); // Moderada
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _selected = Set<String>.from(
      widget.data.symptoms.where((s) => s != 'Ninguno'),
    );
    _selectedIntensity = widget.existingIntensity;
    _notes = TextEditingController(text: widget.data.notes ?? '');
  }

  @override
  void dispose() {
    _tabController.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      final dio = ref.read(dioClientProvider);
      final supabaseDs = ref.read(supabaseAuthDataSourceProvider);
      final token = await supabaseDs.getIdToken();
      if (token == null) throw Exception('Sin token');

      final sympStr = _selected.join(', ');
      final notesStr = _notes.text.trim();

      await dio.patch(
        '/api/measurements/spirometer/${widget.data.id}/symptoms',
        data: {
          'symptoms': sympStr.isEmpty ? '' : sympStr,
          'symptom_intensity': _selected.isNotEmpty ? _selectedIntensity : null,
          'notes': notesStr.isEmpty ? '' : notesStr,
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      await widget.onSaved();
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(' Síntomas guardados'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('hh:mm a');
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 16),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: widget.zoneColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.air_rounded,
                      color: widget.zoneColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${widget.data.value.toInt()} ${widget.data.unit}',
                        style: const TextStyle(
                          fontFamily: 'Satoshi',
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        timeFormat.format(widget.data.dateTime),
                        style: const TextStyle(
                          fontFamily: 'GeneralSans',
                          fontSize: 12,
                          color: Colors.black38,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TabBar(
              controller: _tabController,
              labelColor: const Color(0xFF023E8A),
              unselectedLabelColor: Colors.black45,
              indicatorColor: const Color(0xFF023E8A),
              labelStyle: const TextStyle(
                fontFamily: 'Satoshi',
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
              unselectedLabelStyle: const TextStyle(
                fontFamily: 'GeneralSans',
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
              tabs: const [
                Tab(text: 'Respiración'),
                Tab(text: 'Ambiental'),
                Tab(text: 'Vitales'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildRespirationTab(scrollController),
                  _buildEnvironmentTab(scrollController),
                  _buildVitalsTab(scrollController),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRespirationTab(ScrollController scrollController) {
    return SingleChildScrollView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '¿Cómo te sentiste?',
            style: TextStyle(
              fontFamily: 'Satoshi',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Toca los síntomas que apliquen a esta medición.',
            style: TextStyle(
              fontFamily: 'GeneralSans',
              fontSize: 13,
              color: Colors.black45,
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _options.map((sym) {
              final isSel = _selected.contains(sym);
              return GestureDetector(
                onTap: () => setState(() {
                  if (isSel) {
                    _selected.remove(sym);
                  } else {
                    _selected.add(sym);
                  }
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isSel
                        ? widget.zoneColor.withOpacity(0.12)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: isSel ? widget.zoneColor : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isSel) ...[
                        Icon(
                          Icons.check_circle_rounded,
                          size: 14,
                          color: widget.zoneColor,
                        ),
                        const SizedBox(width: 6),
                      ],
                      Text(
                        sym,
                        style: TextStyle(
                          fontFamily: 'GeneralSans',
                          fontSize: 14,
                          fontWeight: isSel ? FontWeight.w700 : FontWeight.w400,
                          color: isSel ? widget.zoneColor : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          // ── Intensidad ──
          if (_selected.isNotEmpty) ...[
            const Text(
              'Intensidad',
              style: TextStyle(
                fontFamily: 'GeneralSans',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                for (final level in ['Leve', 'Moderada', 'Severa']) ...[
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedIntensity = level),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _selectedIntensity == level
                              ? _intensityColor(level).withOpacity(0.12)
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _selectedIntensity == level
                                ? _intensityColor(level)
                                : Colors.transparent,
                            width: 1.5,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          level,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: _selectedIntensity == level
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: _selectedIntensity == level
                                ? _intensityColor(level)
                                : Colors.black54,
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (level != 'Severa') const SizedBox(width: 8),
                ],
              ],
            ),
            const SizedBox(height: 24),
          ] else
            const SizedBox(height: 28),
          const Text(
            'Notas adicionales',
            style: TextStyle(
              fontFamily: 'GeneralSans',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _notes,
            maxLines: 3,
            style: const TextStyle(
              fontFamily: 'GeneralSans',
              fontSize: 14,
              color: Colors.black87,
            ),
            decoration: InputDecoration(
              hintText: 'Ej: dificultad al despertar...',
              hintStyle: const TextStyle(color: Colors.black26),
              filled: true,
              fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: widget.zoneColor),
              ),
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              onPressed: _isSaving ? null : _save,
              icon: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.check_rounded),
              label: const Text(
                'Guardar Cambios',
                style: TextStyle(
                  fontFamily: 'Satoshi',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.zoneColor,
                foregroundColor: Colors.white,
                disabledBackgroundColor: widget.zoneColor.withOpacity(0.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnvironmentTab(ScrollController scrollController) {
    // Determine colors/status based on values (simplified logic)
    Color aqiColor = Colors.green;
    String aqiStatus = "Bueno";
    if (widget.data.aqi != null) {
      if (widget.data.aqi! > 150) {
        aqiColor = Colors.red;
        aqiStatus = "Dañino";
      } else if (widget.data.aqi! > 50) {
        aqiColor = Colors.orange;
        aqiStatus = "Moderado";
      }
    }

    Color pollenColor = Colors.green;
    String pollenVal = widget.data.pollenLevel ?? "Bajo";
    if (pollenVal.toLowerCase().contains("high") ||
        pollenVal.toLowerCase().contains("alto") ||
        pollenVal.toLowerCase() == "peligroso") {
      pollenVal = "Alto";
      pollenColor = Colors.red;
    } else if (pollenVal.toLowerCase().contains("moderate") ||
        pollenVal.toLowerCase().contains("medio") ||
        pollenVal.toLowerCase() == "precaución") {
      pollenVal = "Medio";
      pollenColor = Colors.orange;
    } else {
      pollenVal = "Bajo";
    }

    return SingleChildScrollView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      child: widget.data.aqi == null
          ? _buildEmptyState(
              "Sin datos",
              "No se registró el ambiente en este soplido.",
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoCard(
                  title: "Calidad del Aire (ICA)",
                  value: "${widget.data.aqi}",
                  subtitle: aqiStatus,
                  icon: Icons.air,
                  color: aqiColor,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoCard(
                        title: "Polen",
                        value: pollenVal,
                        subtitle: "Nivel",
                        icon: Icons.park_outlined,
                        color: pollenColor,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildInfoCard(
                        title: "Humedad",
                        value: "${widget.data.humidity}%",
                        subtitle: "Relativa",
                        icon: Icons.water_drop_outlined,
                        color: Colors.lightBlue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildInfoCard(
                  title: "Temperatura",
                  value: "${widget.data.temperature}°C",
                  subtitle: "Ambiente exterior",
                  icon: Icons.thermostat_outlined,
                  color: Colors.orange,
                ),
                if (widget.data.locationName != null &&
                    widget.data.locationName!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.location_on_rounded,
                            size: 18,
                            color: Colors.blue.shade700,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Ubicación de Medición",
                                style: TextStyle(
                                  fontFamily: 'GeneralSans',
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black45,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                widget.data.locationName!,
                                style: const TextStyle(
                                  fontFamily: 'Satoshi',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
    );
  }

  Widget _buildVitalsTab(ScrollController scrollController) {
    return SingleChildScrollView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      child: Column(
        children: [
          // Ritmo Cardíaco
          _buildInfoCard(
            title: "Ritmo Cardíaco (BPM)",
            value: widget.data.heartRate?.toString() ?? "--",
            subtitle: "Latidos por minuto",
            icon: Icons.favorite_outline,
            color: widget.data.heartRate != null
                ? Colors.redAccent
                : Colors.grey.shade400,
          ),
          const SizedBox(height: 16),

          // Oxígeno
          _buildInfoCard(
            title: "Oxígeno en Sangre (SpO2)",
            value: widget.data.spo2 != null ? "${widget.data.spo2}%" : "--",
            subtitle: "Saturación",
            icon: Icons.bloodtype_outlined,
            color:
                widget.data.spo2 != null ? Colors.red : Colors.grey.shade400,
          ),
          const SizedBox(height: 16),

          // Pasos
          _buildInfoCard(
            title: "Pasos",
            value: widget.data.steps?.toString() ?? "--",
            subtitle: "Actividad física",
            icon: Icons.directions_walk_rounded,
            color:
                widget.data.steps != null ? Colors.orange : Colors.grey.shade400,
          ),
          const SizedBox(height: 16),

          // Sueño
          _buildInfoCard(
            title: "Sueño",
            value: widget.data.sleepHours != null
                ? "${widget.data.sleepHours!.toStringAsFixed(1)}h"
                : "--",
            subtitle: "Descanso total",
            icon: Icons.bedtime_outlined,
            color: widget.data.sleepHours != null
                ? Colors.deepPurple
                : Colors.grey.shade400,
          ),
          const SizedBox(height: 16),

          // Tasa Respiratoria
          _buildInfoCard(
            title: "Tasa Respiratoria",
            value: widget.data.respiratoryRate != null
                ? "${widget.data.respiratoryRate} rpm"
                : "--",
            subtitle: "Respiraciones por minuto",
            icon: Icons.air_rounded,
            color: widget.data.respiratoryRate != null
                ? Colors.teal
                : Colors.grey.shade400,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'GeneralSans',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.black54,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontFamily: 'Satoshi',
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontFamily: 'GeneralSans',
                    fontSize: 12,
                    color: color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String title, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 48),
          Icon(
            Icons.monitor_heart_outlined,
            size: 64,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Satoshi',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'GeneralSans',
              fontSize: 14,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}

class _VitalBadge extends StatelessWidget {
  final IconData icon;
  final String value;
  final Color color;

  const _VitalBadge({
    required this.icon,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color.withOpacity(0.8)),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Satoshi',
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaginationFooter extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final bool hasNext;
  final bool hasPrevious;
  final bool isLoading;
  final VoidCallback onNext;
  final VoidCallback onPrevious;

  const _PaginationFooter({
    required this.currentPage,
    required this.totalPages,
    required this.hasNext,
    required this.hasPrevious,
    required this.isLoading,
    required this.onNext,
    required this.onPrevious,
  });

  @override
  Widget build(BuildContext context) {
    if (totalPages <= 1 && !isLoading) return const SizedBox.shrink();

    return Column(
      children: [
        if (isLoading)
          const Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: LinearProgressIndicator(
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF023E8A)),
            ),
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Botón Anterior
            _PageButton(
              label: 'Anterior',
              icon: Icons.arrow_back_ios_new_rounded,
              onTap: hasPrevious && !isLoading ? onPrevious : null,
            ),

            // Indicador de Página
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Text(
                'Página $currentPage de $totalPages',
                style: const TextStyle(
                  fontFamily: 'Satoshi',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.black54,
                ),
              ),
            ),

            // Botón Siguiente
            _PageButton(
              label: 'Siguiente',
              icon: Icons.arrow_forward_ios_rounded,
              onTap: hasNext && !isLoading ? onNext : null,
              isRight: true,
            ),
          ],
        ),
      ],
    );
  }
}

class _PageButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final bool isRight;

  const _PageButton({
    required this.label,
    required this.icon,
    this.onTap,
    this.isRight = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDisabled = onTap == null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Opacity(
          opacity: isDisabled ? 0.4 : 1.0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(
                color: isDisabled
                    ? Colors.grey.shade200
                    : const Color(0xFF023E8A).withOpacity(0.3),
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!isRight) ...[
                  Icon(icon, size: 14, color: const Color(0xFF023E8A)),
                  const SizedBox(width: 8),
                ],
                Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'Satoshi',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF023E8A),
                  ),
                ),
                if (isRight) ...[
                  const SizedBox(width: 8),
                  Icon(icon, size: 14, color: const Color(0xFF023E8A)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
