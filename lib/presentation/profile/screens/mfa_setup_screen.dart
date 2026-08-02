import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pinput/pinput.dart';
import '../../auth/providers/auth_provider.dart';

class MfaSetupScreen extends ConsumerStatefulWidget {
  const MfaSetupScreen({super.key});

  @override
  ConsumerState<MfaSetupScreen> createState() => _MfaSetupScreenState();
}

class _MfaSetupScreenState extends ConsumerState<MfaSetupScreen> {
  bool _isLoading = true;
  bool _isVerifying = false;
  String? _errorMessage;

  String? _factorId;
  String? _qrCodeUri;
  final TextEditingController _pinController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _startEnrollment();
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _startEnrollment() async {
    try {
      final repository = ref.read(authRepositoryProvider);

      
      final aal = await repository.getAuthenticatorAssuranceLevel();
      if (aal.nextLevel.toString().contains('aal2')) {
        if (mounted) {
          setState(() {
            _errorMessage = 'El 2FA ya se encuentra activo en esta cuenta.';
            _isLoading = false;
          });
        }
        return;
      }

      
      try {
        final factors = await repository.listFactors();
        for (final factor in factors) {
          if (factor.status == 'unverified') {
            await repository.unenrollMfa(factor.id);
          }
        }
      } catch (e) {
        print('Error limpiando factores previos: $e');
      }

      final AuthMFAEnrollResponse response = await repository.enrollMfa();

      if (mounted) {
        setState(() {
          _factorId = response.id;
          _qrCodeUri = response.totp?.uri;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error al generar código 2FA: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _verifyCode(String code) async {
    if (_factorId == null) return;

    setState(() {
      _errorMessage = null;
      _isVerifying = true;
    });

    try {
      final repository = ref.read(authRepositoryProvider);
      await repository.challengeAndVerifyMfa(factorId: _factorId!, code: code);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡2FA Activado exitosamente! '),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Código incorrecto. Intenta de nuevo.';
          _isVerifying = false;
        });
        _pinController.clear();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF023E8A)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.black87,
          ),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Configurar 2FA',
          style: TextStyle(
            fontFamily: 'Satoshi',
            color: Colors.black87,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          children: [
            const Icon(
              Icons.security_rounded,
              size: 64,
              color: Color(0xFF023E8A),
            ),
            const SizedBox(height: 24),
            const Text(
              'Aumenta la seguridad de tu cuenta',
              style: TextStyle(
                fontFamily: 'Satoshi',
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              '1. Descarga Google Authenticator o Authy en tu celular.\n2. Escanea el siguiente Código QR.',
              style: TextStyle(
                fontFamily: 'GeneralSans',
                fontSize: 15,
                color: Colors.black54,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            if (_errorMessage != null)
              Container(
                margin: const EdgeInsets.only(bottom: 24),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      color: Colors.red.shade700,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(
                          fontFamily: 'GeneralSans',
                          color: Colors.red.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            if (_qrCodeUri != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: QrImageView(
                  data: _qrCodeUri!,
                  version: QrVersions.auto,
                  size: 200.0,
                ),
              ),
              const SizedBox(height: 32),

              const Text(
                '3. Ingresa el código de 6 dígitos de tu app para confirmar:',
                style: TextStyle(
                  fontFamily: 'GeneralSans',
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              Pinput(
                controller: _pinController,
                length: 6,
                onCompleted: _isVerifying ? null : _verifyCode,
                defaultPinTheme: PinTheme(
                  width: 50,
                  height: 56,
                  textStyle: const TextStyle(
                    fontSize: 22,
                    color: Colors.black87,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Satoshi',
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                ),
                focusedPinTheme: PinTheme(
                  width: 50,
                  height: 56,
                  textStyle: const TextStyle(
                    fontSize: 22,
                    color: const Color(0xFF023E8A),
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Satoshi',
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF023E8A),
                      width: 2,
                    ),
                  ),
                ),
              ),

              if (_isVerifying) ...[
                const SizedBox(height: 24),
                const CircularProgressIndicator(color: Color(0xFF023E8A)),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
