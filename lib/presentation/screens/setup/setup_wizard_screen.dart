import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'steps/biometria_step.dart';
import 'steps/historial_step.dart';
import 'steps/disclaimer_step.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import 'providers/setup_form_provider.dart';
import '../../../infrastructure/notifications/services/local_notification_service.dart';

class SetupWizardScreen extends ConsumerStatefulWidget {
  const SetupWizardScreen({super.key});

  @override
  ConsumerState<SetupWizardScreen> createState() => _SetupWizardScreenState();
}

class _SetupWizardScreenState extends ConsumerState<SetupWizardScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  final int _totalSteps = 3;

  Future<void> _nextStep() async {
    final formState = ref.read(setupFormProvider);

    
    if (formState.isPosting) return;

    if (_currentStep < _totalSteps - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      
      final profileData = formState.toJson();
      print(' Enviando payload a API (SetupWizard): $profileData');

      try {
        
        ref.read(setupFormProvider.notifier).setPosting(true);

        
        final repo = ref.read(authRepositoryProvider);
        await repo.createProfile(profileData: profileData);
        print(' Perfil guardado exitosamente en el backend');

        
        final currentUser = ref.read(authStateProvider).value;
        if (currentUser != null) {
          final updatedUser = currentUser.copyWith(isSetupCompleted: true);
          ref.read(authStateProvider.notifier).updateUser(updatedUser);
        }

        
        ref.read(setupCompletedProvider.notifier).complete();

        
        final name = currentUser?.fullName.split(' ').first ?? 'Paciente';
        await LocalNotificationService.showWelcomeNotification(name);

        
        if (mounted) context.go('/home');
      } catch (e) {
        print(' Error guardando perfil: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error al guardar datos. Intenta de nuevo.'),
            ),
          );
        }
      } finally {
        
        if (mounted) {
          ref.read(setupFormProvider.notifier).setPosting(false);
        }
      }
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, 
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: _currentStep == 0
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black87),
                onPressed: _previousStep,
              ),
        title: Text(
          'Configuración Inicial (${_currentStep + 1}/$_totalSteps)',
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            fontFamily: 'Satoshi',
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          
          LinearProgressIndicator(
            value: (_currentStep + 1) / _totalSteps,
            backgroundColor: Colors.grey[200],
            valueColor: const AlwaysStoppedAnimation<Color>(
              Color(0xFF023E8A), 
            ),
            minHeight: 4,
          ),

          
          Expanded(
            child: PageView(
              controller: _pageController,
              physics:
                  const NeverScrollableScrollPhysics(), 
              onPageChanged: (index) {
                setState(() {
                  _currentStep = index;
                });
              },
              children: const [BiometriaStep(), HistorialStep(), DisclaimerStep()],
            ),
          ),

          
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _nextStep,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF023E8A), 
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: ref.watch(setupFormProvider).isPosting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          ),
                        )
                      : Text(
                          _currentStep == _totalSteps - 1
                              ? 'Finalizar'
                              : 'Siguiente',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            fontFamily: 'Satoshi',
                          ),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
