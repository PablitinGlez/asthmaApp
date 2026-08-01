// Excepción personalizada para errores de autenticación
class AuthException implements Exception {
  final String message;
  AuthException(this.message);

  @override
  String toString() => message; // Sin prefijo "Exception:"
}

// Helper para traducir errores de Firebase Auth a español
class FirebaseAuthErrorTranslator {
  // Traduce códigos de error de Firebase a mensajes en español
  static String translate(String errorCode) {
    switch (errorCode) {
      // Errores de registro - GENÉRICOS por seguridad
      case 'email-already-in-use':
        return 'No se pudo completar el registro. Verifica tus datos';
      case 'invalid-email':
        return 'El correo electrónico no es válido';
      case 'operation-not-allowed':
        return 'Operación no permitida. Contacta a soporte';
      case 'weak-password':
        return 'La contraseña es muy débil. Usa al menos 6 caracteres';

      // Errores de login - GENÉRICOS por seguridad
      case 'user-disabled':
        return 'Esta cuenta ha sido deshabilitada';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Correo o contraseña incorrectos'; // Genérico

      // Errores de red
      case 'network-request-failed':
        return 'Error de conexión. Verifica tu internet';
      case 'too-many-requests':
        return 'Demasiados intentos. Espera un momento';

      // Errores generales
      case 'requires-recent-login':
        return 'Por seguridad, vuelve a iniciar sesión';
      default:
        return 'Error al autenticarse. Intenta de nuevo';
    }
  }

  // Verifica si un error indica que el email ya existe
  static bool isEmailAlreadyInUse(String errorCode) {
    return errorCode == 'email-already-in-use';
  }

  // Verifica si un error indica credenciales incorrectas
  static bool isInvalidCredentials(String errorCode) {
    return errorCode == 'user-not-found' ||
        errorCode == 'wrong-password' ||
        errorCode == 'invalid-credential';
  }
}
