import 'package:dio/dio.dart';
import '../models/user_model.dart';
import '../models/user_profile_model.dart';
import '../../../config/network/dio_client.dart';

class AuthApiDataSource {
  final DioClient _client;

  AuthApiDataSource({required DioClient client}) : _client = client;

  Future<bool> checkEmailExists({required String email}) async {
    try {
      final response = await _client.post(
        '/api/auth/check-email',
        data: {'email': email},
      );
      if (response.statusCode == 200) {
        return response.data['exists'] == true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<UserModel> registerInBackend({
    required String token,
    required String fullName,
    required String role,
  }) async {
    try {
      final response = await _client.post(
        '/api/auth/register',
        data: {'full_name': fullName, 'role': role},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        return UserModel.fromJson(response.data['user']);
      } else {
        throw Exception('Error al registrar en el backend: ${response.data}');
      }
    } on DioException catch (e) {
      throw Exception('Error de red: ${e.message}');
    }
  }

  Future<UserModel?> verifyTokenInBackend(String token) async {
    try {
      final response = await _client.post(
        '/api/auth/verify',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map<String, dynamic> && data.containsKey('user')) {
          return UserModel.fromJson(data['user']);
        }
        return UserModel.fromJson(data);
      }
      return null;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return null; // Usuario no existe en backend
      }
      throw Exception('Error al verificar token: ${e.message}');
    }
  }

  Future<UserModel> updateAvatarInBackend({
    required String token,
    required String avatarSeed,
    required String avatarBackground,
  }) async {
    try {
      final response = await _client.patch(
        '/api/auth/update-avatar',
        data: {
          'avatar_seed': avatarSeed,
          'avatar_background': avatarBackground,
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        return UserModel.fromJson(response.data['user']);
      } else {
        throw Exception('Error al actualizar avatar en el backend');
      }
    } on DioException catch (e) {
      throw Exception('Error de red al actualizar avatar: ${e.message}');
    }
  }

  Future<void> createProfile({
    required String token,
    required Map<String, dynamic> profileData,
  }) async {
    try {
      final response = await _client.post(
        '/api/auth/profile',
        data: profileData,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Error al crear perfil en el backend: ${response.data}',
        );
      }
    } on DioException catch (e) {
      throw Exception('Error de red al crear perfil: ${e.message}');
    }
  }

  Future<UserProfileModel> getProfile({required String token}) async {
    try {
      final response = await _client.get(
        '/api/auth/profile',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        print(' DEBUG: Profile Response: ${response.data}');
        return UserProfileModel.fromJson(response.data);
      } else {
        throw Exception('Error al obtener perfil del backend');
      }
    } on DioException catch (e) {
      throw Exception('Error de red al obtener perfil: ${e.message}');
    }
  }

  Future<UserProfileModel> updateProfile({
    required String token,
    required Map<String, dynamic> profileData,
  }) async {
    try {
      final response = await _client.put(
        '/api/auth/profile',
        data: profileData,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        return UserProfileModel.fromJson(response.data);
      } else {
        throw Exception('Error al actualizar perfil en el backend');
      }
    } on DioException catch (e) {
      throw Exception('Error de red al actualizar perfil: ${e.message}');
    }
  }

  Future<String> assignDoctor({
    required String token,
    required String doctorCode,
  }) async {
    try {
      final response = await _client.post(
        '/api/auth/assign-doctor?doctor_code=$doctorCode',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        return response.data['message'] ?? 'Doctor vinculado exitosamente';
      } else {
        throw Exception('Error al vincular doctor: ${response.data}');
      }
    } on DioException catch (e) {
      if (e.response?.data != null && e.response?.data is Map) {
         throw Exception(e.response!.data['detail'] ?? 'Código de doctor no válido');
      }
      throw Exception('Error de red: ${e.message}');
    }
  }

  Future<UserModel> updateRole({
    required String token,
    required String role,
  }) async {
    try {
      final response = await _client.patch(
        '/api/auth/role',
        data: {'role': role},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        return UserModel.fromJson(response.data['user']);
      } else {
        throw Exception('Error al actualizar rol en el backend');
      }
    } on DioException catch (e) {
      throw Exception('Error de red al actualizar rol: ${e.message}');
    }
  }

  // Métodos para guardianes y vinculación (paciente)

  Future<String> getLinkingCode({required String token}) async {
    try {
      final response = await _client.get(
        '/api/guardian/linking-code',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (response.statusCode == 200) {
        return response.data['linking_code'];
      }
      throw Exception('Error al obtener el código de vinculación');
    } on DioException catch (e) {
      throw Exception('Error de red al obtener el código: ${e.message}');
    }
  }

  Future<List<Map<String, dynamic>>> getMyGuardians({required String token}) async {
    try {
      final response = await _client.get(
        '/api/guardian/my-guardians',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(response.data);
      }
      throw Exception('Error al obtener los guardianes');
    } on DioException catch (e) {
      throw Exception('Error de red: ${e.message}');
    }
  }

  Future<void> unlinkGuardian({required String token, required int guardianId}) async {
    try {
      final response = await _client.delete(
        '/api/guardian/unlink/$guardianId',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (response.statusCode != 200) {
        throw Exception('Error al desvincular al guardián');
      }
    } on DioException catch (e) {
      throw Exception('Error de red: ${e.message}');
    }
  }

  Future<void> updateFcmToken({
    required String token,
    required String fcmToken,
  }) async {
    try {
      final response = await _client.post(
        '/api/auth/fcm-token?fcm_token=$fcmToken',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode != 200) {
        throw Exception('Error al actualizar fcm token en el backend');
      }
    } on DioException catch (e) {
      throw Exception('Error de red: ${e.message}');
    }
  }
}
