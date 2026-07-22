import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StorageService {
  // Singleton
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  final _secureStorage = const FlutterSecureStorage();

  // Keys
  static const String _tokenKey = 'auth_token';

  /// Guardar valor genérico
  Future<void> saveValue(String key, String value) async {
    await _secureStorage.write(
      key: key,
      value: value,
      aOptions: _getAndroidOptions(),
      iOptions: _getIOSOptions(),
    );
  }

  /// Leer valor genérico
  Future<String?> getValue(String key) async {
    return await _secureStorage.read(
      key: key,
      aOptions: _getAndroidOptions(),
      iOptions: _getIOSOptions(),
    );
  }

  /// Borrar valor genérico
  Future<void> deleteValue(String key) async {
    await _secureStorage.delete(
      key: key,
      aOptions: _getAndroidOptions(),
      iOptions: _getIOSOptions(),
    );
  }

  /// Guardar token de manera segura
  Future<void> saveToken(String token) async {
    await saveValue(_tokenKey, token);
  }

  /// Leer token
  Future<String?> getToken() async {
    return await getValue(_tokenKey);
  }

  /// Borrar token (Logout)
  Future<void> deleteToken() async {
    await deleteValue(_tokenKey);
  }

  // Opciones de configuración para Android (EncryptedSharedPreferences)
  AndroidOptions _getAndroidOptions() =>
      const AndroidOptions(encryptedSharedPreferences: true);

  // Opciones de configuración para iOS
  IOSOptions _getIOSOptions() =>
      const IOSOptions(accessibility: KeychainAccessibility.first_unlock);
}
