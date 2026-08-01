import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../providers/auth_notifier.dart';
import '../../common/widgets/snackbar_helper.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _oldPasswordController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    // NO reseteamos el estado aquí porque borraríamos el flag de recuperación
    // que el Router acaba de detectar.

    ref.listenManual(authNotifierProvider, (previous, next) {
      // Manejo de Errores
      if (next.errorMessage != null &&
          !next.isLoading &&
          previous?.errorMessage != next.errorMessage) {
        SnackBarHelper.showError(context, next.errorMessage!);
      }

      // Éxito al enviar correo de recuperación
      if (next.isResetEmailSent &&
          !next.isLoading &&
          previous?.isLoading == true) {
        SnackBarHelper.showSuccess(
          context,
          'Se ha enviado un correo para restablecer tu contraseña',
        );
        ref.read(authNotifierProvider.notifier).resetState();
      }

      // Éxito al actualizar contraseña
      if (next.isPasswordUpdateSuccess &&
          !next.isLoading &&
          previous?.isLoading == true) {
        SnackBarHelper.showSuccess(
          context,
          'Tu contraseña ha sido actualizada correctamente',
        );

        // Flujo de seguridad: Limpiar estado de recuperación y redirigir
        Future.delayed(const Duration(seconds: 2), () {
          if (!mounted) return;

          final isRecoveryPath =
              GoRouterState.of(context).uri.path == '/reset-password';

          if (isRecoveryPath) {
            // Si venía de recuperación (por link o desde afuera), deslogueamos
            ref.read(authNotifierProvider.notifier).logout();
            context.go('/login');
          } else {
            // Si fue un cambio normal (/change-password), volvemos al perfil
            ref.read(authNotifierProvider.notifier).clearRecoveryState();
            context.pop();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    // Determinar el modo basándonos en la ruta para evitar parpadeos durante el loading
    final isRecoveryMode =
        GoRouterState.of(context).uri.path == '/reset-password';

    return Scaffold(
      backgroundColor: const Color(0xFF023E8A),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/fondoFortget.png',
              fit: BoxFit.cover,
            ),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () {
                      if (context.canPop()) {
                        Navigator.pop(context);
                      } else {
                        context.go('/login');
                      }
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isRecoveryMode
                            ? 'Nueva Contraseña'
                            : 'Cambiar Contraseña',
                        style: const TextStyle(
                          fontFamily: 'Satoshi',
                          fontSize: 28,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isRecoveryMode
                            ? 'Crea una contraseña segura para proteger tu cuenta'
                            : 'Ingresa tu contraseña actual y la nueva para actualizar tus credenciales',
                        style: const TextStyle(
                          fontFamily: 'Satoshi',
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: Colors.white70,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 48),
                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                    ),
                    padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
                    child: Form(
                      key: _formKey,
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (!isRecoveryMode) ...[
                              _buildInputLabel('Contraseña Actual'),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _oldPasswordController,
                                obscureText: !_isPasswordVisible,
                                decoration: _buildInputDecoration(
                                  hint: 'Tu clave actual',
                                ),
                                validator: (value) =>
                                    value == null || value.isEmpty
                                    ? 'Campo requerido'
                                    : null,
                              ),
                              const SizedBox(height: 12),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: authState.isSendingEmail
                                      ? null
                                      : () {
                                          final email = ref
                                              .read(authStateProvider)
                                              .value
                                              ?.email;
                                          if (email != null) {
                                            ref
                                                .read(
                                                  authNotifierProvider.notifier,
                                                )
                                                .sendPasswordResetEmail(email);
                                          } else {
                                            SnackBarHelper.showError(
                                              context,
                                              'No se pudo encontrar tu correo.',
                                            );
                                          }
                                        },
                                  child: authState.isSendingEmail
                                      ? const SizedBox(
                                          height: 14,
                                          width: 14,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Color(0xFF023E8A),
                                          ),
                                        )
                                      : const Text(
                                          '¿Olvidaste tu contraseña?',
                                          style: TextStyle(
                                            color: Color(0xFF023E8A),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
                            _buildInputLabel(
                              isRecoveryMode
                                  ? 'Nueva Contraseña'
                                  : 'Nueva Contraseña',
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: !_isPasswordVisible,
                              decoration: _buildInputDecoration(
                                hint: 'Mínimo 6 caracteres',
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _isPasswordVisible
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                    color: Colors.grey,
                                  ),
                                  onPressed: () => setState(
                                    () => _isPasswordVisible =
                                        !_isPasswordVisible,
                                  ),
                                ),
                              ),
                              validator: (value) => value!.length < 6
                                  ? 'Mínimo 6 caracteres'
                                  : null,
                            ),
                            const SizedBox(height: 24),
                            _buildInputLabel('Confirmar Nueva Contraseña'),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _confirmPasswordController,
                              obscureText: !_isPasswordVisible,
                              decoration: _buildInputDecoration(
                                hint: 'Repite tu nueva contraseña',
                              ),
                              validator: (value) =>
                                  value != _passwordController.text
                                  ? 'Las contraseñas no coinciden'
                                  : null,
                            ),
                            const SizedBox(height: 32),
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                onPressed: authState.isLoading
                                    ? null
                                    : _handleResetPassword,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF023E8A),
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
                                    : Text(
                                        isRecoveryMode
                                            ? 'Guardar y continuar'
                                            : 'Actualizar contraseña',
                                        style: const TextStyle(
                                          fontFamily: 'Satoshi',
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.white,
                                        ),
                                      ),
                              ),
                            ),
                          ],
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

  Widget _buildInputLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: 'Satoshi',
        fontSize: 14,
        color: Colors.grey.shade700,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String hint,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      suffixIcon: suffixIcon,
      hintStyle: TextStyle(
        fontFamily: 'Satoshi',
        color: Colors.grey.shade400,
        fontSize: 14,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF4361EE), width: 1.5),
      ),
    );
  }

  void _handleResetPassword() {
    if (_formKey.currentState!.validate()) {
      final isRecoveryMode = ref.read(authNotifierProvider).isPasswordRecovery;
      ref
          .read(authNotifierProvider.notifier)
          .updatePassword(
            _passwordController.text.trim(),
            oldPassword: isRecoveryMode
                ? null
                : _oldPasswordController.text.trim(),
          );
    }
  }
}
