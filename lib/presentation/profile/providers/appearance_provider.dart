import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';

class AppAppearance {
  final Color seedColor;
  final ThemeMode themeMode;

  const AppAppearance({
    required this.seedColor,
    required this.themeMode,
  });

  AppAppearance copyWith({Color? seedColor, ThemeMode? themeMode}) {
    return AppAppearance(
      seedColor: seedColor ?? this.seedColor,
      themeMode: themeMode ?? this.themeMode,
    );
  }
}

class AppearanceNotifier extends Notifier<AppAppearance> {
  @override
  AppAppearance build() {
    final authState = ref.watch(authStateProvider);
    final user = authState.value;
    if (user != null) {
      _loadFromPrefs(user.id);
    }
    return const AppAppearance(
      seedColor: Color(kDefaultAccent),
      themeMode: ThemeMode.system,
    );
  }

  Future<void> _loadFromPrefs(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final seed = prefs.getInt('appearance_seed_$userId') ?? kDefaultAccent;
    final mode = prefs.getString('appearance_theme_$userId') ?? 'system';
    state = AppAppearance(
      seedColor: Color(seed),
      themeMode: _parseMode(mode),
    );
  }

  ThemeMode _parseMode(String value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  Future<void> setSeedColor(Color color) async {
    state = state.copyWith(seedColor: color);
    await _persist();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    await _persist();
  }

  Future<void> _persist() async {
    final user = ref.read(authStateProvider).value;
    if (user == null) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('appearance_seed_${user.id}', state.seedColor.toARGB32());
    final String mode = state.themeMode == ThemeMode.dark
        ? 'dark'
        : state.themeMode == ThemeMode.light
            ? 'light'
            : 'system';
    await prefs.setString('appearance_theme_${user.id}', mode);
  }
}

final appearanceProvider =
    NotifierProvider<AppearanceNotifier, AppAppearance>(AppearanceNotifier.new);