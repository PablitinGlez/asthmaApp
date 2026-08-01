class AuthException implements Exception {
  final String message;
  AuthException(this.message);

  @override
  String toString() => message;
}

class FirebaseAuthErrorTranslator {
  static String translate(String errorCode) {
    switch (errorCode) {
      case 'email-already-in-use':
        return 'No se pudo completar el registro. Verifica tus datos';
      case 'invalid-email':
        return 'El correo electrónico no es válido';
      case 'operation-not-allowed':
        return 'Operación no permitida. Contacta a soporte';
      case 'weak-password':
        return 'La contraseña es muy débil. Usa al menos 6 caracteres';

      case 'user-disabled':
        return 'Esta cuenta ha sido deshabilitada';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Correo o contraseña incorrectos';

      case 'network-request-failed':
        return 'Error de conexión. Verifica tu internet';
      case 'too-many-requests':
        return 'Demasiados intentos. Espera un momento';

      case 'requires-recent-login':
        return 'Por seguridad, vuelve a iniciar sesión';
      default:
        return 'Error al autenticarse. Intenta de nuevo';
    }
  }

  static bool isEmailAlreadyInUse(String errorCode) {
    return errorCode == 'email-already-in-use';
  }

  static bool isInvalidCredentials(String errorCode) {
    return errorCode == 'user-not-found' ||
        errorCode == 'wrong-password' ||
        errorCode == 'invalid-credential';
  }
}
