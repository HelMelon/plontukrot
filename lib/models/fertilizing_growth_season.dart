/// Active growth season for fertilizing frequency lookup.
enum FertilizingGrowthSeason {
  springSummer,
  autumnWinter,
}

/// How spring/summer month boundaries are resolved.
enum FertilizingSeasonMode {
  /// April–September vs October–March (northern hemisphere default).
  northern,

  /// Opposite of [northern].
  southern,

  /// User-defined [springStartMonth]–[springEndMonth].
  custom,
}

/// User settings for determining the current fertilizing season by calendar month.
class FertilizingSeasonSettings {
  static const northernSpringStart = 4;
  static const northernSpringEnd = 9;

  final FertilizingSeasonMode mode;
  final int springStartMonth;
  final int springEndMonth;

  const FertilizingSeasonSettings({
    this.mode = FertilizingSeasonMode.northern,
    this.springStartMonth = northernSpringStart,
    this.springEndMonth = northernSpringEnd,
  });

  FertilizingSeasonSettings copyWith({
    FertilizingSeasonMode? mode,
    int? springStartMonth,
    int? springEndMonth,
  }) {
    return FertilizingSeasonSettings(
      mode: mode ?? this.mode,
      springStartMonth: springStartMonth ?? this.springStartMonth,
      springEndMonth: springEndMonth ?? this.springEndMonth,
    );
  }

  /// Effective month range for spring/summer after applying [mode].
  (int start, int end) get effectiveSpringRange {
    return switch (mode) {
      FertilizingSeasonMode.northern => (
          northernSpringStart,
          northernSpringEnd,
        ),
      FertilizingSeasonMode.southern => (
          northernSpringEnd + 1 > 12 ? 1 : northernSpringEnd + 1,
          northernSpringStart - 1 < 1 ? 12 : northernSpringStart - 1,
        ),
      FertilizingSeasonMode.custom => (
          _clampMonth(springStartMonth),
          _clampMonth(springEndMonth),
        ),
    };
  }

  /// Resolves growth season for [month] (1–12) using configured boundaries.
  FertilizingGrowthSeason growthSeasonForMonth(int month) {
    final (start, end) = effectiveSpringRange;
    if (_monthInRange(_clampMonth(month), start, end)) {
      return FertilizingGrowthSeason.springSummer;
    }
    return FertilizingGrowthSeason.autumnWinter;
  }

  /// Resolves growth season for [when] using its calendar month.
  FertilizingGrowthSeason growthSeasonForDate(DateTime when) {
    return growthSeasonForMonth(when.month);
  }

  factory FertilizingSeasonSettings.fromMap(Map<String, dynamic>? data) {
    if (data == null) return const FertilizingSeasonSettings();
    final modeRaw = data['fertilizingSeasonMode'] as String?;
    final mode = FertilizingSeasonMode.values.firstWhere(
      (m) => m.name == modeRaw,
      orElse: () => FertilizingSeasonMode.northern,
    );
    return FertilizingSeasonSettings(
      mode: mode,
      springStartMonth:
          _clampMonth(data['fertilizingSpringStartMonth'] as int? ?? northernSpringStart),
      springEndMonth:
          _clampMonth(data['fertilizingSpringEndMonth'] as int? ?? northernSpringEnd),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fertilizingSeasonMode': mode.name,
      'fertilizingSpringStartMonth': springStartMonth,
      'fertilizingSpringEndMonth': springEndMonth,
    };
  }

  static int _clampMonth(int month) {
    if (month < 1) return 1;
    if (month > 12) return 12;
    return month;
  }

  static bool _monthInRange(int month, int start, int end) {
    if (start <= end) {
      return month >= start && month <= end;
    }
    return month >= start || month <= end;
  }
}
