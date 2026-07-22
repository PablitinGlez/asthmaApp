import '../entities/user_entity.dart';

abstract class GuardianRepository {
  Future<String> getLinkingCode();
  Future<String> linkPatient(String linkingCode);
  Future<List<UserEntity>> getMonitoredPatients();
}
