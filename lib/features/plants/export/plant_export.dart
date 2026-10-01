import 'dart:convert';

import 'package:intl/intl.dart';
import 'package:plontukrot/core/l10n/app_localizations_x.dart';
import 'package:plontukrot/l10n/app_localizations.dart';
import 'package:share_plus/share_plus.dart';

import '../../../models/fertilizing_entry.dart';
import '../../../models/manipulation_entry.dart';
import '../../../models/manipulation_type.dart';
import '../../../models/note.dart';
import '../../../models/plant.dart';
import '../../../models/propagation.dart';
import '../../../models/repotting_entry.dart';
import '../../../models/watering_entry.dart';

enum PlantExportFormat { json, markdown }

class PlantCatalogExportRequest {
  final Set<PlantExportField> fields;
  final PlantExportFormat format;

  const PlantCatalogExportRequest({
    required this.fields,
    required this.format,
  });
}

/// Identity fields for the plant catalog export, in file order.
enum PlantExportField {
  createdAt,
  family,
  genus,
  species,
  cultivar,
  stage,
  nickname,
}

String plantExportFieldLabel(AppLocalizations l10n, PlantExportField field) {
  return switch (field) {
    PlantExportField.createdAt => l10n.plantDateAddedLabel,
    PlantExportField.family => l10n.plantFamily,
    PlantExportField.genus => l10n.plantGenus,
    PlantExportField.species => l10n.plantSpecies,
    PlantExportField.cultivar => l10n.plantCultivar,
    PlantExportField.stage => l10n.plantGrowthStage,
    PlantExportField.nickname => l10n.plantNickname,
  };
}

String calendarDay(DateTime date) {
  final local = date.toLocal();
  return DateFormat('yyyy-MM-dd').format(local);
}

Map<String, dynamic> plantIdentityPayload(
  Plant plant,
  AppLocalizations l10n,
  Set<PlantExportField> fields,
) {
  final payload = <String, dynamic>{};
  for (final field in PlantExportField.values) {
    if (!fields.contains(field)) continue;
    switch (field) {
      case PlantExportField.createdAt:
        final createdAt = plant.createdAt;
        payload['createdAt'] =
            createdAt == null ? null : calendarDay(createdAt);
      case PlantExportField.family:
        payload['family'] = plant.plantFamily?.trim() ?? '';
      case PlantExportField.genus:
        payload['genus'] = plant.genus.trim();
      case PlantExportField.species:
        payload['species'] = plant.species.trim();
      case PlantExportField.cultivar:
        payload['cultivar'] = plant.cultivarsDisplay;
      case PlantExportField.stage:
        payload['stage'] = l10n.stageTitle(plant.stage);
      case PlantExportField.nickname:
        payload['nickname'] = plant.nickname.trim();
    }
  }
  return payload;
}

List<String> plantExportFieldKeys(Set<PlantExportField> fields) {
  return [
    for (final field in PlantExportField.values)
      if (fields.contains(field)) _fieldKey(field),
  ];
}

String _fieldKey(PlantExportField field) {
  return switch (field) {
    PlantExportField.createdAt => 'createdAt',
    PlantExportField.family => 'family',
    PlantExportField.genus => 'genus',
    PlantExportField.species => 'species',
    PlantExportField.cultivar => 'cultivar',
    PlantExportField.stage => 'stage',
    PlantExportField.nickname => 'nickname',
  };
}

Map<String, dynamic> plantCatalogPayload({
  required String uid,
  required List<Plant> plants,
  required AppLocalizations l10n,
  required Set<PlantExportField> fields,
  DateTime? exportedAt,
}) {
  int comparePlants(Plant a, Plant b) {
    final speciesCmp =
        a.species.toLowerCase().compareTo(b.species.toLowerCase());
    if (speciesCmp != 0) return speciesCmp;
    return a.nickname.toLowerCase().compareTo(b.nickname.toLowerCase());
  }

  final grouped = <int, List<Plant>>{};
  for (final plant in plants) {
    grouped.putIfAbsent(plant.stage, () => <Plant>[]).add(plant);
  }
  final stageKeys = grouped.keys.toList()..sort();

  final stages = <Map<String, dynamic>>[];
  for (final stage in stageKeys) {
    final stagePlants = List<Plant>.from(grouped[stage]!)..sort(comparePlants);
    stages.add({
      'stage': l10n.stageTitle(stage),
      'count': stagePlants.length,
      'plants': [
        for (final plant in stagePlants)
          plantIdentityPayload(plant, l10n, fields),
      ],
    });
  }

  return {
    'uid': uid,
    'exportedAt': (exportedAt ?? DateTime.now()).toUtc().toIso8601String(),
    'fields': plantExportFieldKeys(fields),
    'count': plants.length,
    'stages': stages,
  };
}

