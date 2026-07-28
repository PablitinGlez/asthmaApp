import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../infrastructure/services/background_sync_service.dart';

class BackgroundSyncState {
  final DateTime? lastSyncTime;
  final bool isSyncing;
  final bool isSuccess;
  final String statusMessage;

  BackgroundSyncState({
    this.lastSyncTime,
    this.isSyncing = false,
    this.isSuccess = true,
    this.statusMessage = 'Monitoreo Automático Activo',
  });

  BackgroundSyncState copyWith({
    DateTime? lastSyncTime,
    bool? isSyncing,
    bool? isSuccess,
    String? statusMessage,
  }) {
    return BackgroundSyncState(
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      isSyncing: isSyncing ?? this.isSyncing,
      isSuccess: isSuccess ?? this.isSuccess,
      statusMessage: statusMessage ?? this.statusMessage,
    );
  }
}

class BackgroundSyncNotifier extends Notifier<BackgroundSyncState> {
  Timer? _foregroundTimer;

  @override
  BackgroundSyncState build() {
    // 1. Cargar timestamp de última sincronización
    Future.microtask(() => loadLastSyncInfo());

    // 2. Iniciar temporizador activo de primer plano (envía datos automáticamente cada 5 min)
    _startForegroundAutoSync();

    ref.onDispose(() {
      _foregroundTimer?.cancel();
    });

    return BackgroundSyncState();
  }

  void _startForegroundAutoSync() {
    _foregroundTimer?.cancel();
    _foregroundTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      debugPrint('⏱️ [FOREGROUND TIMER] Ejecutando sincronización automática periódica (5 min)...');
      triggerSync();
    });
  }

  Future<void> loadLastSyncInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timeStr = prefs.getString('last_background_sync_time');
      final isSuccess = prefs.getBool('last_background_sync_success') ?? true;

      if (timeStr != null) {
        final time = DateTime.tryParse(timeStr);
        state = state.copyWith(
          lastSyncTime: time,
          isSuccess: isSuccess,
        );
      }
    } catch (_) {}
  }

  Future<void> triggerSync() async {
    if (state.isSyncing) return;

    state = state.copyWith(
      isSyncing: true,
      statusMessage: 'Sincronizando métricas en tiempo real...',
    );

    try {
      final success = await BackgroundSyncService.performBackgroundSync();
      final now = DateTime.now();

      state = state.copyWith(
        isSyncing: false,
        lastSyncTime: now,
        isSuccess: success,
        statusMessage: success
            ? 'Monitoreo Automático Activo'
            : 'Reintentando sincronización...',
      );
    } catch (e) {
      state = state.copyWith(
        isSyncing: false,
        isSuccess: false,
        statusMessage: 'Error de red en monitoreo',
      );
    }
  }
}

final backgroundSyncProvider =
    NotifierProvider<BackgroundSyncNotifier, BackgroundSyncState>(
  BackgroundSyncNotifier.new,
);
