import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/notification_settings_provider.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(notificationSettingsProvider);
    final notifier = ref.read(notificationSettingsProvider.notifier);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.black87,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Configurar Alertas',
          style: TextStyle(
            color: Colors.black87,
            fontFamily: 'Satoshi',
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(
              'Recordatorios de Soplido',
              'Asegura tus mediciones diarias',
            ),
            const SizedBox(height: 16),
            _buildToggleCard(
              title: 'Habilitar Recordatorios',
              subtitle: 'Recibe avisos para registrar tu PEF',
              value: settings.pefRemindersEnabled,
              onChanged: notifier.togglePefReminders,
              icon: Icons.alarm_on_rounded,
            ),

            if (settings.pefRemindersEnabled) ...[
              const SizedBox(height: 16),
              _buildTimeSettingCard(
                context: context,
                title: 'Mañana',
                time: settings.morningReminder,
                onTap: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: settings.morningReminder,
                  );
                  if (time != null) notifier.updateMorningTime(time);
                },
              ),
              const SizedBox(height: 12),
              _buildTimeSettingCard(
                context: context,
                title: 'Tarde',
                time: settings.afternoonReminder,
                onTap: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: settings.afternoonReminder,
                  );
                  if (time != null) notifier.updateAfternoonTime(time);
                },
              ),
              const SizedBox(height: 12),
              _buildTimeSettingCard(
                context: context,
                title: 'Noche',
                time: settings.eveningReminder,
                onTap: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: settings.eveningReminder,
                  );
                  if (time != null) notifier.updateEveningTime(time);
                },
              ),
            ],

            const SizedBox(height: 40),
            _buildSectionHeader('Alertas Inteligentes', 'IA y Seguridad'),
            const SizedBox(height: 16),
            _buildToggleCard(
              title: 'Alertas de Emergencia',
              subtitle: 'Avisa a contactos si entras en Zona Roja',
              value: settings.emergencyAlertsEnabled,
              onChanged: notifier.toggleEmergencyAlerts,
              icon: Icons.emergency_share_rounded,
            ),
            const SizedBox(height: 12),
            _buildToggleCard(
              title: 'Consejos de Salud',
              subtitle: 'Tips basados en clima y polen',
              value: settings.healthTipsEnabled,
              onChanged: notifier.toggleHealthTips,
              icon: Icons.lightbulb_outline_rounded,
            ),

            const SizedBox(height: 40),
            _buildSectionHeader(
              'Preferencias de Sistema',
              'Feedback de la app',
            ),
            const SizedBox(height: 16),
            _buildToggleCard(
              title: 'Sonido',
              subtitle: 'Alertas audibles',
              value: settings.soundEnabled,
              onChanged: notifier.toggleSound,
              icon: Icons.volume_up_rounded,
            ),
            const SizedBox(height: 12),
            _buildToggleCard(
              title: 'Vibración',
              subtitle: 'Feedback táctil',
              value: settings.vibrationEnabled,
              onChanged: notifier.toggleVibration,
              icon: Icons.vibration_rounded,
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Satoshi',
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: Color(0xFF023E8A),
          ),
        ),
        Text(
          subtitle,
          style: TextStyle(
            fontFamily: 'GeneralSans',
            fontSize: 13,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildToggleCard({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF023E8A).withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF023E8A), size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Satoshi',
                    fontWeight: FontWeight.w500,
                    fontSize: 15,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontFamily: 'GeneralSans',
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF023E8A),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSettingCard({
    required BuildContext context,
    required String title,
    required TimeOfDay time,
    required VoidCallback onTap,
  }) {
    final timeStr =
        '${time.hourOfPeriod}:${time.minute.toString().padLeft(2, '0')} ${time.period == DayPeriod.am ? 'AM' : 'PM'}';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Row(
          children: [
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'Satoshi',
                fontWeight: FontWeight.w400,
                fontSize: 15,
              ),
            ),
            const Spacer(),
            Text(
              timeStr,
              style: const TextStyle(
                fontFamily: 'GeneralSans',
                fontSize: 15,
                fontWeight: FontWeight.w400,
                color: Color(0xFF023E8A),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.edit_calendar_rounded,
              size: 18,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
}
