import 'plant.dart';

class PlantFilterCriteria {
  final bool propagatingOnly;
  final bool groupsOnly;
  final bool rerootingOnly;
  final bool quarantineOnly;
  final String? plantFamily;
  final String? genus;
  final String? cultivar;
  final int? stage;
  final String? presetId;
  final String? presetName;

  const PlantFilterCriteria({
    this.propagatingOnly = false,
    this.groupsOnly = false,
    this.rerootingOnly = false,
    this.quarantineOnly = false,
    this.plantFamily,
    this.genus,
    this.cultivar,
    this.stage,
    this.presetId,
    this.presetName,
  });

  static const empty = PlantFilterCriteria();

  bool get isEmpty =>
      !propagatingOnly &&
      !groupsOnly &&
      !rerootingOnly &&
      !quarantineOnly &&
      (plantFamily == null || plantFamily!.isEmpty) &&
      (genus == null || genus!.isEmpty) &&
      (cultivar == null || cultivar!.isEmpty) &&
      stage == null;

  bool get isActive => !isEmpty;

  int get activeCount {
    int count = 0;
    if (propagatingOnly) count++;
    if (groupsOnly) count++;
    if (rerootingOnly) count++;
    if (quarantineOnly) count++;
    if (plantFamily != null && plantFamily!.isNotEmpty) count++;
    if (genus != null && genus!.isNotEmpty) count++;
    if (cultivar != null && cultivar!.isNotEmpty) count++;
    if (stage != null) count++;
    return count;
  }

  bool matches(
    Plant plant, {
    required bool isPropagating,
    required bool isRerooting,
  }) {
    if (propagatingOnly && !isPropagating) return false;
    if (groupsOnly && !plant.isGroup) return false;
    if (rerootingOnly && !isRerooting) return false;
    if (quarantineOnly && !plant.isInQuarantine()) return false;
    if (plantFamily != null &&
        plantFamily!.isNotEmpty &&
        (plant.plantFamily ?? '').trim() != plantFamily) {
      return false;
    }
    if (genus != null &&
        genus!.isNotEmpty &&
        plant.genus.trim() != genus) {
      return false;
    }
    if (cultivar != null && cultivar!.isNotEmpty) {
      final matchCultivar = plant.cultivarLabels.any(
        (c) => c.toLowerCase() == cultivar!.toLowerCase(),
      );
      if (!matchCultivar) return false;
    }
    if (stage != null && plant.stage != stage) {
      return false;
    }
    return true;
  }

  PlantFilterCriteria copyWith({
    bool? propagatingOnly,
    bool? groupsOnly,
    bool? rerootingOnly,
    bool? quarantineOnly,
    String? plantFamily,
    bool clearPlantFamily = false,
    String? genus,
    bool clearGenus = false,
    String? cultivar,
    bool clearCultivar = false,
    int? stage,
    bool clearStage = false,
    String? presetId,
    bool clearPresetId = false,
    String? presetName,
    bool clearPresetName = false,
  }) {
    return PlantFilterCriteria(
      propagatingOnly: propagatingOnly ?? this.propagatingOnly,
      groupsOnly: groupsOnly ?? this.groupsOnly,
      rerootingOnly: rerootingOnly ?? this.rerootingOnly,
      quarantineOnly: quarantineOnly ?? this.quarantineOnly,
      plantFamily: clearPlantFamily ? null : (plantFamily ?? this.plantFamily),
      genus: clearGenus ? null : (genus ?? this.genus),
      cultivar: clearCultivar ? null : (cultivar ?? this.cultivar),
      stage: clearStage ? null : (stage ?? this.stage),
      presetId: clearPresetId ? null : (presetId ?? this.presetId),
      presetName: clearPresetName ? null : (presetName ?? this.presetName),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'propagatingOnly': propagatingOnly,
      'groupsOnly': groupsOnly,
      'rerootingOnly': rerootingOnly,
      'quarantineOnly': quarantineOnly,
      'plantFamily': plantFamily,
      'genus': genus,
      'cultivar': cultivar,
      'stage': stage,
      'presetId': presetId,
      'presetName': presetName,
    };
  }

  factory PlantFilterCriteria.fromMap(Map<String, dynamic> map) {
    return PlantFilterCriteria(
      propagatingOnly: map['propagatingOnly'] as bool? ?? false,
      groupsOnly: map['groupsOnly'] as bool? ?? false,
      rerootingOnly: map['rerootingOnly'] as bool? ?? false,
      quarantineOnly: map['quarantineOnly'] as bool? ?? false,
      plantFamily: map['plantFamily'] as String?,
      genus: map['genus'] as String?,
      cultivar: map['cultivar'] as String?,
      stage: map['stage'] as int?,
      presetId: map['presetId'] as String?,
      presetName: map['presetName'] as String?,
    );
  }
}

class PlantFilterPreset {
  final String id;
  final String name;
  final PlantFilterCriteria criteria;
  final DateTime createdAt;

  const PlantFilterPreset({
    required this.id,
    required this.name,
    required this.criteria,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'criteria': criteria.toMap(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory PlantFilterPreset.fromMap(Map<String, dynamic> map) {
    return PlantFilterPreset(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      criteria: PlantFilterCriteria.fromMap(
        (map['criteria'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
