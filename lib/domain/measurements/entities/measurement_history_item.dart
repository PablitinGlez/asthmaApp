class MeasurementHistoryItem {
  final int? id;
  final DateTime measuredAt;
  final int? pef;
  final int? spo2;
  final int? heartRate;
  final String? symptoms;
  final String? symptomIntensity;
  final String? notes;
  final int? aqi;
  final double? temperature;
  final int? humidity;
  final String? pollenLevel;
  final String? locationName;
  final int? steps;
  final double? sleepHours;
  final int? respiratoryRate;

  MeasurementHistoryItem({
    this.id,
    required this.measuredAt,
    this.pef,
    this.spo2,
    this.heartRate,
    this.symptoms,
    this.symptomIntensity,
    this.notes,
    this.aqi,
    this.temperature,
    this.humidity,
    this.pollenLevel,
    this.locationName,
    this.steps,
    this.sleepHours,
    this.respiratoryRate,
  });

  factory MeasurementHistoryItem.fromJson(Map<String, dynamic> json) {
    return MeasurementHistoryItem(
      id: json['id'] as int?,
      measuredAt: DateTime.parse(json['measured_at']),
      pef: json['pef'] as int?,
      spo2: json['spo2'] as int?,
      heartRate: json['heart_rate'] as int?,
      symptoms: json['symptoms'] as String?,
      symptomIntensity: json['symptom_intensity'] as String?,
      notes: json['notes'] as String?,
      aqi: json['aqi'] as int?,
      temperature: json['temperature'] != null
          ? (json['temperature'] as num).toDouble()
          : null,
      humidity: json['humidity'] as int?,
      pollenLevel: json['pollen_level'] as String?,
      locationName: json['location_name'] as String?,
      steps: json['steps'] as int?,
      sleepHours: json['sleep_hours'] != null
          ? (json['sleep_hours'] as num).toDouble()
          : null,
      respiratoryRate: json['respiratory_rate'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'measured_at': measuredAt.toIso8601String(),
      'pef': pef,
      'spo2': spo2,
      'heart_rate': heartRate,
      'symptoms': symptoms,
      'symptom_intensity': symptomIntensity,
      'notes': notes,
      'aqi': aqi,
      'temperature': temperature,
      'humidity': humidity,
      'pollen_level': pollenLevel,
      'location_name': locationName,
      'steps': steps,
      'sleep_hours': sleepHours,
      'respiratory_rate': respiratoryRate,
    };
  }
}
