import 'package:dio/dio.dart';
import '../../../config/network/dio_client.dart';
import '../models/user_model.dart';

class GuardianApiDataSource {
  final DioClient _client;

  GuardianApiDataSource({required DioClient client}) : _client = client;

  Future<String> getLinkingCode({required String token}) async {
    try {
      final response = await _client.get(
        '/api/guardian/linking-code',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        return response.data['linking_code'];
      } else {
        throw Exception('Error al obtener código de vinculación');
      }
    } on DioException catch (e) {
      throw Exception('Error de red al obtener código: ${e.message}');
    }
  }

  Future<String> linkPatient({
    required String token,
    required String linkingCode,
  }) async {
    try {
      final response = await _client.post(
        '/api/guardian/link',
        data: {'linking_code': linkingCode},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        return response.data['message'] ?? 'Vinculación exitosa';
      } else {
        throw Exception('Error al vincular paciente');
      }
    } on DioException catch (e) {
      if (e.response?.data != null && e.response?.data is Map) {
         throw Exception(e.response!.data['detail'] ?? 'Código de vinculación no válido');
      }
      throw Exception('Error de red al vincular: ${e.message}');
    }
  }

  Future<List<UserModel>> getMonitoredPatients({required String token}) async {
    try {
      final response = await _client.get(
        '/api/guardian/monitored-patients',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => UserModel.fromJson(json)).toList();
      } else {
        throw Exception('Error al obtener pacientes monitoreados');
      }
    } on DioException catch (e) {
      throw Exception('Error de red al obtener pacientes: ${e.message}');
    }
  }
}
