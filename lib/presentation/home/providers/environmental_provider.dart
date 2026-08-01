import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart' as gc;
import 'package:permission_handler/permission_handler.dart' as ph;
import '../../auth/providers/auth_provider.dart';

enum EnvironmentalStatus {
  initial,
  loading,
  missingPermission,
  serviceDisabled,
  deniedForever,
  authorized,
  error,
}

class EnvironmentalState {
  final EnvironmentalStatus status;
  final Position? position;
  final String? locationName;
  final String? errorMessage;

  final int? aqi;
  final String? airStatus;
  final String? pollenValue;
  final String? pollenStatus;
  final int? humidity;
  final String? humidityStatus;
  final double? windSpeed;
  final double? temperature;

  EnvironmentalState({
    required this.status,
    this.position,
    this.locationName,
    this.errorMessage,
    this.aqi,
    this.airStatus,
    this.pollenValue,
    this.pollenStatus,
    this.humidity,
    this.humidityStatus,
    this.windSpeed,
    this.temperature,
  });

  bool get isLoading => status == EnvironmentalStatus.loading;

  factory EnvironmentalState.initial() => EnvironmentalState(
    status: EnvironmentalStatus.initial,
    position: null,
    locationName: null,
    errorMessage: null,
    aqi: null,
    airStatus: null,
    pollenValue: null,
    pollenStatus: null,
    humidity: null,
    humidityStatus: null,
    windSpeed: null,
    temperature: null,
  );

  EnvironmentalState copyWith({
    EnvironmentalStatus? status,
    Position? position,
    String? locationName,
    String? errorMessage,
    int? aqi,
    String? airStatus,
    String? pollenValue,
    String? pollenStatus,
    int? humidity,
    String? humidityStatus,
    double? windSpeed,
    double? temperature,
  }) {
    return EnvironmentalState(
      status: status ?? this.status,
      position: position ?? this.position,
      locationName: locationName ?? this.locationName,
      errorMessage: errorMessage ?? this.errorMessage,
      aqi: aqi ?? this.aqi,
      airStatus: airStatus ?? this.airStatus,
      pollenValue: pollenValue ?? this.pollenValue,
      pollenStatus: pollenStatus ?? this.pollenStatus,
      humidity: humidity ?? this.humidity,
      humidityStatus: humidityStatus ?? this.humidityStatus,
      windSpeed: windSpeed ?? this.windSpeed,
      temperature: temperature ?? this.temperature,
    );
  }
}

class EnvironmentalNotifier extends Notifier<EnvironmentalState> {
  StreamSubscription<ServiceStatus>? _serviceStatusSubscription;

  @override
  EnvironmentalState build() {
    Future.microtask(checkCurrentStatus);

    if (!kIsWeb) {
      _serviceStatusSubscription = Geolocator.getServiceStatusStream().listen((
        status,
      ) {
        if (status == ServiceStatus.disabled) {
          state = state.copyWith(status: EnvironmentalStatus.serviceDisabled);
        } else {
          checkCurrentStatus();
        }
      });
    }

    ref.onDispose(() {
      _serviceStatusSubscription?.cancel();
    });

    return EnvironmentalState.initial();
  }

