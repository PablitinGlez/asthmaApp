import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'dart:ui' as ui;
import '../../auth/providers/auth_provider.dart';
import '../../common/widgets/snackbar_helper.dart';
import '../../profile/screens/profile_screen.dart';
import '../tabs/dashboard_tab.dart';
import '../tabs/measurements_tab.dart';
import '../tabs/analysis_tab.dart';
import '../providers/measurements_provider.dart';
import '../providers/prediction_provider.dart';
import '../providers/smartwatch_provider.dart';
import '../../../core/services/pdf_service.dart';

import '../widgets/dashboard/risk_alert_sheet.dart';
import '../providers/patient_location_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;
  final GlobalKey _exportKey = GlobalKey();

  late final List<Widget> _screens = [
    const DashboardTab(),
    MeasurementsTab(exportKey: _exportKey),
    const AnalysisTab(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authStateProvider).value;
      if (user != null && user.role != 'guardian') {
        ref.read(patientLocationProvider.notifier).fetchAndSyncLocation();
      }

      if (user != null && mounted) {
        final firstName = user.fullName.split(' ').first;
        final avatar = CircleAvatar(
          radius: 18,
          backgroundColor: Color(
            int.parse('FF${user.avatarBackground}', radix: 16),
          ),
          child: ClipOval(
            child: SvgPicture.network(
              'https://api.dicebear.com/9.x/initials/svg?seed=${user.avatarSeed}&backgroundColor=${user.avatarBackground}',
              width: 36,
              height: 36,
              fit: BoxFit.cover,
            ),
          ),
        );
        SnackBarHelper.showSuccess(
          context,
          ' ¡Bienvenido, $firstName!',
          leading: avatar,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).value;
    final List<String> titles = [
      'Inicio',
      'Mediciones',
      'Análisis',
      'Mi Perfil',
    ];

    
    ref.listen(authStateProvider, (previous, next) {
      final u = next.value;
      if (u != null && u.role != 'guardian') {
        ref.read(patientLocationProvider.notifier).fetchAndSyncLocation();
      }
    });

    
    ref.listen<int?>(riskAlertProvider, (previous, next) {
      if (next != null && previous != next) {
        showRiskAlertSheet(context, ref, next);
        ref.read(riskAlertProvider.notifier).clear();
      }
    });

    
    ref.listen<PredictionState>(predictionProvider, (previous, next) {
      if (next.riskLevel == 'red' && previous?.riskLevel != 'red') {
        // Solo se activa la alerta automática cuando la predicción se apoya en
        // datos reales (reloj vinculado) o en una simulación explícita. Sin un
        // reloj conectado las vigas tienden a "rojo" por datos vacíos, lo que
        // disparaba falsas alarmas e interrumpía el flujo de los permisos.
        final watch = ref.read(smartwatchProvider);
        if (next.isSimulationActive || watch.isLinked) {
          debugPrint(' SOS TRIGGER: IA detectó riesgo CRÍTICO. Navegando a SOS.');
          context.push('/sos');
        }
      }
    });

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: ClipRect(
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: AppBar(
              backgroundColor: Colors.white.withOpacity(0.7),
              elevation: 0,
              centerTitle: false,
              title: Text(
                titles[_currentIndex],
                style: const TextStyle(
                  color: Colors.black87,
                  fontFamily: 'Satoshi',
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  overflow: TextOverflow.ellipsis,
                ),
                maxLines: 1,
              ),
              actions: [
                
                if (_currentIndex == 1)
                  IconButton(
                    key: _exportKey,
                    icon: const Icon(
                      Icons.ios_share_rounded,
                      color: Color(0xFF023E8A),
                      size: 22,
                    ),
                    onPressed: () async {
                      final history = ref.read(measurementsProvider).value;
                      if (history == null || history.allItems.isEmpty) {
                        SnackBarHelper.showError(
                          context,
                          'No hay mediciones para exportar.',
                        );
                        return;
                      }

                      SnackBarHelper.showSuccess(
                        context,
                        'Generando reporte detallado...',
                      );

                      try {
                        await PdfService.generateMeasurementsReport(
                          userName: user?.fullName ?? 'Paciente',
                          history: history.allItems,
                        );
                      } catch (e) {
                        if (mounted) {
                          SnackBarHelper.showError(
                            context,
                            'Error al generar el PDF: $e',
                          );
                        }
                      }
                    },
                  ),
                
                IconButton(
                  icon: const Icon(
                    Icons.notifications_none_outlined,
                    color: Colors.black87,
                  ),
                  onPressed: () => context.push('/notifications'),
                ),
                
                Padding(
                  padding: const EdgeInsets.only(right: 16.0, left: 8.0),
                  child: InkWell(
                    onTap: () => setState(() => _currentIndex = 3),
                    borderRadius: BorderRadius.circular(18),
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: Color(
                        int.parse(
                          'FF${user?.avatarBackground ?? '023e8a'}',
                          radix: 16,
                        ),
                      ),
                      child: ClipOval(
                        child: SvgPicture.network(
                          'https://api.dicebear.com/9.x/initials/svg?seed=${user?.avatarSeed ?? 'Usuario'}&backgroundColor=${user?.avatarBackground ?? '023e8a'}',
                          width: 36,
                          height: 36,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF023E8A),
        unselectedItemColor: Colors.grey.shade400,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        selectedLabelStyle: const TextStyle(
          fontFamily: 'Satoshi',
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        unselectedLabelStyle: const TextStyle(
          fontFamily: 'Satoshi',
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
        elevation: 0,
        iconSize: 22, 
        items: [
          BottomNavigationBarItem(
            icon: _buildTabIcon(Icons.home_outlined, false),
            activeIcon: _buildTabIcon(Icons.home_outlined, true),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: _buildTabIcon(Icons.monitor_heart_outlined, false),
            activeIcon: _buildTabIcon(Icons.monitor_heart_outlined, true),
            label: 'Mediciones',
          ),
          BottomNavigationBarItem(
            icon: _buildTabIcon(Icons.bar_chart_outlined, false),
            activeIcon: _buildTabIcon(Icons.bar_chart_outlined, true),
            label: 'Análisis',
          ),
          BottomNavigationBarItem(
            icon: _buildTabIcon(Icons.person_outline, false),
            activeIcon: _buildTabIcon(Icons.person_outline, true),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }

  Widget _buildTabIcon(IconData icon, bool isSelected) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        
        Container(
          width: 24,
          height: 3,
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF023E8A) : Colors.transparent,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 8),
        
        Icon(icon),
      ],
    );
  }
}
