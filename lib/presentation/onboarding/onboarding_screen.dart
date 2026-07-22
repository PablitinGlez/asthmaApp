import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../auth/providers/auth_provider.dart';
import 'models/onboarding_model.dart';
import 'widgets/onboarding_slide_widget.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late AnimationController _badgeController;
  late Animation<double> _badgeAnimation;

  @override
  void initState() {
    super.initState();
    // Animación de "Levitación" suave
    _badgeController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2), // Ciclo de 2 segundos
    )..repeat(reverse: true); // Sube y baja infinitamente

    _badgeAnimation = Tween<double>(begin: 0, end: 10).animate(
      CurvedAnimation(parent: _badgeController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _badgeController.dispose();
    super.dispose();
  }

  final List<OnboardingSlide> _slides = [
    OnboardingSlide(
      title: 'Bienvenido a\nAsthma Predictor',
      description:
          'Tu compañero personal para el control y prevención del asma',
      image: 'assets/personajes/per1.png',
    ),
    OnboardingSlide(
      title: 'Monitorea tu Salud',
      description:
          'Conecta dispositivos IoT y registra tus mediciones diarias de forma sencilla',
      image: 'assets/personajes/per2.png',
      badges: [
        FloatingBadge(
          icon: Icons.watch_rounded,
          top: 20,
          right: 40,
          animate: true,
        ),
        FloatingBadge(
          icon: Icons.medication_rounded,
          bottom: 50,
          left: 20,
          animate: true,
        ),
        FloatingBadge(
          icon: Icons.insert_chart_rounded,
          bottom: 20,
          right: 30,
          animate: true,
        ),
      ],
    ),
    OnboardingSlide(
      title: 'Predicción Inteligente',
      description:
          'Recibe alertas tempranas con IA para prevenir crisis asmáticas',
      image: '',
      badges: [
        FloatingBadge(
          svgPath: 'assets/charts/chart1.svg',
          top: 0,
          left: 130,
          animate: false,
          width: 160,
          height: 170,
          entranceAnimation: BadgeEntranceAnimation.fromRight,
        ),
        FloatingBadge(
          svgPath: 'assets/charts/chart2.svg',
          top: 130,
          left: 3,
          animate: false,
          width: 220,
          height: 140,
          entranceAnimation: BadgeEntranceAnimation.fromLeft,
        ),
        FloatingBadge(
          svgPath: 'assets/charts/chart3.svg',
          bottom: -10,
          right: 20,
          animate: false,
          width: 150,
          height: 110,
          entranceAnimation: BadgeEntranceAnimation.fromRight,
        ),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Fondo gradiente/imagen
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/fondo2.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 24),
                // Indicadores (Ahora arriba)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _slides.length,
                    (index) => _buildIndicator(index == _currentPage),
                  ),
                ),
                const SizedBox(height: 16),

                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _slides.length,
                    onPageChanged: (int page) {
                      setState(() {
                        _currentPage = page;
                      });
                    },
                    itemBuilder: (context, index) {
                      // Usamos el nuevo Widget Modular
                      return OnboardingSlideWidget(
                        slide: _slides[index],
                        badgeAnimation: _badgeAnimation,
                      );
                    },
                  ),
                ),

                // Botón Siguiente / Empezar (Solo abajo)
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_currentPage == _slides.length - 1) {
                          _completeOnboarding();
                        } else {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF023E8A),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        _currentPage == _slides.length - 1
                            ? 'Empezar'
                            : 'Siguiente',
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                          fontWeight: FontWeight.w400,
                          fontFamily: 'Satoshi',
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIndicator(bool isActive) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      height: 4,
      width: 35,
      decoration: BoxDecoration(
        color: isActive
            ? const Color(0xFF023E8A)
            : Colors.grey.withOpacity(0.3),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  void _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);

    // Actualizamos el estado global para que el Router reaccione
    ref.read(onboardingCompletedProvider.notifier).complete();

    // Navegar directamente al login para evitar el parpadeo del Splash
    if (mounted) context.go('/login');
  }
}
