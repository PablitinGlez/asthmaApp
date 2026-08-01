import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pinput/pinput.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/auth_notifier.dart';
import '../../common/widgets/snackbar_helper.dart';

class OtpVerificationScreen extends ConsumerStatefulWidget {
  const OtpVerificationScreen({super.key});

  @override
  ConsumerState<OtpVerificationScreen> createState() =>
      _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends ConsumerState<OtpVerificationScreen> {
  final pinController = TextEditingController();
  final focusNode = FocusNode();

  static const String _attemptsKey = 'otp_failed_attempts';
  static const String _lockoutKey = 'otp_lockout_until';

  int _failedAttempts = 0;
  DateTime? _lockoutUntil;
  int _remainingLockoutSeconds = 0;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _loadLockoutState();

    ref.listenManual(authNotifierProvider, (previous, next) {
      if (next.errorMessage != null &&
          !next.isLoading &&
          previous?.errorMessage != next.errorMessage) {
        _handleFailedAttempt();

        SnackBarHelper.showError(context, next.errorMessage!);
        pinController.clear();
      }

      if (next.isAuthenticated && !next.isLoading) {
        _resetLockout();

        SnackBarHelper.showSuccess(context, '¡Cuenta verificada con éxito!');
      }
    });
  }

  Future<void> _loadLockoutState() async {
    final prefs = await SharedPreferences.getInstance();
    final lockoutString = prefs.getString(_lockoutKey);
    final attempts = prefs.getInt(_attemptsKey) ?? 0;

    if (mounted) {
      setState(() {
        _failedAttempts = attempts;
      });
    }

    if (lockoutString != null) {
      final lockoutTime = DateTime.parse(lockoutString);
      if (DateTime.now().isBefore(lockoutTime)) {
        _startLockoutCountdown(lockoutTime);
      } else {
        _resetLockout();
      }
    }
  }

  Future<void> _handleFailedAttempt() async {
    final prefs = await SharedPreferences.getInstance();
    _failedAttempts++;
    await prefs.setInt(_attemptsKey, _failedAttempts);

    if (_failedAttempts >= 5) {
      final lockoutTime = DateTime.now().add(const Duration(minutes: 5));
      await prefs.setString(_lockoutKey, lockoutTime.toIso8601String());
      _startLockoutCountdown(lockoutTime);
      SnackBarHelper.showError(
        context,
        'Demasiados intentos fallidos. Por seguridad, espera 5 minutos.',
      );
    }
  }

