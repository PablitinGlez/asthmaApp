import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import 'dart:io' show Platform;

class PermissionsState {
  final PermissionStatus notificationStatus;
  final PermissionStatus bluetoothStatus;
  final PermissionStatus healthStatus;
  final PermissionStatus locationStatus;
  final bool isLoading;

  PermissionsState({
    this.notificationStatus = PermissionStatus.denied,
    this.bluetoothStatus = PermissionStatus.denied,
    this.healthStatus = PermissionStatus.denied,
    this.locationStatus = PermissionStatus.denied,
    this.isLoading = true,
  });

  PermissionsState copyWith({
    PermissionStatus? notificationStatus,
    PermissionStatus? bluetoothStatus,
    PermissionStatus? healthStatus,
    PermissionStatus? locationStatus,
    bool? isLoading,
  }) {
    return PermissionsState(
      notificationStatus: notificationStatus ?? this.notificationStatus,
      bluetoothStatus: bluetoothStatus ?? this.bluetoothStatus,
      healthStatus: healthStatus ?? this.healthStatus,
      locationStatus: locationStatus ?? this.locationStatus,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class PermissionsNotifier extends Notifier<PermissionsState>
    with WidgetsBindingObserver {
  @override
  PermissionsState build() {
    WidgetsBinding.instance.addObserver(this);
    ref.onDispose(() {
      WidgetsBinding.instance.removeObserver(this);
    });

    Future.microtask(checkPermissions);
    return PermissionsState(isLoading: true);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState appState) {
    if (appState == AppLifecycleState.resumed) {
      checkPermissions();
    }
  }

  Future<void> checkPermissions() async {
    state = state.copyWith(isLoading: true);

    // Revisar estatus actual de Bluetooth (depende de Android o general)
    final bluetooth = await Permission.bluetooth.status;

    // Revisar estatus actual de Notificaciones
    final notification = await Permission.notification.status;

    // Revisar estatus actual de Salud/Sensores
    final health = Platform.isAndroid
        ? await Permission.activityRecognition.status
        : await Permission.sensors.status;

    // Revisar estatus actual de Ubicación (Privacidad de Software)
    final location = await Permission.location.status;

    state = state.copyWith(
      bluetoothStatus: bluetooth,
      notificationStatus: notification,
      healthStatus: health,
      locationStatus: location,
      isLoading: false,
    );
  }

  Future<void> requestNotificationPermission() async {
    await Permission.notification.request();
    await checkPermissions();
  }

  Future<void> requestBluetoothPermission() async {
    await Permission.bluetooth.request();
    // En Android 12+ tal vez se necesite bluetoothScan y bluetoothConnect.
    await Permission.bluetoothConnect.request();
    await Permission.bluetoothScan.request();
    await checkPermissions();
  }

  Future<void> requestHealthPermission() async {
    if (Platform.isAndroid) {
      await Permission.activityRecognition.request();
      await Permission.sensors.request();
    } else {
      await Permission.sensors.request();
    }
    await checkPermissions();
  }

  Future<void> requestLocationPermission() async {
    await Permission.location.request();
    await checkPermissions();
  }
}

final permissionsProvider =
    NotifierProvider<PermissionsNotifier, PermissionsState>(
      PermissionsNotifier.new,
    );