class PlantJournalExport {
  final List<WateringEntry> waterings;
  final List<FertilizingEntry> fertilizings;
  final List<RepottingEntry> repottings;
  final List<ManipulationEntry> manipulations;
  final List<Note> notes;
  final List<Propagation> propagations;

  const PlantJournalExport({
    required this.waterings,
    required this.fertilizings,
    required this.repottings,
    required this.manipulations,
    required this.notes,
    required this.propagations,
  });
}

Map<String, dynamic> plantJournalPayload({
  required Plant plant,
  required PlantJournalExport journal,
  required AppLocalizations l10n,
  DateTime? exportedAt,
}) {
  final byDay = <String, List<_TimelineEvent>>{};

  void add(DateTime at, _TimelineEvent event) {
    byDay.putIfAbsent(calendarDay(at), () => []).add(event);
  }

  for (final entry in journal.waterings) {
    add(entry.wateredAt, _TimelineEvent(0, {'type': 'watering'}));
  }
  for (final entry in journal.fertilizings) {
    add(
      entry.appliedAt,
      _TimelineEvent(1, {
        'type': 'fertilizing',
        'fertilizer': l10n.fertilizerDisplayName(
          storedName: entry.fertilizerName,
          fertilizerId: entry.fertilizerId,
        ),
      }),
    );
  }
  for (final entry in journal.repottings) {
    add(
      entry.repottedAt,
      _TimelineEvent(2, {
        'type': 'repotting',
        'soil': l10n.soilDisplayName(entry.soilName),
      }),
    );
  }
  for (final entry in journal.manipulations) {
    add(entry.appliedAt, _TimelineEvent(3, _manipulationEvent(entry, l10n)));
  }
  for (final note in journal.notes) {
    final at = note.createdAt;
    final text = note.text.trim();
    if (at == null || text.isEmpty) continue;
    add(at, _TimelineEvent(4, {'type': 'note', 'text': text}));
  }
  for (final batch in journal.propagations) {
    add(batch.startedAt, _TimelineEvent(5, {'type': 'propagation'}));
  }

  final days = byDay.keys.toList()..sort();
  return {
    'exportedAt': (exportedAt ?? DateTime.now()).toUtc().toIso8601String(),
    'plant': plantIdentityPayload(plant, l10n, PlantExportField.values.toSet()),
    'propagationBatchCount': journal.propagations.length,
    'days': [
      for (final day in days)
        {
          'date': day,
          'events': [
            for (final event in (byDay[day]!..sort())) event.payload,
          ],
        },
    ],
  };
}

Map<String, dynamic> _manipulationEvent(
  ManipulationEntry entry,
  AppLocalizations l10n,
) {
  final payload = <String, dynamic>{
    'type': 'manipulation',
    'kind': l10n.manipulationTypeLabel(entry.type),
  };
  final note = entry.note?.trim();
  if (note != null && note.isNotEmpty) payload['note'] = note;
  if (entry.type == ManipulationType.stimulator) {
    final name = entry.stimulatorName?.trim();
    if (name != null && name.isNotEmpty) payload['stimulator'] = name;
    final dosage = entry.dosage?.trim();
    if (dosage != null && dosage.isNotEmpty) payload['dosage'] = dosage;
  }
  if (entry.type == ManipulationType.rerooting) {
    if (entry.reanimationTags.isNotEmpty) {
      payload['tags'] = [
        for (final tag in entry.reanimationTags) l10n.reanimationTagLabel(tag),
      ];
    }
    if (entry.isGreenhouse) payload['greenhouse'] = true;
    final endedAt = entry.endedAt;
    if (endedAt != null) payload['endedAt'] = calendarDay(endedAt);
    if (entry.stageBefore != null && entry.stageAfter != null) {
      payload['stageBefore'] = l10n.stageTitle(entry.stageBefore!);
      payload['stageAfter'] = l10n.stageTitle(entry.stageAfter!);
    }
  }
  return payload;
}

class _TimelineEvent implements Comparable<_TimelineEvent> {
  final int rank;
  final Map<String, dynamic> payload;

  const _TimelineEvent(this.rank, this.payload);

  @override
  int compareTo(_TimelineEvent other) => rank.compareTo(other.rank);
}

String plantCatalogMarkdown({
  required List<Plant> plants,
  required AppLocalizations l10n,
  required Set<PlantExportField> fields,
}) {
  final payload = plantCatalogPayload(
    uid: '',
    plants: plants,
    l10n: l10n,
    fields: fields,
  );
  final buffer = StringBuffer('# ${l10n.profileExportPlants}\n');
  final stages = payload['stages'] as List<Map<String, dynamic>>;
  for (final stage in stages) {
    buffer.writeln();
    buffer.writeln('## ${_mdInline('${stage['stage']}')}');
    final rows = stage['plants'] as List<Map<String, dynamic>>;
    for (final row in rows) {
      buffer.writeln();
      buffer.writeln('### ${_plantHeading(row, l10n)}');
      _writeIdentityLines(buffer, row, l10n);
    }
  }
  buffer.writeln();
  return buffer.toString();
}

