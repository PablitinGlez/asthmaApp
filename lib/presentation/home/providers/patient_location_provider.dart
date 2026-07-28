import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import '../../auth/providers/auth_provider.dart';

class PatientLocationState {
  final double? latitude;
  final double? longitude;
  final DateTime? lastUpdated;
  final bool isLoading;
  final String? errorMessage;

  PatientLocationState({
    this.latitude,
    this.longitude,
    this.lastUpdated,
    this.isLoading = false,
    this.errorMessage,
  });

  bool get hasLocation => latitude != null && longitude != null;

  PatientLocationState copyWith({
    double? latitude,
    double? longitude,
    DateTime? lastUpdated,
    bool? isLoading,
    String? errorMessage,
  }) {
    return PatientLocationState(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class PatientLocationNotifier extends Notifier<PatientLocationState> {
  @override
  PatientLocationState build() {
    // Intentar recuperar de caché inicial en background
    Future.microtask(() => loadFromCache());
    return PatientLocationState();
  }

  Future<void> loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lat = prefs.getDouble('patient_last_latitude');
      final lng = prefs.getDouble('patient_last_longitude');
      final timeStr = prefs.getString('patient_last_location_time');

      if (lat != null && lng != null) {
        final time = timeStr != null ? DateTime.tryParse(timeStr) : null;
        state = state.copyWith(
          latitude: lat,
          longitude: lng,
          lastUpdated: time,
        );
        debugPrint('📍 [UBICACIÓN CACHÉ] Recuperada de SharedPreferences: Lat=$lat, Lng=$lng');
      }
    } catch (_) {}
  }

  /// Solicita permisos de GPS, obtiene coordenadas en tiempo real y sincroniza con backend
  Future<void> fetchAndSyncLocation() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // Si el GPS del sistema está desactivado, intentar obtener la última posición conocida
        final lastPosition = await Geolocator.getLastKnownPosition();
        if (lastPosition != null) {
          await _saveAndSetLocation(lastPosition.latitude, lastPosition.longitude);
        }
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Los servicios de ubicación (GPS) están desactivados en el sistema.',
        );
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      debugPrint('📍 [GPS PERMISOS] Permiso inicial: $permission');

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        debugPrint('📍 [GPS PERMISOS] Permiso tras solicitar: $permission');
      }

      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        final lastPosition = await Geolocator.getLastKnownPosition();
        if (lastPosition != null) {
          await _saveAndSetLocation(lastPosition.latitude, lastPosition.longitude);
        }
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Permisos de ubicación no otorgados.',
        );
        return;
      }

      // Obtener posición en tiempo real precisa
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );

      await _saveAndSetLocation(position.latitude, position.longitude);

    } catch (e) {
      debugPrint('❌ [UBICACIÓN ERROR] Excepción al capturar GPS: $e');
      try {
        final lastKnown = await Geolocator.getLastKnownPosition();
        if (lastKnown != null) {
          await _saveAndSetLocation(lastKnown.latitude, lastKnown.longitude);
        }
      } catch (_) {}

      state = state.copyWith(
        isLoading: false,
        errorMessage: 'No se pudo obtener la ubicación actual.',
      );
    }
  }

  Future<void> _saveAndSetLocation(double lat, double lng) async {
    final now = DateTime.now();
    state = state.copyWith(
      latitude: lat,
      longitude: lng,
      lastUpdated: now,
      isLoading: false,
    );

    debugPrint('📍 [UBICACIÓN ÉXITO] Lat=$lat, Lng=$lng');

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('patient_last_latitude', lat);
      await prefs.setDouble('patient_last_longitude', lng);
      await prefs.setString('patient_last_location_time', now.toIso8601String());
    } catch (_) {}

    _sendLocationToBackend(lat, lng);
  }

  Future<void> _sendLocationToBackend(double lat, double lng) async {
    try {
      final dioClient = ref.read(dioClientProvider);
      final supabaseAuthDS = ref.read(supabaseAuthDataSourceProvider);
      final token = await supabaseAuthDS.getIdToken();

      if (token == null) return;

      final response = await dioClient.post(
        '/api/patient/location',
        data: {
          'latitude': lat,
          'longitude': lng,
          'timestamp': DateTime.now().toIso8601String(),
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      debugPrint('✅ [UBICACIÓN BACKEND] Sincronizada con estado 200/201: ${response.statusCode}');
    } catch (e) {
      debugPrint('ℹ️ [UBICACIÓN BACKEND] Envió asíncrono realizado. Error de backend: $e');
    }
  }
}

final patientLocationProvider =
    NotifierProvider<PatientLocationNotifier, PatientLocationState>(
  PatientLocationNotifier.new,
);
