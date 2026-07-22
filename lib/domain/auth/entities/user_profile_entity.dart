class UserProfileEntity {
  final int userId;

  // Civic fields (Tab 1)
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

  // Clinical fields (Tab 2)
  final double? heightCm;
  final double? weightKg;
  final String? bloodType;
  final int? personalBestPef;
  final String? asthmaType;
  final String? diagnosisDate;
  final String? knownAllergies;
  final String? currentMedications;

  // Doctor vinculado (NUEVO)
  final String? linkedDoctorName;
  final String? linkedDoctorCode;
  final String? linkedDoctorSpecialty;
  final String? linkedDoctorEmail;

  UserProfileEntity({
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
}
