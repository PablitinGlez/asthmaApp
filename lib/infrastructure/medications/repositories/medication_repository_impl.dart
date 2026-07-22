import '../../../domain/models/medication.dart';
import '../datasources/medication_api_datasource.dart';

abstract class MedicationRepository {
  Future<List<Medication>> getMedications(String token);
  Future<Medication> createMedication(String token, Map<String, dynamic> data);
  Future<Medication> updateMedication(String token, int id, Map<String, dynamic> data);
  Future<void> deleteMedication(String token, int id);
  Future<Medication> registerDose(String token, int id);
}

class MedicationRepositoryImpl implements MedicationRepository {
  final MedicationApiDataSource _dataSource;

  MedicationRepositoryImpl({required MedicationApiDataSource dataSource})
      : _dataSource = dataSource;

  @override
  Future<List<Medication>> getMedications(String token) => 
      _dataSource.getMedications(token);

  @override
  Future<Medication> createMedication(String token, Map<String, dynamic> data) =>
      _dataSource.createMedication(token, data);

  @override
  Future<Medication> updateMedication(String token, int id, Map<String, dynamic> data) =>
      _dataSource.updateMedication(token, id, data);

  @override
  Future<void> deleteMedication(String token, int id) => 
      _dataSource.deleteMedication(token, id);

  @override
  Future<Medication> registerDose(String token, int id) => 
      _dataSource.registerDose(token, id);
}
