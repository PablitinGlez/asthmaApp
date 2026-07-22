import 'package:asthmaapp/presentation/home/screens/home_screen.dart';
import 'package:flutter/material.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  /// TODO: Implementar lógica de inicialización
  /// - Verificar si el usuario tiene sesión activa (Firebase Auth)
  /// - Cargar configuración local (Isar/SharedPreferences)
  /// - Pre-cargar datos críticos si es necesario
  /// - Navegar a la pantalla correspondiente (Login o Home)
  Future<void> _initializeApp() async {
    // Simular tiempo de carga (eliminar después)
    await Future.delayed(const Duration(seconds: 2));

    // TODO: Verificar autenticación
    // final isAuthenticated = await _checkAuthentication();

    // Navegación temporal al HomeScreen (cambiar después según autenticación)
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }

    // TODO: Implementar navegación condicional
    // if (mounted) {
    //   if (isAuthenticated) {
    //     Navigator.pushReplacement(
    //       context,
    //       MaterialPageRoute(builder: (_) => const HomeScreen()),
    //     );
    //   } else {
    //     Navigator.pushReplacement(
    //       context,
    //       MaterialPageRoute(builder: (_) => const LoginScreen()),
    //     );
    //   }
    // }
  }

  /// TODO: Implementar verificación de autenticación
  // Future<bool> _checkAuthentication() async {
  //   // Aquí verificarás si hay un token/sesión activa
  //   return false;
  // }

  /// TODO: Implementar precarga de datos
  // Future<void> _preloadData() async {
  //   // Aquí cargarás datos críticos de la base de datos local
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 20),
            Text(
              'Cargando...',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
            ),
          ],
        ),
      ),
    );
  }
}
