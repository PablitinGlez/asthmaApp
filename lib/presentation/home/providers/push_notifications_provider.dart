import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import 'dart:io';

class PushNotificationsNotifier extends Notifier<void> {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  @override
  void build() {
    ref.listen(authStateProvider, (previous, next) {
      if (next.value != null && previous?.value == null) {
        _getToken();
      }
    });

    _initNotifications();
  }

  Future<void> _initNotifications() async {
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      _getToken();
    }

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {});

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {});
  }

  Future<void> _getToken() async {
    try {
      String? token = await _fcm.getToken();
      if (token != null) {
        _syncTokenWithBackend(token);
      }
      
      _fcm.onTokenRefresh.listen(_syncTokenWithBackend);
    } catch (e) {}
  }

  Future<void> _syncTokenWithBackend(String fcmToken) async {
    final authState = ref.read(authStateProvider);
    final user = authState.value;
    
    if (user != null) {
      try {
        await ref.read(authRepositoryProvider).updateFcmToken(fcmToken: fcmToken);
      } catch (e) {}
    }
  }
}

final pushNotificationsProvider = NotifierProvider<PushNotificationsNotifier, void>(
  PushNotificationsNotifier.new,
);
