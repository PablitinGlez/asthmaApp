import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/foundation.dart';
import 'package:flutter_timezone/flutter_timezone.dart';

class LocalNotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    tz.initializeTimeZones();
    final String timeZoneName = (await FlutterTimezone.getLocalTimezone()).identifier;
    tz.setLocalLocation(tz.getLocation(timeZoneName));
    
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _notificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        debugPrint('Notificación presionada: ${details.payload}');
      },
    );
  }

  static Future<void> scheduleMedicationReminder({
    required int id,
    required String name,
    required DateTime scheduledDate,
    List<int>? daysOfWeek,
  }) async {
    print('🔔 Notifications: Intentando agendar recordatorio para "$name" el $scheduledDate');
    
    // Si la fecha ya pasó, no agendamos
    if (scheduledDate.isBefore(DateTime.now())) {
      print('⚠️ Notifications: La fecha ya pasó, saltando agendamiento.');
      return;
    }

    try {
      final tzDate = tz.TZDateTime.from(scheduledDate, tz.local);

      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'medication_reminders_v2',
        'Recordatorios de Medicamentos',
        channelDescription: 'Notificaciones para recordarte tomar tu medicina',
        importance: Importance.max,
        priority: Priority.high,
        ticker: 'ticker',
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails platformDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      if (daysOfWeek == null || daysOfWeek.isEmpty || daysOfWeek.length == 7) {
        // Notificación diaria
        print('📅 Notifications: Configurando alarma DIARIA con ID: $id a las ${tzDate.hour}:${tzDate.minute}');
        await _notificationsPlugin.zonedSchedule(
          id: id,
          title: '💊 Hora de tu medicina',
          body: 'Es momento de tomar: $name',
          scheduledDate: tzDate,
          notificationDetails: platformDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.time,
          payload: 'medication_$id',
        );
      } else {
        // Notificación específica por días de la semana
        print('📅 Notifications: Configurando alarma semanal para los días: $daysOfWeek');
        for (final dayIndex in daysOfWeek) {
          tz.TZDateTime scheduledDay = _nextInstanceOfDay(tzDate, dayIndex);
          
          print('   - Agendando para el día $dayIndex con ID: ${id * 10 + dayIndex}');
          await _notificationsPlugin.zonedSchedule(
            id: id * 10 + dayIndex,
            title: '💊 Recordatorio: $name',
            body: 'Toca dosis de tu medicamento',
            scheduledDate: scheduledDay,
            notificationDetails: platformDetails,
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
            payload: 'medication_$id',
          );
        }
      }
      print('✅ Notifications: Alarma(s) configurada(s) correctamente.');
    } catch (e) {
      print('❌ Notifications: Error crítico al agendar recordatorio: $e');
      rethrow; // Re-lanzamos para que el try-catch del UI lo capture
    }
  }

  static tz.TZDateTime _nextInstanceOfDay(tz.TZDateTime scheduledDate, int dayIndex) {
    tz.TZDateTime scheduled = scheduledDate;
    while (scheduled.weekday != dayIndex) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  static Future<void> cancelMedicationReminders(int id) async {
    await _notificationsPlugin.cancel(id: id);
    for (int i = 1; i <= 7; i++) {
      await _notificationsPlugin.cancel(id: id * 10 + i);
    }
  }

  static Future<void> scheduleTestOneMinute() async {
    final tzDate = tz.TZDateTime.now(tz.local).add(const Duration(minutes: 1));
    print('⏳ TEST: Agendando alarma 100% aislada para las: ${tzDate.hour}:${tzDate.minute}:${tzDate.second}');
    
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'medication_reminders_v2',
      'Recordatorios de Medicamentos',
      channelDescription: 'Notificaciones para recordarte tomar tu medicina',
      importance: Importance.max,
      priority: Priority.high,
    );
    const NotificationDetails platformDetails = NotificationDetails(android: androidDetails);

    await _notificationsPlugin.zonedSchedule(
      id: 88888,
      title: '⏰ ¡Alarma de 1 minuto!',
      body: 'Esto prueba que el encolamiento en segundo plano SÍ funciona.',
      scheduledDate: tzDate,
      notificationDetails: platformDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
    print('✅ TEST: ¡Alarma programada, minimiza la app ahora mismo!');
  }

  static Future<void> showWelcomeNotification(String name) async {
    print('🎉 Notifications: Preparando notificación de bienvenida para $name');
    try {
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'welcome_notifications',
        'Bienvenida',
        channelDescription: 'Notificaciones de bienvenida al registrarse',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails platformDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notificationsPlugin.show(
        id: 0,
        title: '¡Hola $name! 👋',
        body: 'Bienvenido a Asthma Predictor, estamos aquí para cuidarte.',
        notificationDetails: platformDetails,
        payload: 'welcome',
      );
      print('✅ Notifications: Notificación de bienvenida enviada con éxito.');
    } catch (e) {
      print('❌ Notifications: Error al enviar bienvenida: $e');
    }
  }

  static Future<void> cancelAll() async {
    await _notificationsPlugin.cancelAll();
  }
}
