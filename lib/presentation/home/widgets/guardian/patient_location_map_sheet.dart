import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../domain/auth/entities/user_entity.dart';

/// Muestra un BottomSheet con mapa interactivo y ubicación en tiempo real del paciente.
void showPatientLocationMapSheet(BuildContext context, UserEntity patient) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => PatientLocationMapSheet(patient: patient),
  );
}

class PatientLocationMapSheet extends StatefulWidget {
  final UserEntity patient;
  const PatientLocationMapSheet({super.key, required this.patient});

  @override
  State<PatientLocationMapSheet> createState() =>
      _PatientLocationMapSheetState();
}

class _PatientLocationMapSheetState extends State<PatientLocationMapSheet> {
  double? _activeLat;
  double? _activeLng;
  bool _hasRealGps = false;
  String? _addressText;
  bool _isLoadingAddress = false;

  @override
  void initState() {
    super.initState();
    _initCoordinates();
  }

  Future<void> _initCoordinates() async {
    double? lat = widget.patient.latitude;
    double? lng = widget.patient.longitude;

    if (lat != null && lng != null) {
      if (mounted) {
        setState(() {
          _activeLat = lat;
          _activeLng = lng;
          _hasRealGps = true;
        });
      }
      _fetchAddress(lat, lng);
      return;
    }

    // Respaldo en caché local de SharedPreferences (Pruebas en el mismo dispositivo o caché reciente)
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedLat = prefs.getDouble('patient_last_latitude');
      final cachedLng = prefs.getDouble('patient_last_longitude');

      if (cachedLat != null && cachedLng != null && mounted) {
        setState(() {
          _activeLat = cachedLat;
          _activeLng = cachedLng;
          _hasRealGps = true;
        });
        _fetchAddress(cachedLat, cachedLng);
        return;
      }
    } catch (_) {}

    // Respaldo por lectura directa del dispositivo
    try {
      final lastPos = await Geolocator.getLastKnownPosition();
      if (lastPos != null && mounted) {
        setState(() {
          _activeLat = lastPos.latitude;
          _activeLng = lastPos.longitude;
          _hasRealGps = true;
        });
        _fetchAddress(lastPos.latitude, lastPos.longitude);
        return;
      }
    } catch (_) {}

    // Ubicación por defecto de respaldo (CDMX)
    if (mounted) {
      setState(() {
        _activeLat = 19.4326077;
        _activeLng = -99.133208;
        _hasRealGps = false;
      });
    }
  }

  Future<void> _fetchAddress(double lat, double lng) async {
    setState(() => _isLoadingAddress = true);
    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty && mounted) {
        final place = placemarks.first;
        final street = place.street ?? '';
        final subLocality = place.subLocality ?? place.locality ?? '';
        final administrativeArea = place.administrativeArea ?? '';
        setState(() {
          _addressText = [street, subLocality, administrativeArea]
              .where((s) => s.isNotEmpty)
              .join(', ');
          _isLoadingAddress = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingAddress = false);
      }
    }
  }

  Future<void> _openExternalMaps(double lat, double lng) async {
    final Uri googleMapsUrl = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
    );
    if (await canLaunchUrl(googleMapsUrl)) {
      await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir la aplicación de mapas.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final double targetLat = _activeLat ?? 19.4326077;
    final double targetLng = _activeLng ?? -99.133208;
    final LatLng centerLatLng = LatLng(targetLat, targetLng);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // ── Header con Handle y Título ──
          Container(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: Color(
                        int.parse(
                          'FF${widget.patient.avatarBackground}',
                          radix: 16,
                        ),
                      ),
                      child: ClipOval(
                        child: SvgPicture.network(
                          'https://api.dicebear.com/9.x/initials/svg?seed=${widget.patient.avatarSeed}&backgroundColor=${widget.patient.avatarBackground}',
                          width: 40,
                          height: 40,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.patient.fullName,
                            style: const TextStyle(
                              fontFamily: 'Satoshi',
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1D3557),
                            ),
                          ),
                          Row(
                            children: [
                              Icon(
                                _hasRealGps
                                    ? Icons.my_location_rounded
                                    : Icons.location_off_outlined,
                                size: 14,
                                color: _hasRealGps
                                    ? Colors.green.shade600
                                    : Colors.orange.shade700,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _hasRealGps
                                    ? 'Ubicación GPS en tiempo real'
                                    : 'Sin señal de GPS reciente',
                                style: TextStyle(
                                  fontFamily: 'GeneralSans',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: _hasRealGps
                                      ? Colors.green.shade700
                                      : Colors.orange.shade800,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Cuerpo: Mapa Interactivo FlutterMap ──
          Expanded(
            child: ClipRect(
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: centerLatLng,
                  initialZoom: 15.5,
                  minZoom: 4.0,
                  maxZoom: 18.0,
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.asthmaapp.app',
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: centerLatLng,
                        width: 70,
                        height: 70,
                        child: _PatientMapMarker(
                          patientName: widget.patient.fullName,
                          avatarSeed: widget.patient.avatarSeed,
                          avatarBg: widget.patient.avatarBackground,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ── Footer: Dirección y Botón External Map ──
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.pin_drop_rounded, color: Color(0xFFD90429), size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _isLoadingAddress
                            ? 'Buscando dirección...'
                            : (_addressText ??
                                '${targetLat.toStringAsFixed(5)}°, ${targetLng.toStringAsFixed(5)}°'),
                        style: const TextStyle(
                          fontFamily: 'GeneralSans',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () => _openExternalMaps(targetLat, targetLng),
                    icon: const Icon(Icons.map_rounded, size: 20),
                    label: const Text(
                      'Abrir en Google Maps',
                      style: TextStyle(
                        fontFamily: 'Satoshi',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF023E8A),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PatientMapMarker extends StatelessWidget {
  final String patientName;
  final String avatarSeed;
  final String avatarBg;

  const _PatientMapMarker({
    required this.patientName,
    required this.avatarSeed,
    required this.avatarBg,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Onda externa de pulso
        Container(
          width: 66,
          height: 66,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFD90429).withValues(alpha: 0.25),
            border: Border.all(
              color: const Color(0xFFD90429).withValues(alpha: 0.6),
              width: 1.5,
            ),
          ),
        ),
        // Pin central con el avatar del paciente
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: CircleAvatar(
            radius: 22,
            backgroundColor: Color(int.parse('FF$avatarBg', radix: 16)),
            child: ClipOval(
              child: SvgPicture.network(
                'https://api.dicebear.com/9.x/initials/svg?seed=$avatarSeed&backgroundColor=$avatarBg',
                width: 44,
                height: 44,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
