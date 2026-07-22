class EmergencyContactModel {
  final int id;
  final int userId;
  final String contactName;
  final String phoneNumber;
  final String? relationship;
  final bool isPrimary;

  EmergencyContactModel({
    required this.id,
    required this.userId,
    required this.contactName,
    required this.phoneNumber,
    this.relationship,
    required this.isPrimary,
  });

  factory EmergencyContactModel.fromJson(Map<String, dynamic> json) {
    return EmergencyContactModel(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      contactName: json['contact_name'] as String,
      phoneNumber: json['phone_number'] as String,
      relationship: json['relationship'] as String?,
      isPrimary: json['is_primary'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'contact_name': contactName,
    'phone_number': phoneNumber,
    'relationship': relationship,
    'is_primary': isPrimary,
  };
}
