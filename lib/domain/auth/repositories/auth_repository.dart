import '../entities/user_entity.dart';
import '../entities/user_profile_entity.dart';

abstract class AuthRepository {
  Stream<UserEntity?> authStateChanges();

  Future<UserEntity> register({
    required String email,
    required String password,
    required String fullName,
    required String role,
  });

  Future<UserEntity> verifyOtpAndSync({
    required String email,
    required String tokenPin,
    required String fullName,
    required String role,
  });

  Future<UserEntity> login({required String email, required String password});

  Future<UserEntity> signInWithGoogle();

  Future<void> logout();

  Future<void> sendPasswordResetEmail(String email);

  Future<UserEntity> updateAvatar({
    required String avatarSeed,
    required String avatarBackground,
  });

  Future<void> updatePassword(String newPassword, {String? oldPassword});

  Future<void> createProfile({required Map<String, dynamic> profileData});

  Future<UserProfileEntity> getProfile();

  Future<UserProfileEntity> updateProfile({
    required Map<String, dynamic> profileData,
  });

  Future<String> assignDoctor({required String doctorCode});

  Future<void> resendOtp({required String email});

  Future<dynamic> enrollMfa();
  Future<dynamic> challengeAndVerifyMfa({
    required String factorId,
    required String code,
  });
  Future<void> unenrollMfa(String factorId);
  Future<dynamic> getAuthenticatorAssuranceLevel();
  Future<List<dynamic>> listFactors();

  Future<UserEntity> updateRole({required String role});

  Future<String> getLinkingCode();
  Future<List<Map<String, dynamic>>> getMyGuardians();
  Future<void> unlinkGuardian({required int guardianId});
  Future<void> updateFcmToken({required String fcmToken});
}