  Future<void> _resetLockout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_attemptsKey);
    await prefs.remove(_lockoutKey);

    if (mounted) {
      setState(() {
        _failedAttempts = 0;
        _lockoutUntil = null;
        _remainingLockoutSeconds = 0;
      });
    }
  }

  void _startLockoutCountdown(DateTime lockoutTime) {
    if (mounted) {
      setState(() {
        _lockoutUntil = lockoutTime;
        _remainingLockoutSeconds = lockoutTime
            .difference(DateTime.now())
            .inSeconds;
      });
    }

    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final remaining = lockoutTime.difference(DateTime.now()).inSeconds;
      if (remaining <= 0) {
        timer.cancel();
        _resetLockout();
      } else if (mounted) {
        setState(() {
          _remainingLockoutSeconds = remaining;
        });
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    pinController.dispose();
    focusNode.dispose();
    super.dispose();
  }

  void _verifyOtp(String pinCode) {
    if (_lockoutUntil != null) {
      SnackBarHelper.showError(
        context,
        'Por favor espera a que termine el bloqueo temporal.',
      );
      return;
    }

    if (pinCode.length == 6) {
      final authState = ref.read(authNotifierProvider);
      ref
          .read(authNotifierProvider.notifier)
          .verifyOtp(
            email: authState.pendingEmail ?? '',
            tokenPin: pinCode,
            fullName: authState.pendingFullName ?? '',
            role: 'patient',
          );
    }
  }

  String _formatLockoutTime() {
    final minutes = (_remainingLockoutSeconds / 60).floor();
    final seconds = _remainingLockoutSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final isLockedOut = _lockoutUntil != null;

    final defaultPinTheme = PinTheme(
      width: 50,
      height: 60,
      textStyle: const TextStyle(
        fontSize: 24,
        color: Color.fromRGBO(30, 60, 87, 1),
        fontWeight: FontWeight.w600,
        fontFamily: 'Satoshi',
      ),
      decoration: BoxDecoration(
        color: isLockedOut ? Colors.grey.shade100 : Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration!.copyWith(
        border: Border.all(color: const Color(0xFF4361EE), width: 1.5),
      ),
    );

    final submittedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration!.copyWith(
        color: isLockedOut
            ? Colors.grey.shade200
            : const Color.fromRGBO(234, 239, 243, 1),
      ),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () {
            ref.read(authNotifierProvider.notifier).resetState();
            context.go('/register');
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isLockedOut
                      ? Colors.red.withOpacity(0.1)
                      : const Color(0xFF4361EE).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isLockedOut
                      ? Icons.lock_clock_outlined
                      : Icons.email_outlined,
                  size: 60,
                  color: isLockedOut ? Colors.red : const Color(0xFF4361EE),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                isLockedOut ? 'Acceso Bloqueado' : 'Verificación de Correo',
                style: const TextStyle(
                  fontFamily: 'Satoshi',
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              if (isLockedOut)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Has superado el límite de intentos (5). Por seguridad, intenta de nuevo en:',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'GeneralSans',
                          fontSize: 14,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _formatLockoutTime(),
                        style: const TextStyle(
                          fontFamily: 'Satoshi',
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: Colors.red,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                )
              else
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: const TextStyle(
                      fontFamily: 'Satoshi',
                      fontSize: 16,
                      color: Colors.grey,
                      height: 1.5,
                    ),
                    children: [
                      const TextSpan(
                        text:
                            'Por favor ingresa el código de 6 dígitos que enviamos a tu correo para activar tu cuenta.',
                      ),
                      TextSpan(
                        text: authState.pendingEmail ?? '',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 48),

              IgnorePointer(
                ignoring: isLockedOut,
                child: Pinput(
                  length: 6,
                  controller: pinController,
                  focusNode: focusNode,
                  defaultPinTheme: defaultPinTheme,
                  focusedPinTheme: focusedPinTheme,
                  submittedPinTheme: submittedPinTheme,
                  separatorBuilder: (index) => const SizedBox(width: 8),
                  onCompleted: (pin) => _verifyOtp(pin),
                ),
              ),

              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: (authState.isLoading || isLockedOut)
                      ? null
                      : () {
                          if (pinController.text.length == 6) {
                            _verifyOtp(pinController.text);
                          } else {
                            SnackBarHelper.showError(
                              context,
                              'Ingresa el código completo',
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF023E8A),
                    disabledBackgroundColor: Colors.grey.shade300,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: authState.isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Verificar Código',
                          style: TextStyle(
                            fontFamily: 'Satoshi',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 32),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '¿No recibiste el código? ',
                    style: TextStyle(
                      fontFamily: 'Satoshi',
                      color: Colors.grey.shade600,
                    ),
                  ),
                  GestureDetector(
                    onTap: (authState.isLoading || isLockedOut)
                        ? null
                        : () {
                            ref
                                .read(authNotifierProvider.notifier)
                                .resendOtp(
                                  ref
                                          .watch(authNotifierProvider)
                                          .pendingEmail ??
                                      '',
                                );
                            SnackBarHelper.showSuccess(
                              context,
                              '¡Código reenviado! Revisa tu bandeja de entrada.',
                            );
                          },
                    child: Text(
                      'Reenviar',
                      style: TextStyle(
                        fontFamily: 'Satoshi',
                        color: isLockedOut
                            ? Colors.grey
                            : const Color(0xFF4361EE),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
