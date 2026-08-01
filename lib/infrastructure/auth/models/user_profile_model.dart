import '../../../domain/auth/entities/user_profile_entity.dart';

class UserProfileModel {
  final int userId;

  final String? firstName;
  final String? lastName;
  final int? age;
  final String? gender;
  final String? phoneNumber;
  final String? addressStreet;
  final String? addressCity;
  final String? addressState;
  final String? addressZip;
  final String? healthInsuranceNumber;

  final double? heightCm;
  final double? weightKg;
  final String? bloodType;
  final int? personalBestPef;
  final String? asthmaType;
  final String? diagnosisDate;
  final String? knownAllergies;
  final String? currentMedications;

  final String? linkedDoctorName;
  final String? linkedDoctorCode;
  final String? linkedDoctorSpecialty;
  final String? linkedDoctorEmail;

  UserProfileModel({
    required this.userId,
    this.firstName,
    this.lastName,
    this.age,
    this.gender,
    this.phoneNumber,
    this.addressStreet,
    this.addressCity,
    this.addressState,
    this.addressZip,
    this.healthInsuranceNumber,
    this.heightCm,
    this.weightKg,
    this.bloodType,
    this.personalBestPef,
    this.asthmaType,
    this.diagnosisDate,
    this.knownAllergies,
    this.currentMedications,
    this.linkedDoctorName,
    this.linkedDoctorCode,
    this.linkedDoctorSpecialty,
    this.linkedDoctorEmail,
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      userId: json['user_id'] ?? 0,
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      age: json['age'] as int?,
      gender: json['gender'] as String?,
      phoneNumber: json['phone_number'] as String?,
      addressStreet: json['address_street'] as String?,
      addressCity: json['address_city'] as String?,
      addressState: json['address_state'] as String?,
      addressZip: json['address_zip'] as String?,
      healthInsuranceNumber: json['health_insurance_number'] as String?,
      heightCm: json['height_cm'] != null
          ? (json['height_cm'] as num).toDouble()
          : null,
      weightKg: json['weight_kg'] != null
          ? (json['weight_kg'] as num).toDouble()
          : null,
      bloodType: json['blood_type'] as String?,
      personalBestPef: json['personal_best_pef'] as int?,
      asthmaType: json['asthma_type'] as String?,
      diagnosisDate: json['diagnosis_date'] as String?,
      knownAllergies: json['known_allergies'] as String?,
      currentMedications: json['current_medications'] as String?,
      linkedDoctorName: json['linked_doctor_name'] as String?,
      linkedDoctorCode: json['linked_doctor_code'] as String?,
      linkedDoctorSpecialty: json['linked_doctor_specialty'] as String?,
      linkedDoctorEmail: json['linked_doctor_email'] as String?,
    );
  }

  UserProfileEntity toEntity() => UserProfileEntity(
    userId: userId,
    firstName: firstName,
    lastName: lastName,
    age: age,
    gender: gender,
    phoneNumber: phoneNumber,
    addressStreet: addressStreet,
    addressCity: addressCity,
    addressState: addressState,
    addressZip: addressZip,
    healthInsuranceNumber: healthInsuranceNumber,
    heightCm: heightCm,
    weightKg: weightKg,
    bloodType: bloodType,
    personalBestPef: personalBestPef,
    asthmaType: asthmaType,
    diagnosisDate: diagnosisDate,
    knownAllergies: knownAllergies,
    currentMedications: currentMedications,
    linkedDoctorName: linkedDoctorName,
    linkedDoctorCode: linkedDoctorCode,
    linkedDoctorSpecialty: linkedDoctorSpecialty,
    linkedDoctorEmail: linkedDoctorEmail,
  );
}
