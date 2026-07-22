import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/providers/auth_notifier.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'health_connect_sync_screen.dart';
import '../providers/personal_info_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final user = authState.value;

    // Datos REALES del usuario
    final String userName = (user?.fullName ?? 'Usuario')
        .trim()
        .split(RegExp(r'\s+'))
        .first;
    final String userEmail = user?.email ?? "sin-email@example.com";

    // Detectar método de login real desde Supabase
    final supabaseUser = Supabase.instance.client.auth.currentUser;
    final String provider =
        supabaseUser?.appMetadata['provider'] as String? ?? 'email';
    final bool isGoogle = provider == 'google';
    final String loginMethod = isGoogle ? "Google" : "Email";

    // Obtener información del perfil (incluyendo doctor vinculado)
    final personalInfoState = ref.watch(personalInfoProvider);
    final profile = personalInfoState.profile;
    final String? linkedDoctorName = profile?.linkedDoctorName;
    final String? linkedDoctorCode = profile?.linkedDoctorCode;
    final bool hasDoctor = linkedDoctorName != null;
    
    print('🔍 DEBUG: ProfileScreen - hasDoctor: $hasDoctor, Name: $linkedDoctorName');

    final String avatarUrl =
        'https://api.dicebear.com/9.x/initials/svg?seed=${user?.fullName ?? 'Usuario'}&backgroundColor=${user?.avatarBackground ?? '023e8a'}';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(
          left: 24.0,
          right: 24.0,
          bottom:
              120.0, // Aumentado para evitar solapamiento con botones del sistema
          top: kToolbarHeight + 48.0, // Espacio para la barra de cristal
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Avatar del usuario con Edición
            Center(
              child: Stack(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(
                        int.parse(
                          'FF${user?.avatarBackground ?? '023e8a'}',
                          radix: 16,
                        ),
                      ),
                      border: Border.all(
                        color: const Color(0xFF023E8A),
                        width: 2,
                      ),
                    ),
                    child: ClipOval(
                      child: SvgPicture.network(
                        avatarUrl,
                        fit: BoxFit.cover,
                        placeholderBuilder: (context) =>
                            const CircularProgressIndicator(),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: () {
                        context.push('/edit-avatar');
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF023E8A),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.edit,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Nombre del usuario
            Text(
              userName,
              style: const TextStyle(
                fontFamily: 'Satoshi',
                fontSize: 24,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),

            const SizedBox(height: 8),

            // Email del usuario
            Text(
              userEmail,
              style: TextStyle(
                fontFamily: 'Satoshi',
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),

            const SizedBox(height: 12),

            // Badge del método de login
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: loginMethod == "Google"
                    ? Colors.red.shade50
                    : Colors.blue.shade50,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: loginMethod == "Google"
                      ? Colors.red.shade200
                      : Colors.blue.shade200,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    loginMethod == "Google" ? Icons.g_mobiledata : Icons.email,
                    size: 20,
                    color: loginMethod == "Google"
                        ? Colors.red.shade700
                        : Colors.blue.shade700,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    loginMethod == "Google"
                        ? "Cuenta de Google"
                        : "Email y Contraseña",
                    style: TextStyle(
                      fontFamily: 'Satoshi',
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: loginMethod == "Google"
                          ? Colors.red.shade700
                          : Colors.blue.shade700,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // Sección: Cuenta
            _buildSectionTitle("Cuenta"),
            const SizedBox(height: 16),

            _buildOptionCard(
              icon: Icons.person_outline,
              title: "Información Personal",
              subtitle: "Edita tu altura, edad y mejor PEF",
              onTap: () {
                context.push('/personal-info');
              },
            ),

            const SizedBox(height: 12),

            _buildOptionCard(
              icon: Icons.medication_outlined,
              title: "Mis Medicamentos",
              subtitle: "Gestiona tu tratamiento y recordatorios",
              onTap: () {
                context.push('/medications');
              },
            ),

            const SizedBox(height: 12),

            _buildOptionCard(
              icon: hasDoctor ? Icons.verified_user_outlined : Icons.medical_services_outlined,
              title: hasDoctor ? "Mi Doctor" : "Vincular Doctor",
              subtitle: hasDoctor 
                ? "Dr. $linkedDoctorName • Toca para ver info" 
                : "Ingresa el código proporcionado por tu médico",
              onTap: () {
                if (hasDoctor) {
                  _showMyDoctorDialog(
                    context, 
                    ref, 
                    linkedDoctorName, 
                    linkedDoctorCode!,
                    profile?.linkedDoctorSpecialty,
                    profile?.linkedDoctorEmail,
                  );
                } else {
                  _showLinkDoctorDialog(context, ref);
                }
              },
            ),

            const SizedBox(height: 12),

            _buildOptionCard(
              icon: Icons.lock_outline,
              title: "Cambiar Contraseña",
              subtitle: "Actualiza tu contraseña de acceso",
              onTap: () {
                context.push('/change-password');
              },
              isDisabled: loginMethod == "Google", // Deshabilitado si es Google
            ),

            const SizedBox(height: 12),

            _buildOptionCard(
              icon: Icons.security_rounded,
              title: "Seguridad 2FA",
              subtitle: "Configura Google Authenticator",
              onTap: () {
                context.push('/mfa-setup');
              },
            ),

            const SizedBox(height: 32),

            // Sección: Dispositivos
            _buildSectionTitle("Dispositivos"),
            const SizedBox(height: 16),

            _buildOptionCard(
              icon: Icons.contacts_outlined,
              title: "Contactos",
              subtitle: "Personas a notificar en caso de emergencia",
              onTap: () {
                context.push('/emergency-contacts');
              },
            ),

            const SizedBox(height: 12),

            _buildOptionCard(
              icon: Icons.health_and_safety_outlined,
              title: "Sincronización Health Connect",
              subtitle: "Estado de permisos y datos del reloj",
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const HealthConnectSyncScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: 32),

            // Sección: Preferencias
            _buildSectionTitle("Preferencias"),
            const SizedBox(height: 16),

            _buildOptionCard(
              icon: Icons.notifications_outlined,
              title: "Notificaciones",
              subtitle: "Configura alertas y recordatorios",
              onTap: () {
                context.push('/notifications');
              },
            ),

            const SizedBox(height: 12),

            _buildOptionCard(
              icon: Icons.privacy_tip_outlined,
              title: "Privacidad y Permisos",
              subtitle: "Gestiona accesos del teléfono",
              onTap: () {
                context.push('/permissions');
              },
            ),

            const SizedBox(height: 32),

            // Sección: Soporte
            _buildSectionTitle("Soporte"),
            const SizedBox(height: 16),

            _buildOptionCard(
              icon: Icons.help_outline,
              title: "Ayuda y Soporte",
              subtitle: "Preguntas frecuentes y contacto",
              onTap: () {
                context.push('/help-support');
              },
            ),

            const SizedBox(height: 12),

            _buildOptionCard(
              icon: Icons.info_outline,
              title: "Acerca de",
              subtitle: "Versión de la app y términos",
              onTap: () {
                context.push('/about');
              },
            ),

            const SizedBox(height: 40),

            // Botón de Cerrar Sesión
            SizedBox(
              width: double.infinity,
              height: 56,
              child: OutlinedButton(
                onPressed: () =>
                    ref.read(authNotifierProvider.notifier).logout(),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.red.shade400, width: 1.5),
                  foregroundColor: Colors.red.shade700,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Cerrar Sesión',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Satoshi',
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(
          fontFamily: 'Satoshi',
          fontSize: 18,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildOptionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDisabled = false,
  }) {
    return GestureDetector(
      onTap: isDisabled ? null : onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDisabled ? Colors.grey.shade100 : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDisabled ? Colors.grey.shade300 : Colors.grey.shade200,
            width: 1,
          ),
          boxShadow: isDisabled
              ? []
              : [
                  BoxShadow(
                    color: Colors.grey.shade100,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDisabled
                    ? Colors.grey.shade200
                    : const Color(0xFF023E8A).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: isDisabled
                    ? Colors.grey.shade400
                    : const Color(0xFF023E8A),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'Satoshi',
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: isDisabled ? Colors.grey.shade500 : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: 'GeneralSans',
                      fontSize: 14,
                      color: isDisabled
                          ? Colors.grey.shade400
                          : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: isDisabled ? Colors.grey.shade400 : Colors.grey.shade400,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  void _showMyDoctorDialog(
    BuildContext context, 
    WidgetRef ref, 
    String name, 
    String code,
    String? specialty,
    String? email,
  ) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.verified_user_outlined, color: Color(0xFF023E8A)),
              SizedBox(width: 10),
              Text(
                'Mi Doctor',
                style: TextStyle(fontFamily: 'Satoshi', fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Estás vinculado actualmente con:',
                style: TextStyle(fontFamily: 'Satoshi', fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              Text(
                'Dr. $name',
                style: const TextStyle(
                  fontFamily: 'Satoshi',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              if (specialty != null && specialty.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  specialty,
                  style: TextStyle(
                    fontFamily: 'Satoshi',
                    fontSize: 14,
                    color: Colors.blue.shade800,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              
              // Fila de Código
              Row(
                children: [
                  const Icon(Icons.pin_outlined, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    'Código: $code',
                    style: const TextStyle(fontFamily: 'Satoshi', fontSize: 14, color: Colors.black54),
                  ),
                ],
              ),
              
              if (email != null && email.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.email_outlined, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        email,
                        style: const TextStyle(
                          fontFamily: 'Satoshi', 
                          fontSize: 14, 
                          color: Colors.black54,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 8),
              const Text(
                'Tu doctor puede ver tu historial clínico y tendencias de PEF para darte un mejor seguimiento.',
                style: TextStyle(fontFamily: 'Satoshi', fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cerrar', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                _showLinkDoctorDialog(context, ref, isChanging: true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF023E8A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Cambiar Doctor'),
            ),
          ],
        );
      },
    );
  }

  void _showLinkDoctorDialog(BuildContext context, WidgetRef ref, {bool isChanging = false}) {
    final TextEditingController controller = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(
                isChanging ? 'Cambiar de Médico' : 'Vincular Doctor',
                style: const TextStyle(fontFamily: 'Satoshi', fontWeight: FontWeight.bold),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isChanging 
                      ? 'Ingresa el nuevo Código Vinculante para cambiar de médico. El doctor anterior dejará de ver tu historial.'
                      : 'Pídele a tu médico su Código Vinculante e ingrésalo aquí para compartir automáticamente tu historial clínico.',
                    style: const TextStyle(fontFamily: 'Satoshi', fontSize: 14, color: Colors.black87),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      labelText: 'Código del Doctor',
                      hintText: 'Ej: DOC-XXXXXX',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.pin_outlined),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          final code = controller.text.trim();
                          if (code.isEmpty) return;

                          setState(() => isLoading = true);

                          try {
                            final message = await ref
                                .read(authNotifierProvider.notifier)
                                .assignDoctor(code);

                            if (ctx.mounted) {
                              Navigator.of(ctx).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(message),
                                  backgroundColor: Colors.green.shade600,
                                ),
                              );
                            }
                          } catch (e) {
                            setState(() => isLoading = false);
                            if (ctx.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(e.toString()),
                                  backgroundColor: Colors.red.shade600,
                                ),
                              );
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF023E8A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(isChanging ? 'Cambiar' : 'Vincular', style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
