import '../../../domain/auth/entities/user_entity.dart';
import '../../../domain/auth/repositories/guardian_repository.dart';
import '../datasources/guardian_api_datasource.dart';
import '../datasources/supabase_auth_datasource.dart';

class GuardianRepositoryImpl implements GuardianRepository {
  final GuardianApiDataSource _apiDataSource;
  final SupabaseAuthDataSource _supabaseDataSource;

  GuardianRepositoryImpl({
    required GuardianApiDataSource apiDataSource,
    required SupabaseAuthDataSource supabaseDataSource,
  }) : _apiDataSource = apiDataSource,
       _supabaseDataSource = supabaseDataSource;

  @override
  Future<String> getLinkingCode() async {
    final token = await _supabaseDataSource.getIdToken();
    if (token == null) throw Exception('No se pudo obtener el token');
    return await _apiDataSource.getLinkingCode(token: token);
  }

  @override
  Future<String> linkPatient(String linkingCode) async {
    final token = await _supabaseDataSource.getIdToken();
    if (token == null) throw Exception('No se pudo obtener el token');
    return await _apiDataSource.linkPatient(token: token, linkingCode: linkingCode);
  }

  @override
  Future<List<UserEntity>> getMonitoredPatients() async {
    final token = await _supabaseDataSource.getIdToken();
    if (token == null) throw Exception('No se pudo obtener el token');
    
    final models = await _apiDataSource.getMonitoredPatients(token: token);
    return models.map((model) => model.toEntity()).toList();
  }
}