String plantJournalMarkdown({
  required Plant plant,
  required PlantJournalExport journal,
  required AppLocalizations l10n,
}) {
  final payload = plantJournalPayload(
    plant: plant,
    journal: journal,
    l10n: l10n,
  );
  final identity = payload['plant'] as Map<String, dynamic>;
  final buffer = StringBuffer('# ${_plantHeading(identity, l10n)}\n');
  buffer.writeln();
  _writeIdentityLines(buffer, identity, l10n);
  buffer.writeln();
  buffer.writeln(
    '**${l10n.exportPropagationBatchCount(payload['propagationBatchCount'] as int)}**',
  );
  final days = payload['days'] as List<Map<String, dynamic>>;
  for (final day in days) {
    buffer.writeln();
    buffer.writeln('## ${day['date']}');
    buffer.writeln();
    final events = day['events'] as List<Map<String, dynamic>>;
    for (final event in events) {
      buffer.writeln('- ${_eventLine(event, l10n)}');
    }
  }
  buffer.writeln();
  return buffer.toString();
}

void _writeIdentityLines(
  StringBuffer buffer,
  Map<String, dynamic> row,
  AppLocalizations l10n,
) {
  for (final field in PlantExportField.values) {
    final key = _fieldKey(field);
    if (!row.containsKey(key)) continue;
    final value = row[key];
    if (value == null) continue;
    final text = '$value'.trim();
    if (text.isEmpty) continue;
    buffer.writeln(
      '- **${_mdInline(plantExportFieldLabel(l10n, field))}:** ${_mdInline(text)}',
    );
  }
}

String _plantHeading(Map<String, dynamic> row, AppLocalizations l10n) {
  for (final key in ['nickname', 'species', 'genus']) {
    final value = row[key];
    if (value is String && value.trim().isNotEmpty) {
      return _mdInline(value.trim());
    }
  }
  return _mdInline(l10n.commonUntitled);
}

String _eventLine(Map<String, dynamic> event, AppLocalizations l10n) {
  final type = event['type'];
  switch (type) {
    case 'watering':
      return _mdInline(l10n.watering);
    case 'fertilizing':
      return _mdInline('${l10n.fertilizing}: ${event['fertilizer']}');
    case 'repotting':
      return _mdInline('${l10n.repotting}: ${event['soil']}');
    case 'note':
      return _mdInline('${l10n.plantNote}: ${event['text']}');
    case 'propagation':
      return _mdInline(l10n.plantPropagation);
    case 'manipulation':
      return _mdInline(_manipulationLine(event, l10n));
    default:
      return _mdInline('$type');
  }
}

String _manipulationLine(Map<String, dynamic> event, AppLocalizations l10n) {
  final parts = <String>['${event['kind']}'];
  final stimulator = event['stimulator'];
  if (stimulator is String && stimulator.isNotEmpty) parts.add(stimulator);
  final dosage = event['dosage'];
  if (dosage is String && dosage.isNotEmpty) parts.add(dosage);
  final tags = event['tags'];
  if (tags is List && tags.isNotEmpty) parts.add(tags.join(', '));
  if (event['greenhouse'] == true) parts.add(l10n.reanimationGreenhouse);
  final endedAt = event['endedAt'];
  if (endedAt is String && endedAt.isNotEmpty) parts.add(endedAt);
  final before = event['stageBefore'];
  final after = event['stageAfter'];
  if (before is String && after is String) {
    parts.add(l10n.manipulationRerootingStageChange(before, after));
  }
  final note = event['note'];
  if (note is String && note.isNotEmpty) parts.add(note);
  return parts.join(' · ');
}

String _mdInline(String value) {
  return value
      .replaceAll('\\', r'\\')
      .replaceAll('\r\n', ' ')
      .replaceAll('\n', ' ')
      .replaceAll('*', r'\*')
      .replaceAll('_', r'\_')
      .replaceAll('`', r'\`')
      .replaceAll('[', r'\[');
}

Future<void> shareExportDocument({
  required String fileName,
  required String content,
  required PlantExportFormat format,
}) async {
  final bytes = utf8.encode(content);
  final mimeType = format == PlantExportFormat.json
      ? 'application/json'
      : 'text/markdown';
  await SharePlus.instance.share(
    ShareParams(
      files: [
        XFile.fromData(
          bytes,
          mimeType: mimeType,
          name: fileName,
        ),
      ],
      fileNameOverrides: [fileName],
    ),
  );
}

String exportFileName({
  required String baseName,
  required DateTime date,
  required PlantExportFormat format,
}) {
  final stamp = DateFormat('yyyy-MM-dd').format(date);
  final extension = format == PlantExportFormat.json ? 'json' : 'md';
  return '$baseName-$stamp.$extension';
}

String jsonExportContent(Map<String, dynamic> payload) {
  return const JsonEncoder.withIndent('  ').convert(payload);
}
