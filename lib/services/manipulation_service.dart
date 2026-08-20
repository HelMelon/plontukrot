import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/manipulation_entry.dart';
import '../models/manipulation_type.dart';

class ManipulationService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String get uid => FirebaseAuth.instance.currentUser!.uid;

  DocumentReference<Map<String, dynamic>> _plantRef(String plantId) {
    return _db.collection('users').doc(uid).collection('plants').doc(plantId);
  }

  CollectionReference<Map<String, dynamic>> _manipulationsRef(String plantId) {
    return _plantRef(plantId).collection('manipulations');
  }

  Future<void> _syncLastManipulationAt(String plantId) async {
    final snapshot = await _manipulationsRef(plantId)
        .orderBy('appliedAt', descending: true)
        .limit(1)
        .get();

    await _plantRef(plantId).update({
      'lastManipulationAt': snapshot.docs.isEmpty
          ? FieldValue.delete()
          : snapshot.docs.first.data()['appliedAt'],
    });
  }

  static String? _trimOrNull(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static void _validateStimulatorName(String? name) {
    if (_trimOrNull(name) == null) {
      throw ArgumentError('stimulatorName is required for stimulator type');
    }
  }

  Map<String, dynamic> _buildEntryData({
    required ManipulationType type,
    required DateTime appliedAt,
    String? note,
    int? stageBefore,
    int? stageAfter,
    String? stimulatorId,
    String? stimulatorName,
    String? dosage,
  }) {
    if (type == ManipulationType.stimulator) {
      _validateStimulatorName(stimulatorName);
    }

    return {
      'type': type.code,
      'appliedAt': Timestamp.fromDate(appliedAt),
      if (_trimOrNull(note) != null) 'note': _trimOrNull(note),
      if (type == ManipulationType.rerooting && stageBefore != null)
        'stageBefore': stageBefore,
      if (type == ManipulationType.rerooting && stageAfter != null)
        'stageAfter': stageAfter,
      if (type == ManipulationType.stimulator) ...{
        if (stimulatorId != null) 'stimulatorId': stimulatorId,
        'stimulatorName': _trimOrNull(stimulatorName),
        if (_trimOrNull(dosage) != null) 'dosage': _trimOrNull(dosage),
      },
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  Future<void> addManipulation({
    required String plantId,
    required ManipulationType type,
    required DateTime appliedAt,
    String? note,
    int? stageAfter,
    String? stimulatorId,
    String? stimulatorName,
    String? dosage,
  }) async {
    int? stageBefore;
    if (type == ManipulationType.rerooting) {
      final plantDoc = await _plantRef(plantId).get();
      stageBefore = plantDoc.data()?['stage'] as int? ?? 0;
    }

    final batch = _db.batch();
    final entryRef = _manipulationsRef(plantId).doc();
    batch.set(
      entryRef,
      _buildEntryData(
        type: type,
        appliedAt: appliedAt,
        note: note,
        stageBefore: stageBefore,
        stageAfter: stageAfter,
        stimulatorId: stimulatorId,
        stimulatorName: stimulatorName,
        dosage: dosage,
      ),
    );

    final plantUpdates = <String, dynamic>{
      'lastManipulationAt': Timestamp.fromDate(appliedAt),
    };
    if (type == ManipulationType.rerooting && stageAfter != null) {
      plantUpdates['stage'] = stageAfter;
    }
    batch.update(_plantRef(plantId), plantUpdates);

    await batch.commit();
  }

  Future<void> updateManipulation({
    required String plantId,
    required String manipulationId,
    required ManipulationType type,
    required DateTime appliedAt,
    String? note,
    int? stageBefore,
    int? stageAfter,
    String? stimulatorId,
    String? stimulatorName,
    String? dosage,
  }) async {
    if (type == ManipulationType.stimulator) {
      _validateStimulatorName(stimulatorName);
    }

    final entryRef = _manipulationsRef(plantId).doc(manipulationId);
    final existing = await entryRef.get();
    if (!existing.exists) return;

    final existingData = existing.data()!;
    final resolvedStageBefore = type == ManipulationType.rerooting
        ? (stageBefore ?? existingData['stageBefore'] as int?)
        : null;

    final data = <String, dynamic>{
      'type': type.code,
      'appliedAt': Timestamp.fromDate(appliedAt),
      'note': _trimOrNull(note) ?? FieldValue.delete(),
      'stageBefore': FieldValue.delete(),
      'stageAfter': FieldValue.delete(),
      'stimulatorId': FieldValue.delete(),
      'stimulatorName': FieldValue.delete(),
      'dosage': FieldValue.delete(),
    };

    if (type == ManipulationType.rerooting) {
      if (resolvedStageBefore != null) {
        data['stageBefore'] = resolvedStageBefore;
      }
      if (stageAfter != null) {
        data['stageAfter'] = stageAfter;
      }
    } else if (type == ManipulationType.stimulator) {
      if (stimulatorId != null) data['stimulatorId'] = stimulatorId;
      data['stimulatorName'] = _trimOrNull(stimulatorName);
      final trimmedDosage = _trimOrNull(dosage);
      if (trimmedDosage != null) data['dosage'] = trimmedDosage;
    }

    final batch = _db.batch();
    batch.update(entryRef, data);

    if (type == ManipulationType.rerooting && stageAfter != null) {
      batch.update(_plantRef(plantId), {'stage': stageAfter});
    }

    await batch.commit();
    await _syncLastManipulationAt(plantId);
  }

  Future<void> deleteManipulation({
    required String plantId,
    required String manipulationId,
  }) async {
    await _manipulationsRef(plantId).doc(manipulationId).delete();
    await _syncLastManipulationAt(plantId);
  }

  Stream<List<ManipulationEntry>> getManipulationHistory(
    String plantId, {
    int limit = 40,
  }) {
    return _manipulationsRef(plantId)
        .orderBy('appliedAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map(ManipulationEntry.fromFirestore).toList(),
        );
  }
}