  Future<void> checkCurrentStatus() async {
    if (state.status == EnvironmentalStatus.initial) {
      state = state.copyWith(status: EnvironmentalStatus.loading);
    }

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        state = state.copyWith(status: EnvironmentalStatus.serviceDisabled);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        state = state.copyWith(status: EnvironmentalStatus.missingPermission);
      } else if (permission == LocationPermission.deniedForever) {
        state = state.copyWith(status: EnvironmentalStatus.deniedForever);
      } else {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 15),
        );

        await _fetchEnvironmentalData(position);
      }
    } catch (e) {
      final errorMsg = e.toString().toLowerCase();
      if (errorMsg.contains('disabled') ||
          errorMsg.contains('location service')) {
        state = state.copyWith(status: EnvironmentalStatus.serviceDisabled);
      } else {
        state = state.copyWith(
          status: EnvironmentalStatus.error,
          errorMessage: e.toString(),
        );
      }
    }
  }

  Future<void> requestPermission() async {
    state = state.copyWith(status: EnvironmentalStatus.loading);

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        state = state.copyWith(status: EnvironmentalStatus.serviceDisabled);
        return;
      }

      LocationPermission permission = await Geolocator.requestPermission();

      if (permission == LocationPermission.denied) {
        state = state.copyWith(status: EnvironmentalStatus.missingPermission);
      } else if (permission == LocationPermission.deniedForever) {
        state = state.copyWith(status: EnvironmentalStatus.deniedForever);
      } else {
        final position = await Geolocator.getCurrentPosition();
        await _fetchEnvironmentalData(position);
      }
    } catch (e) {
      final errorMsg = e.toString().toLowerCase();
      if (errorMsg.contains('disabled') ||
          errorMsg.contains('location service')) {
        state = state.copyWith(status: EnvironmentalStatus.serviceDisabled);
      } else {
        state = state.copyWith(
          status: EnvironmentalStatus.error,
          errorMessage: e.toString(),
        );
      }
    }
  }

  Future<void> _fetchEnvironmentalData(Position pos) async {
    try {
      final dio = ref.read(dioClientProvider);

      String? localName;
      try {
        List<gc.Placemark> placemarks = await gc.placemarkFromCoordinates(
          pos.latitude,
          pos.longitude,
        );
        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          localName = p.locality ?? p.subLocality ?? p.name ?? p.administrativeArea;
          if (localName != null && p.administrativeArea != null) {
             localName = "$localName, ${p.administrativeArea}";
          }
        }
      } catch (e) {
        debugPrint('Error en reverse geocoding: $e');
      }

      final response = await dio.get(
        '/api/environmental/info',
        queryParameters: {'lat': pos.latitude, 'lng': pos.longitude},
      );

      if (response.statusCode == 200) {
        final data = response.data;

        final weather = data['weather'] ?? {};
        final air = data['air_quality'] ?? {};
        final pollen = data['pollen'] ?? {};

        state = state.copyWith(
          status: EnvironmentalStatus.authorized,
          position: pos,
          locationName: localName ?? data['location_name'],
          aqi: air['aqi'] is int
              ? air['aqi']
              : (air['aqi'] != null
                    ? int.tryParse(air['aqi'].toString())
                    : null),
          airStatus: _mapAqiStatus(air['aqi']),
          temperature: weather['temperature']?.toDouble(),
          humidity: weather['humidity']?.toInt(),
          pollenValue: _extractPollenValue(pollen),
          pollenStatus: _mapPollenStatus(pollen),
          windSpeed: weather['windSpeed']?.toDouble(),
          errorMessage: null,
        );
      } else {
        throw Exception('Error del servidor: ${response.statusCode}');
      }
    } catch (e) {
      state = state.copyWith(
        status: EnvironmentalStatus.error,
        errorMessage: 'Error al obtener clima: $e',
      );
    }
  }

  String _mapAqiStatus(dynamic aqi) {
    if (aqi == null) return '--';
    final val = aqi is int ? aqi : int.tryParse(aqi.toString()) ?? 0;
    if (val <= 50) return 'Excelente';
    if (val <= 100) return 'Moderado';
    if (val <= 150) return 'Riesgo leve';
    return 'Peligroso';
  }

  String _extractPollenValue(dynamic pollen) {
    if (pollen == null || pollen['Count'] == null) return '--';
    final count = pollen['Count'];
    if (count is Map) {
      final grass = count['grass_pollen'] ?? 0;
      final tree = count['tree_pollen'] ?? 0;
      return (grass + tree).toString();
    }
    return count.toString();
  }

  String _mapPollenStatus(dynamic pollen) {
    if (pollen == null || pollen['Risk'] == null) return '--';
    final risk = pollen['Risk'];
    String rawValue = '';
    
    if (risk is Map) {
      rawValue = (risk['tree_pollen'] ?? risk['grass_pollen'] ?? 'Normal').toString();
    } else {
      rawValue = risk.toString();
    }

    final lower = rawValue.toLowerCase();
    if (lower.contains('low')) return 'Bajo';
    if (lower.contains('moderate') || lower.contains('medium')) return 'Medio';
    if (lower.contains('high') && !lower.contains('very')) return 'Alto';
    if (lower.contains('very high')) return 'Muy Alto';
    if (lower.contains('normal')) return 'Normal';
    
    return rawValue;
  }

  Future<void> openAppPermissionSettings() async {
    await ph.openAppSettings();
  }

  Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }
}

final environmentalProvider =
    NotifierProvider<EnvironmentalNotifier, EnvironmentalState>(
      EnvironmentalNotifier.new,
    );
