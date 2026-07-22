class Medication {
  final int id;
  final int userId;
  final String name;
  final String? dosage;
  final int? frequencyHours;
  final DateTime? nextDose;
  final DateTime? lastDose;
  final bool isActive;
  final List<int>? daysOfWeek; // 1=Mon, 7=Sun
  final DateTime createdAt;
  final DateTime updatedAt;

  Medication({
    required this.id,
    required this.userId,
    required this.name,
    this.dosage,
    this.frequencyHours,
    this.nextDose,
    this.lastDose,
    required this.isActive,
    this.daysOfWeek,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Medication.fromJson(Map<String, dynamic> json) {
    return Medication(
      id: json['id'],
      userId: json['user_id'],
      name: json['name'],
      dosage: json['dosage'],
      frequencyHours: json['frequency_hours'],
      nextDose: json['next_dose'] != null ? DateTime.parse(json['next_dose']) : null,
      lastDose: json['last_dose'] != null ? DateTime.parse(json['last_dose']) : null,
      isActive: json['is_active'] ?? true,
      daysOfWeek: json['days_of_week'] != null 
          ? (json['days_of_week'] as String).split(',').where((s) => s.isNotEmpty).map(int.parse).toList() 
          : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'dosage': dosage,
      'frequency_hours': frequencyHours,
      'next_dose': nextDose?.toIso8601String(),
      'last_dose': lastDose?.toIso8601String(),
      'is_active': isActive,
      'days_of_week': daysOfWeek?.join(','),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Medication copyWith({
    int? id,
    int? userId,
    String? name,
    String? dosage,
    int? frequencyHours,
    DateTime? nextDose,
    DateTime? lastDose,
    bool? isActive,
    List<int>? daysOfWeek,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Medication(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      dosage: dosage ?? this.dosage,
      frequencyHours: frequencyHours ?? this.frequencyHours,
      nextDose: nextDose ?? this.nextDose,
      lastDose: lastDose ?? this.lastDose,
      isActive: isActive ?? this.isActive,
      daysOfWeek: daysOfWeek ?? this.daysOfWeek,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
