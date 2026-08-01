import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'dart:math';
import '../../auth/providers/auth_provider.dart';

class SpirometerState {
  final bool hasLinkedDevice;
  final bool isLoading;
  final String? errorMessage;
  final List<dynamic> devices;

  SpirometerState({
    this.hasLinkedDevice = false,
    this.isLoading = true,
    this.errorMessage,
    this.devices = const [],
  });

  SpirometerState copyWith({
    bool? hasLinkedDevice,
    bool? isLoading,
    String? errorMessage,
    List<dynamic>? devices,
  }) {
    return SpirometerState(
      hasLinkedDevice: hasLinkedDevice ?? this.hasLinkedDevice,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      devices: devices ?? this.devices,
    );
  }
}

class SpirometerNotifier extends Notifier<SpirometerState> {
  @override
  SpirometerState build() {
    Future.microtask(checkLinkedDevices);
    return SpirometerState(isLoading: true);
  }

  Future<void> checkLinkedDevices() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final dioClient = ref.read(dioClientProvider);
      final supabaseAuthDS = ref.read(supabaseAuthDataSourceProvider);
      final token = await supabaseAuthDS.getIdToken();

      if (token == null) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: null,
        );
        return;
      }

      final response = await dioClient.get(
        '/api/devices',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        final List<dynamic> devices = response.data;
        state = state.copyWith(
          hasLinkedDevice: devices.isNotEmpty,
          devices: devices,
          isLoading: false,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Error al consultar dispositivos',
        );
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        state = state.copyWith(hasLinkedDevice: false, isLoading: false);
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: e.response?.data['detail'] ?? 'Error de conexión',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error inesperado',
      );
    }
  }

  Future<void> _refreshDevicesSilently() async {
    try {
      final dioClient = ref.read(dioClientProvider);
      final supabaseAuthDS = ref.read(supabaseAuthDataSourceProvider);
      final token = await supabaseAuthDS.getIdToken();

      if (token == null) return;

      final response = await dioClient.get(
        '/api/devices',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        final List<dynamic> devices = response.data;
        state = state.copyWith(
          hasLinkedDevice: devices.isNotEmpty,
          devices: devices,
          isLoading: false,
        );
      }
    } catch (e) {}
  }

  Future<bool> linkDevice() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final dioClient = ref.read(dioClientProvider);
      final supabaseAuthDS = ref.read(supabaseAuthDataSourceProvider);
      final token = await supabaseAuthDS.getIdToken();

      if (token == null) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'No se pudo obtener el token',
        );
        return false;
      }

      final random = Random();
      final mac = List.generate(
        6,
        (_) =>
            random.nextInt(256).toRadixString(16).padLeft(2, '0').toUpperCase(),
      ).join(':');

      final Map<String, dynamic> deviceData = {
        'device_type': 'spirometer',
        'device_brand': 'Spirometer',
        'device_model': 'SmartPro BT-300',
        'device_mac_address': mac,
        'is_active': true,
      };

      final response = await dioClient.post(
        '/api/devices',
        data: deviceData,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        state = state.copyWith(hasLinkedDevice: true, isLoading: false);
        await _refreshDevicesSilently();
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Error al vincular el dispositivo',
        );
        return false;
      }
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage:
            e.response?.data['detail'] ?? 'Error de conexión al vincular',
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error inesperado al vincular',
      );
      return false;
    }
  }
}

final spirometerProvider =
    NotifierProvider<SpirometerNotifier, SpirometerState>(
      SpirometerNotifier.new,
    );
