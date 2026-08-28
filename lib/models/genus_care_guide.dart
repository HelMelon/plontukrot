import 'model_helpers.dart';

/// Care guide and botanical overview for a plant genus.
class GenusCareGuide {
  final String genus;
  final String? origin;
  final String? light;
  final String? watering;
  final String? fertilizing;
  final String? soil;
  final String? humidity;
  final String? toxicity;

  const GenusCareGuide({
    required this.genus,
    this.origin,
    this.light,
    this.watering,
    this.fertilizing,
    this.soil,
    this.humidity,
    this.toxicity,
  });

  bool get isEmpty =>
      (origin == null || origin!.isEmpty) &&
      (light == null || light!.isEmpty) &&
      (watering == null || watering!.isEmpty) &&
      (fertilizing == null || fertilizing!.isEmpty) &&
      (soil == null || soil!.isEmpty) &&
      (humidity == null || humidity!.isEmpty) &&
      (toxicity == null || toxicity!.isEmpty);

  bool get isNotEmpty => !isEmpty;

  factory GenusCareGuide.fromMap(Map<String, dynamic> data) {
    return GenusCareGuide(
      genus: readString(data, 'genus') ?? '',
      origin: readString(data, 'origin')?.trim(),
      light: readString(data, 'light')?.trim(),
      watering: readString(data, 'watering')?.trim(),
      fertilizing: readString(data, 'fertilizing')?.trim(),
      soil: readString(data, 'soil')?.trim(),
      humidity: readString(data, 'humidity')?.trim(),
      toxicity: readString(data, 'toxicity')?.trim(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'genus': genus,
      if (origin != null) 'origin': origin,
      if (light != null) 'light': light,
      if (watering != null) 'watering': watering,
      if (fertilizing != null) 'fertilizing': fertilizing,
      if (soil != null) 'soil': soil,
      if (humidity != null) 'humidity': humidity,
      if (toxicity != null) 'toxicity': toxicity,
    };
  }
}
