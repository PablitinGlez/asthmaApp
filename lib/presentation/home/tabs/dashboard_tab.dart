import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'package:visibility_detector/visibility_detector.dart';
import '../../../core/storage/storage_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../../action_plan/providers/action_plan_provider.dart';
import '../providers/weekly_trend_provider.dart';
import '../widgets/dashboard/dashboard_greeting.dart';
import '../widgets/dashboard/spirometer_gauge.dart';
import '../widgets/dashboard/quick_actions.dart';
import '../widgets/dashboard/next_dose_card.dart';
import '../widgets/dashboard/core_vitals_cards.dart';
import '../widgets/dashboard/weekly_trend_chart.dart';
import '../widgets/dashboard/environmental_radar.dart';
import '../widgets/dashboard/performance_vitals_cards.dart';
import '../widgets/dashboard/emergency_sos_button.dart';
import '../widgets/dashboard/ai_simulator_panel.dart';
import '../widgets/dashboard/permissions_reminder_card.dart';
import '../widgets/guardian/guardian_view.dart';

import '../providers/patient_location_provider.dart';

class DashboardTab extends ConsumerStatefulWidget {
  const DashboardTab({super.key});

  @override
  ConsumerState<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends ConsumerState<DashboardTab> {
  final GlobalKey _gaugeKey = GlobalKey();
  final GlobalKey _startMeasureKey = GlobalKey();
  final GlobalKey _symptomKey = GlobalKey();
  final GlobalKey _helpButtonKey = GlobalKey();

  late TutorialCoachMark tutorialCoachMark;
  List<TargetFocus> targets = [];
  bool _isTutorialRunning = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authStateProvider).value;
      if (user != null && user.role != 'guardian') {
        ref.read(patientLocationProvider.notifier).fetchAndSyncLocation();
      }
    });
  }

  Future<void> _checkShowTutorial({bool alwaysShow = false}) async {
    final storage = StorageService();
    final hasSeenTour = await storage.getValue('dashboard_tour_seen');

    if ((hasSeenTour != 'true' || alwaysShow) && !_isTutorialRunning) {
      _isTutorialRunning = true; 

      
      if (!alwaysShow) {
        await storage.saveValue('dashboard_tour_seen', 'true');
      }

      
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
    targets.add(
      TargetFocus(
        identify: "GaugeTarget",
        keyTarget: _gaugeKey,
        alignSkip: Alignment.topRight,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Semáforo de Riesgo",
                    style: TextStyle(
                      fontFamily: 'Satoshi',
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Aquí verás tu nivel de control actual basado en tus últimas mediciones de soplido.",
                    style: TextStyle(
                      fontFamily: 'GeneralSans',
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Align(
                    alignment: Alignment.centerRight,
                    child: OutlinedButton(
                      onPressed: () => controller.next(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text("SIGUIENTE"),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
        shape: ShapeLightFocus.RRect,
        radius: 20,
      ),
    );

    targets.add(
      TargetFocus(
        identify: "StartMeasureTarget",
        keyTarget: _startMeasureKey,
        alignSkip: Alignment.topRight,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, controller) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Iniciar Medición",
                    style: TextStyle(
                      fontFamily: 'Satoshi',
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Usa este botón para registrar una nueva medición de tu flujo espiratorio (PEF) con el dispositivo.",
                    style: TextStyle(
                      fontFamily: 'GeneralSans',
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Align(
                    alignment: Alignment.centerRight,
                    child: OutlinedButton(
                      onPressed: () => controller.next(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text("SIGUIENTE"),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
        shape: ShapeLightFocus.RRect,
        radius: 20,
      ),
    );

    targets.add(
      TargetFocus(
        identify: "SymptomTarget",
        keyTarget: _symptomKey,
        alignSkip: Alignment.topRight,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, controller) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Registrar Síntomas",
                    style: TextStyle(
                      fontFamily: 'Satoshi',
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Reporta cómo te sientes, aunque no hagas una medición, para llevar un control más detallado.",
                    style: TextStyle(
                      fontFamily: 'GeneralSans',
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      onPressed: () => controller.skip(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF023E8A),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text("FINALIZAR"),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
        shape: ShapeLightFocus.RRect,
        radius: 20,
      ),
    );
  }

  void _showTutorial() {
    _initTargets();
    tutorialCoachMark = TutorialCoachMark(
      targets: targets,
      colorShadow: const Color(0xFF023E8A),
      opacityShadow:
          0.7, 
      paddingFocus: 10,
      textSkip: "",
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
      onClickTarget: (target) {
        tutorialCoachMark.next();
      },
      onClickOverlay: (target) {
        tutorialCoachMark.next();
      },
    )..show(context: context);
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).value;
    
    
    if (user?.role == 'guardian') {
      return const GuardianView();
    }

    final userName = user?.fullName.split(' ').first ?? "Usuario";
    final actionPlanState = ref.watch(actionPlanProvider);
    final trendState = ref.watch(weeklyTrendProvider);
    return VisibilityDetector(
      key: const Key('dashboard_tab_visibility'),
      onVisibilityChanged: (visibilityInfo) {
        final visiblePercentage = visibilityInfo.visibleFraction * 100;
        if (visiblePercentage == 100) {
          _checkShowTutorial();
        }
      },
      child: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(
              left: 24.0,
              right: 24.0,
              bottom: 80.0,
              top: kToolbarHeight + 48.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DashboardGreeting(
                      userName: userName,
                      helpButtonKey: _helpButtonKey,
                      onHelpTap: () => _checkShowTutorial(alwaysShow: true),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                const PermissionsReminderCard(),

                const SizedBox(height: 16),

                
                const AISimulatorPanel(),
                const SizedBox(height: 20),

                
                Center(
                  key: _gaugeKey,
                  child: const MainGaugeSection(),
                ),

                const SizedBox(height: 24),

                
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: QuickActionButton(
                        key: _startMeasureKey,
                        label: 'Registrar PEF',
                        icon: Icons.air,
                        color: const Color(0xFF023E8A),
                        onTap: () {
                          context.push('/spirometer');
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: QuickActionButton(
                        key: _symptomKey,
                        label: 'Registrar síntomas',
                        icon: Icons.edit_note,
                        color: const Color(0xFF023E8A),
                        isOutlined: true,
                        onTap: () {
                          context.push('/register-symptom');
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                
                Row(
                  children: [
                    Expanded(
                      child: QuickActionButton(
                        label: 'Mensajes',
                        icon: Icons.chat_bubble_outline_rounded,
                        color: const Color(0xFF0077B6),
                        onTap: () {
                          context.push('/chat');
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: QuickActionButton(
                        label: 'Mi Plan Médico',
                        icon: actionPlanState.hasPlan
                            ? Icons.health_and_safety_outlined
                            : Icons.medical_information_outlined,
                        color: const Color(0xFF023E8A),
                        isOutlined: true,
                        onTap: () {
                          if (!actionPlanState.isLoading) {
                            context.push(
                              '/action-plan',
                              extra: actionPlanState.hasPlan,
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                
                const NextDoseCard(),

                const SizedBox(height: 22),
                Divider(color: Colors.grey.shade100, thickness: 1),
                const SizedBox(height: 22),

                
                const WatchCoreVitals(),

                const SizedBox(height: 32),

                
                WeeklyTrendChart(state: trendState),

                const SizedBox(height: 32),

                
                const EnvironmentalRadar(),

                const SizedBox(height: 32),

                
                const WatchPerformanceVitals(),
              ],
            ),
          ),
          
          Positioned(
            bottom: 16,
            right: 24,
            child: EmergencySOSButton(
              onTap: () => EmergencySOSButton.showProtocol(context),
            ),
          ),
        ],
      ),
    );
  }
}

