import 'package:dio/dio.dart';
import '../../../config/network/dio_client.dart';
import '../../../domain/models/medication.dart';

class MedicationApiDataSource {
  final DioClient _client;

  MedicationApiDataSource({required DioClient client}) : _client = client;

  Future<List<Medication>> getMedications(String token) async {
    final response = await _client.get(
      '/api/medications/',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = response.data;
      return data.map((json) => Medication.fromJson(json)).toList();
    }
    throw Exception('Error al obtener medicamentos');
  }

  Future<Medication> createMedication(String token, Map<String, dynamic> medicationData) async {
    final response = await _client.post(
      '/api/medications/',
      data: medicationData,
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    if (response.statusCode == 201) {
      return Medication.fromJson(response.data);
    }
    throw Exception('Error al crear medicamento');
  }

  Future<Medication> updateMedication(String token, int id, Map<String, dynamic> medicationData) async {
    final response = await _client.patch(
      '/api/medications/$id',
      data: medicationData,
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    if (response.statusCode == 200) {
      return Medication.fromJson(response.data);
    }
    throw Exception('Error al actualizar medicamento');
  }

  Future<void> deleteMedication(String token, int id) async {
    final response = await _client.delete(
      '/api/medications/$id',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    if (response.statusCode != 204) {
      throw Exception('Error al eliminar medicamento');
    }
  }

  Future<Medication> registerDose(String token, int id) async {
    final response = await _client.post(
      '/api/medications/$id/take',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    if (response.statusCode == 200) {
      return Medication.fromJson(response.data);
    }
    throw Exception('Error al registrar dosis');
  }
}
