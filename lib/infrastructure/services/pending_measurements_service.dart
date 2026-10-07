import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';

/// Cola local de mediciones pendientes de enviar.
///
/// Cuando no hay internet, la medición (p. ej. PEF) se guarda aquí en
/// SharedPreferences. Al volver la conexión, [flushPending] reenvía todo y
/// vacía la cola. Evita perder datos de salud por caídas de red.
class PendingMeasurementsService {
  static const String _key = 'pending_measurements_queue';

  static const String baseUrl = 'https://asthma-predictor-api.onrender.com';

  Future<List<Map<String, dynamic>>> _read() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<void> _write(List<Map<String, dynamic>> queue) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(queue));
  }

  /// Guarda una medición pendiente (payload + query params + endpoint).
  Future<void> enqueue({
    required String endpoint,
    required Map<String, dynamic> data,
    Map<String, dynamic>? queryParameters,
    String? token,
  }) async {
    final queue = await _read();
    queue.add({
      'endpoint': endpoint,
      'data': data,
      'queryParameters': queryParameters,
      'token': token,
    });
    await _write(queue);
  }

  /// Número de mediciones pendientes.
  Future<int> count() async => (await _read()).length;

  /// Reenvía todas las pendientes. Devuelve cuántas quedaron sin enviar.
  Future<int> flushPending() async {
    final queue = await _read();
    if (queue.isEmpty) return 0;

    final dio = Dio();
    dio.options.connectTimeout = const Duration(seconds: 10);
    dio.options.receiveTimeout = const Duration(seconds: 10);

    final remaining = <Map<String, dynamic>>[];

    for (final item in queue) {
      final headers = <String, String>{'Content-Type': 'application/json'};
      final token = item['token'] as String?;
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
      try {
        await dio.post(
          '$baseUrl${item['endpoint']}',
          data: item['data'],
          queryParameters: (item['queryParameters'] as Map?)?.cast<String, dynamic>(),
          options: Options(headers: headers),
        );
      } catch (_) {
        remaining.add(item);
      }
    }

    await _write(remaining);
    return remaining.length;
  }
}
