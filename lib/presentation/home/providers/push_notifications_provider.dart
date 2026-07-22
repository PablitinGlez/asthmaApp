import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import 'dart:io';

class PushNotificationsNotifier extends Notifier<void> {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  @override
  void build() {
    // Escuchar cambios de autenticación para sincronizar el token en cuanto el usuario entre
    ref.listen(authStateProvider, (previous, next) {
      if (next.value != null && previous?.value == null) {
        print('🔐 [PUSH] Sesión detectada. Iniciando obtención/sincronización de token...');
        _getToken();
      }
    });

    // Al inicializar, configuramos los listeners de Firebase
    _initNotifications();
  }

  Future<void> _initNotifications() async {
    // 1. Pedir permisos
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('🔔 [PUSH] Permisos concedidos');
      _getToken();
    } else {
      print('🔕 [PUSH] Permisos denegados');
    }

    // 2. Escuchar mensajes en primer plano
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('📩 [PUSH] Mensaje recibido en primer plano: ${message.notification?.title}');
      // Aquí podrías mostrar un snackbar o actualizar la UI
    });

    // 3. Manejar clics (si la app estaba abierta)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('🔗 [PUSH] Usuario hizo clic en la notificación');
    });
  }

  Future<void> _getToken() async {
    try {
      String? token = await _fcm.getToken();
      if (token != null) {
        print('🔑 [PUSH] Token obtenido: $token');
        _syncTokenWithBackend(token);
      }
      
      // Escuchar si el token cambia por Google
      _fcm.onTokenRefresh.listen(_syncTokenWithBackend);
    } catch (e) {
      print('❌ [PUSH] Error al obtener token: $e');
    }
  }

  Future<void> _syncTokenWithBackend(String fcmToken) async {
    final authState = ref.read(authStateProvider);
    final user = authState.value;
    
    if (user != null) {
      print('📡 [PUSH] Sincronizando token con backend...');
      try {
        await ref.read(authRepositoryProvider).updateFcmToken(fcmToken: fcmToken);
        print('✅ [PUSH] Token sincronizado correctamente');
      } catch (e) {
        print('⚠️ [PUSH] Error al sincronizar token: $e');
      }
    }
  }
}

final pushNotificationsProvider = NotifierProvider<PushNotificationsNotifier, void>(
  PushNotificationsNotifier.new,
);
