class WeeklyTrendPoint {
  final DateTime date;
  final int value;
  final String source;

  WeeklyTrendPoint({
    required this.date,
    required this.value,
    required this.source,
  });

  factory WeeklyTrendPoint.fromJson(Map<String, dynamic> json) {
    return WeeklyTrendPoint(
      date: DateTime.parse(json['date']),
      value: json['value'],
      source: json['source'],
    );
  }
}

class WeeklyTrendResponse {
  final int? maxPef;
  final int? minPef;
  final int? avgPef;
  final List<WeeklyTrendPoint> dailyData;

  WeeklyTrendResponse({
    this.maxPef,
    this.minPef,
    this.avgPef,
    required this.dailyData,
  });

  factory WeeklyTrendResponse.fromJson(Map<String, dynamic> json) {
    return WeeklyTrendResponse(
      maxPef: json['max_pef'],
      minPef: json['min_pef'],
      avgPef: json['avg_pef'],
      dailyData:
          (json['daily_data'] as List<dynamic>?)
              ?.map((e) => WeeklyTrendPoint.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
