import 'model_helpers.dart';

/// One day of balcony temperature history.
class BalconyDayTemp {
  final DateTime day;
  final double? dayAvg;
  final double? nightAvg;
  final double? overallAvg;
  final double? latest;

  const BalconyDayTemp({
    required this.day,
    this.dayAvg,
    this.nightAvg,
    this.overallAvg,
    this.latest,
  });

  factory BalconyDayTemp.fromMap(Map<String, dynamic> data) {
    return BalconyDayTemp(
      day: readDate(data, 'day') ?? DateTime.now(),
      dayAvg: readDouble(data, 'dayAvg'),
      nightAvg: readDouble(data, 'nightAvg'),
      overallAvg: readDouble(data, 'overallAvg'),
      latest: readDouble(data, 'latest'),
    );
  }
}
