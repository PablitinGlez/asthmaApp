import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../auth/providers/auth_provider.dart';

class NotificationSettings {
  final bool pefRemindersEnabled;
  final TimeOfDay morningReminder;
  final TimeOfDay afternoonReminder;
  final TimeOfDay eveningReminder;
  final bool emergencyAlertsEnabled;
  final bool healthTipsEnabled;
  final bool soundEnabled;
  final bool vibrationEnabled;

  NotificationSettings({
    this.pefRemindersEnabled = true,
    this.morningReminder = const TimeOfDay(hour: 8, minute: 0),
    this.afternoonReminder = const TimeOfDay(hour: 14, minute: 0),
    this.eveningReminder = const TimeOfDay(hour: 20, minute: 0),
    this.emergencyAlertsEnabled = true,
    this.healthTipsEnabled = true,
    this.soundEnabled = true,
    this.vibrationEnabled = true,
  });

  NotificationSettings copyWith({
    bool? pefRemindersEnabled,
    TimeOfDay? morningReminder,
    TimeOfDay? afternoonReminder,
    TimeOfDay? eveningReminder,
    bool? emergencyAlertsEnabled,
    bool? healthTipsEnabled,
    bool? soundEnabled,
    bool? vibrationEnabled,
  }) {
    return NotificationSettings(
      pefRemindersEnabled: pefRemindersEnabled ?? this.pefRemindersEnabled,
      morningReminder: morningReminder ?? this.morningReminder,
      afternoonReminder: afternoonReminder ?? this.afternoonReminder,
      eveningReminder: eveningReminder ?? this.eveningReminder,
      emergencyAlertsEnabled:
          emergencyAlertsEnabled ?? this.emergencyAlertsEnabled,
      healthTipsEnabled: healthTipsEnabled ?? this.healthTipsEnabled,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
    );
  }
}

class NotificationSettingsNotifier extends Notifier<NotificationSettings> {
  @override
  NotificationSettings build() {
    final authState = ref.watch(authStateProvider);
    final user = authState.value;

    if (user != null) {
      _loadSettings(user.id);
    }
    
    return NotificationSettings();
  }

  Future<void> _loadSettings(String userId) async {
    final prefs = await SharedPreferences.getInstance();

    final morningHour = prefs.getInt('notif_morning_hour_$userId') ?? 8;
    final morningMinute = prefs.getInt('notif_morning_minute_$userId') ?? 0;

    final afternoonHour = prefs.getInt('notif_afternoon_hour_$userId') ?? 14;
    final afternoonMinute = prefs.getInt('notif_afternoon_minute_$userId') ?? 0;

    final eveningHour = prefs.getInt('notif_evening_hour_$userId') ?? 20;
    final eveningMinute = prefs.getInt('notif_evening_minute_$userId') ?? 0;

    state = NotificationSettings(
      pefRemindersEnabled: prefs.getBool('notif_pef_enabled_$userId') ?? true,
      morningReminder: TimeOfDay(hour: morningHour, minute: morningMinute),
      afternoonReminder: TimeOfDay(
        hour: afternoonHour,
        minute: afternoonMinute,
      ),
      eveningReminder: TimeOfDay(hour: eveningHour, minute: eveningMinute),
      emergencyAlertsEnabled: prefs.getBool('notif_emergency_enabled_$userId') ?? true,
      healthTipsEnabled: prefs.getBool('notif_tips_enabled_$userId') ?? true,
      soundEnabled: prefs.getBool('notif_sound_enabled_$userId') ?? true,
      vibrationEnabled: prefs.getBool('notif_vibration_enabled_$userId') ?? true,
    );
  }

  Future<void> updateSettings(NotificationSettings newSettings) async {
    final user = ref.read(authStateProvider).value;
    if (user == null) return;
    
    final userId = user.id;
    state = newSettings;
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool('notif_pef_enabled_$userId', newSettings.pefRemindersEnabled);
    await prefs.setInt('notif_morning_hour_$userId', newSettings.morningReminder.hour);
    await prefs.setInt(
      'notif_morning_minute_$userId',
      newSettings.morningReminder.minute,
    );
    await prefs.setInt(
      'notif_afternoon_hour_$userId',
      newSettings.afternoonReminder.hour,
    );
    await prefs.setInt(
      'notif_afternoon_minute_$userId',
      newSettings.afternoonReminder.minute,
    );
    await prefs.setInt('notif_evening_hour_$userId', newSettings.eveningReminder.hour);
    await prefs.setInt(
      'notif_evening_minute_$userId',
      newSettings.eveningReminder.minute,
    );
    await prefs.setBool(
      'notif_emergency_enabled_$userId',
      newSettings.emergencyAlertsEnabled,
    );
    await prefs.setBool('notif_tips_enabled_$userId', newSettings.healthTipsEnabled);
    await prefs.setBool('notif_sound_enabled_$userId', newSettings.soundEnabled);
    await prefs.setBool(
      'notif_vibration_enabled_$userId',
      newSettings.vibrationEnabled,
    );

    print(' NotificationSettings: Persisted successfully for $userId');
  }

  Future<void> togglePefReminders(bool value) =>
      updateSettings(state.copyWith(pefRemindersEnabled: value));
  Future<void> toggleEmergencyAlerts(bool value) =>
      updateSettings(state.copyWith(emergencyAlertsEnabled: value));
  Future<void> toggleHealthTips(bool value) =>
      updateSettings(state.copyWith(healthTipsEnabled: value));
  Future<void> toggleSound(bool value) =>
      updateSettings(state.copyWith(soundEnabled: value));
  Future<void> toggleVibration(bool value) =>
      updateSettings(state.copyWith(vibrationEnabled: value));

  Future<void> updateMorningTime(TimeOfDay time) =>
      updateSettings(state.copyWith(morningReminder: time));
  Future<void> updateAfternoonTime(TimeOfDay time) =>
      updateSettings(state.copyWith(afternoonReminder: time));
  Future<void> updateEveningTime(TimeOfDay time) =>
      updateSettings(state.copyWith(eveningReminder: time));
}

final notificationSettingsProvider =
    NotifierProvider<NotificationSettingsNotifier, NotificationSettings>(() {
      return NotificationSettingsNotifier();
    });
