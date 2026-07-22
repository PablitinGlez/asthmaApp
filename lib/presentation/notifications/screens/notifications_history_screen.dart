import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class NotificationsHistoryScreen extends ConsumerWidget {
  const NotificationsHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<MockNotification> dummyNotifications = [
      MockNotification(
        title: '¡Próxima dosis ahora!',
        description: 'Toca para registrar tu dosis de Salbutamol (2 disparos).',
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
        type: NotificationType.reminder,
      ),
      MockNotification(
        title: 'Calidad del aire: Moderada',
        description: 'Se detectó un aumento de polen en tu zona. Mantén las ventanas cerradas.',
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        type: NotificationType.alert,
      ),
      MockNotification(
        title: 'Tip de Salud',
        description: 'Realizar ejercicios de respiración hoy puede mejorar tu capacidad pulmonar.',
        timestamp: DateTime.now().subtract(const Duration(hours: 5)),
        type: NotificationType.tip,
      ),
      MockNotification(
        title: 'Recordatorio de Medición',
        description: 'Es momento de realizar tu medición de PEF de la tarde.',
        timestamp: DateTime.now().subtract(const Duration(hours: 8)),
        type: NotificationType.reminder,
      ),
      MockNotification(
        title: 'Resumen Semanal Listo',
        description: 'Tu tendencia de la semana muestra una mejora del 12% en tu estabilidad.',
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
        type: NotificationType.tip,
      ),
      MockNotification(
        title: 'Alerta de Riesgo',
        description: 'Tu última medición estuvo cerca de la zona amarilla. Descansa un poco.',
        timestamp: DateTime.now().subtract(const Duration(days: 1, hours: 4)),
        type: NotificationType.alert,
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87, size: 20),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Notificaciones',
          style: TextStyle(
            fontFamily: 'Satoshi',
            color: Colors.black87,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Color(0xFF023E8A)),
            onPressed: () => context.push('/notifications/settings'),
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        itemCount: dummyNotifications.length,
        itemBuilder: (context, index) {
          final notification = dummyNotifications[index];
          return _NotificationTile(notification: notification);
        },
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final MockNotification notification;

  const _NotificationTile({required this.notification});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Barra lateral de color según el tipo
              Container(
                width: 6,
                color: notification.color,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Icono con fondo circular
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: notification.color.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          notification.icon,
                          color: notification.color,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Contenido de texto
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  notification.typeName,
                                  style: TextStyle(
                                    fontFamily: 'Satoshi',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: notification.color,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                Text(
                                  notification.timeLabel,
                                  style: TextStyle(
                                    fontFamily: 'GeneralSans',
                                    fontSize: 11,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              notification.title,
                              style: const TextStyle(
                                fontFamily: 'Satoshi',
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              notification.description,
                              style: TextStyle(
                                fontFamily: 'GeneralSans',
                                fontSize: 14,
                                color: Colors.grey.shade600,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum NotificationType { alert, reminder, tip }

class MockNotification {
  final String title;
  final String description;
  final DateTime timestamp;
  final NotificationType type;

  MockNotification({
    required this.title,
    required this.description,
    required this.timestamp,
    required this.type,
  });

  Color get color {
    switch (type) {
      case NotificationType.alert:
        return const Color(0xFFE63946);
      case NotificationType.reminder:
        return const Color(0xFF023E8A);
      case NotificationType.tip:
        return const Color(0xFF2A9D8F);
    }
  }

  IconData get icon {
    switch (type) {
      case NotificationType.alert:
        return Icons.warning_amber_rounded;
      case NotificationType.reminder:
        return Icons.notification_important_rounded;
      case NotificationType.tip:
        return Icons.lightbulb_outline_rounded;
    }
  }

  String get typeName {
    switch (type) {
      case NotificationType.alert:
        return 'ALERTA';
      case NotificationType.reminder:
        return 'RECORDATORIO';
      case NotificationType.tip:
        return 'TIP DE SALUD';
    }
  }

  String get timeLabel {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 60) {
      return 'Hace ${difference.inMinutes} min';
    } else if (difference.inHours < 24) {
      if (timestamp.day == now.day) {
        return 'Hoy, ${DateFormat('hh:mm a').format(timestamp)}';
      }
      return 'Ayer, ${DateFormat('hh:mm a').format(timestamp)}';
    } else {
      return DateFormat('dd MMM, hh:mm a').format(timestamp);
    }
  }
}
