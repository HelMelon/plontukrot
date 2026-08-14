import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../core/season/fertilizing_season_controller.dart';
import '../models/fertilizing_frequency.dart';
import '../models/plant.dart';
import '../models/plant_archive_reason.dart';
import '../models/plant_member.dart';
import '../models/plant_photo.dart';
import '../models/variegation.dart';
import 'fertilizing_notification_service.dart';
import 'plant_species_service.dart';
import 'storage_service.dart';

class PlantService {
  static const archiveRetention = Duration(days: 730);

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final PlantSpeciesService _plantSpeciesService = PlantSpeciesService();

  final String uid = FirebaseAuth.instance.currentUser!.uid;

  CollectionReference<Map<String, dynamic>> get _plantsRef =>
      _plantsRefFor(uid);

  CollectionReference<Map<String, dynamic>> _plantsRefFor(String ownerUid) =>
      _firestore.collection('users').doc(ownerUid).collection('plants');

  int? _resolveFertilizingFrequency({
    required int stage,
    required bool isCustom,
    int? requestedFrequencyDays,
  }) {
    return resolveFertilizingFrequencyDays(
      stage: stage,
      seasonSettings: FertilizingSeasonController.instance.settings,
      isCustom: isCustom,
      currentFrequencyDays: requestedFrequencyDays,
    );
  }

  Future<void> _rescheduleNotifications(String plantId) async {
    final plant = await getPlant(plantId);
    if (plant != null) {
      await FertilizingNotificationService.instance.rescheduleForPlant(plant);
    }
  }

  Future<void> markFertilizedToday(String plantId) async {
    final today = DateTime.now();
    final normalized = DateTime(today.year, today.month, today.day);
    await _plantsRef.doc(plantId).update({
      'lastFertilizedAt': Timestamp.fromDate(normalized),
    });
    await _rescheduleNotifications(plantId);
  }

  /// Recomputes auto fertilizing frequency for plants without custom override.
  Future<void> recalculateAutoFertilizingFrequencies() async {
    final snapshot = await _plantsRef.get();
    final batch = _firestore.batch();
    var hasUpdates = false;

    for (final doc in snapshot.docs) {
      final plant = Plant.fromFirestore(doc);
      if (plant.isArchived || plant.isFertilizingFrequencyCustom) continue;
      final resolved = _resolveFertilizingFrequency(
        stage: plant.stage,
        isCustom: false,
        requestedFrequencyDays: null,
      );
      if (resolved != plant.fertilizingFrequencyDays) {
        batch.update(doc.reference, {'fertilizingFrequencyDays': resolved});
        hasUpdates = true;
      }
    }

    if (hasUpdates) {
      await batch.commit();
    }
  }

  Future<String> addPlant({
    required String genus,
    required String species,
    String? cultivar,
    String? plantFamily,
    Variegation variegation = Variegation.none,
    String tradingName = '',
    String nickname = '',
    required int stage,
    int initialLeafCount = 0,
    List<PlantMember> members = const [],
    int? fertilizingFrequencyDays,
    bool isFertilizingFrequencyCustom = false,
  }) async {
    final trimmedGenus = genus.trim();
    final trimmedSpecies = species.trim();
    final trimmedCultivar = cultivar?.trim();
    final trimmedFamily = plantFamily?.trim();
    final trimmedTradingName = tradingName.trim();
    final safeInitialLeafCount =
        initialLeafCount < 0 ? 0 : initialLeafCount;
    final resolvedFrequency = _resolveFertilizingFrequency(
      stage: stage,
      isCustom: isFertilizingFrequencyCustom,
      requestedFrequencyDays: fertilizingFrequencyDays,
    );

    final doc = await _plantsRef.add({
      'genus': trimmedGenus,
      'species': trimmedSpecies,
      'cultivar':
          (trimmedCultivar == null || trimmedCultivar.isEmpty)
              ? null
              : trimmedCultivar,
      'plantFamily':
          (trimmedFamily == null || trimmedFamily.isEmpty) ? null : trimmedFamily,
      'variegation': variegation.storageValue,
      'tradingName': trimmedTradingName,
      'nickname': nickname,
      'stage': stage,
      'imageUrl': null,
      'imageThumbUrl': null,
      'images': <Map<String, dynamic>>[],
      'wateringFrequency': null,
      'fertilizingFrequencyDays': resolvedFrequency,
      'isFertilizingFrequencyCustom': isFertilizingFrequencyCustom,
      'initialLeafCount': safeInitialLeafCount,
      if (members.isNotEmpty) 'members': members.map((m) => m.toMap()).toList(),
      'createdAt': FieldValue.serverTimestamp(),
    });

    await _plantSpeciesService.ensureSpecies(
      species: trimmedSpecies,
      genus: trimmedGenus,
      plantFamily: trimmedFamily,
    );

    await _rescheduleNotifications(doc.id);
    return doc.id;
  }

  /// Active plants for [ownerUid] (own or friend-visible collection).
  Stream<List<Plant>> getPlantsForUser(String ownerUid) {
    return _plantsRefFor(ownerUid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(Plant.fromFirestore)
              .where((plant) => !plant.isArchived)
              .toList(),
        );
  }

  Stream<List<Plant>> getPlants() => getPlantsForUser(uid);

  Stream<Plant?> watchPlantForUser(String ownerUid, String plantId) {
    return _plantsRefFor(ownerUid)
        .doc(plantId)
        .snapshots()
        .map((doc) => doc.exists ? Plant.fromDocument(doc) : null);
  }

  Stream<Plant?> watchPlant(String plantId) => watchPlantForUser(uid, plantId);

  Future<Plant?> getPlant(String plantId) async {
    final doc = await _plantsRef.doc(plantId).get();
    if (!doc.exists) return null;
    return Plant.fromDocument(doc);
  }

  Stream<List<Plant>> watchArchivedPlants() {
    return _plantsRef
        .orderBy('archivedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(Plant.fromFirestore)
              .where((plant) => plant.isArchiveVisible)
              .toList(),
        );
  }

  Map<String, dynamic> _archiveFields({
    required PlantArchiveReason reason,
    required DateTime at,
    String? note,
    String? mergedIntoPlantId,
    String? giftedToUid,
  }) {
    final trimmedNote = note?.trim();
    return {
      'archivedAt': Timestamp.fromDate(at),
      'expiresAt': Timestamp.fromDate(at.add(archiveRetention)),
      'archiveReason': reason.code,
      if (trimmedNote != null && trimmedNote.isNotEmpty)
        'archiveNote': trimmedNote,
      if (mergedIntoPlantId != null) 'mergedIntoPlantId': mergedIntoPlantId,
      if (giftedToUid != null) 'giftedToUid': giftedToUid,
    };
  }

  Future<void> archivePlant({
    required String plantId,
    required PlantArchiveReason reason,
    DateTime? at,
    String? note,
    String? mergedIntoPlantId,
    String? giftedToUid,
  }) async {
    final when = at ?? DateTime.now();
    await _plantsRef.doc(plantId).update(
          _archiveFields(
            reason: reason,
            at: when,
            note: note,
            mergedIntoPlantId: mergedIntoPlantId,
            giftedToUid: giftedToUid,
          ),
        );
    await FertilizingNotificationService.instance.cancelForPlant(plantId);
  }

  Future<String> mergePlants({
    required List<Plant> sources,
    required String genus,
    required String species,
    String? plantFamily,
    required List<PlantMember> members,
    String tradingName = '',
    String nickname = '',
    required int stage,
    int? fertilizingFrequencyDays,
    bool isFertilizingFrequencyCustom = false,
  }) async {
    if (sources.length < 2 || sources.length > 3) {
      throw ArgumentError('Merge requires 2–3 source plants');
    }
    if (members.length < 2 || members.length > 3) {
      throw ArgumentError('Group must have 2–3 members');
    }
    final genera = sources.map((p) => p.genus.trim().toLowerCase()).toSet();
    if (genera.length != 1) {
      throw ArgumentError('All source plants must share the same genus');
    }

    final trimmedGenus = genus.trim();
    final trimmedSpecies = species.trim();
    final trimmedFamily = plantFamily?.trim();
    final trimmedTradingName = tradingName.trim();
    final now = DateTime.now();
    final resolvedFrequency = _resolveFertilizingFrequency(
      stage: stage,
      isCustom: isFertilizingFrequencyCustom,
      requestedFrequencyDays: fertilizingFrequencyDays,
    );

    final groupRef = _plantsRef.doc();
    final batch = _firestore.batch();

    batch.set(groupRef, {
      'genus': trimmedGenus,
      'species': trimmedSpecies,
      'cultivar': null,
      'plantFamily':
          (trimmedFamily == null || trimmedFamily.isEmpty) ? null : trimmedFamily,
      'variegation': Variegation.none.storageValue,
      'tradingName': trimmedTradingName,
      'nickname': nickname,
      'stage': stage,
      'imageUrl': null,
      'imageThumbUrl': null,
      'images': <Map<String, dynamic>>[],
      'wateringFrequency': null,
      'fertilizingFrequencyDays': resolvedFrequency,
      'isFertilizingFrequencyCustom': isFertilizingFrequencyCustom,
      'initialLeafCount': 0,
      'createdAt': FieldValue.serverTimestamp(),
      'members': members.take(3).map((m) => m.toMap()).toList(),
    });

    for (final source in sources) {
      batch.update(
        _plantsRef.doc(source.id),
        _archiveFields(
          reason: PlantArchiveReason.merged,
          at: now,
          mergedIntoPlantId: groupRef.id,
        ),
      );
    }

    await batch.commit();

    await _plantSpeciesService.ensureSpecies(
      species: trimmedSpecies,
      genus: trimmedGenus,
      plantFamily: trimmedFamily,
    );

    await _rescheduleNotifications(groupRef.id);
    return groupRef.id;
  }

  Future<void> purgeExpiredArchived() async {
    final now = DateTime.now();
    final snapshot = await _plantsRef
        .where('expiresAt', isLessThan: Timestamp.fromDate(now))
        .get();

    for (final doc in snapshot.docs) {
      final plant = Plant.fromFirestore(doc);
      if (!plant.isArchived) continue;
      await _deletePlantSubtree(plant.id);
    }
  }

  Future<void> updatePlantImage({
    required String plantId,
    required String imageUrl,
    String? imageThumbUrl,
  }) async {
    await _plantsRef.doc(plantId).update({
      'imageUrl': imageUrl,
      if (imageThumbUrl != null) 'imageThumbUrl': imageThumbUrl,
    });
  }

  /// Prepends a gallery photo (newest first). If the plant already has
  /// [Plant.maxGalleryPhotos], the oldest photo is deleted first.
  Future<void> addPlantPhoto({
    required String plantId,
    required String photoId,
    required String imageUrl,
    required String imageThumbUrl,
    DateTime? addedAt,
  }) async {
    final doc = await _plantsRef.doc(plantId).get();
    if (!doc.exists) {
      throw StateError('Plant $plantId not found');
    }
    final plant = Plant.fromDocument(doc);
    final photos = List<PlantPhoto>.from(plant.galleryPhotos);
    final storage = StorageService();
    final evicted = <PlantPhoto>[];

    while (photos.length >= Plant.maxGalleryPhotos) {
      evicted.add(photos.removeLast());
    }

    photos.insert(
      0,
      PlantPhoto(
        id: photoId,
        imageUrl: imageUrl,
        imageThumbUrl: imageThumbUrl,
        addedAt: addedAt ?? DateTime.now(),
      ),
    );

    await _plantsRef.doc(plantId).update(_galleryWritePayload(photos));

    for (final old in evicted) {
      await storage.deletePlantPhoto(plantId, old.id);
    }
  }

  Future<void> removePlantPhoto({
    required String plantId,
    required String photoId,
  }) async {
    final doc = await _plantsRef.doc(plantId).get();
    if (!doc.exists) {
      throw StateError('Plant $plantId not found');
    }
    final plant = Plant.fromDocument(doc);
    final photos = List<PlantPhoto>.from(plant.galleryPhotos);
    final removed = photos.where((p) => p.id == photoId).toList();
    if (removed.isEmpty) return;

    photos.removeWhere((p) => p.id == photoId);
    await _plantsRef.doc(plantId).update(_galleryWritePayload(photos));

    final storage = StorageService();
    for (final photo in removed) {
      await storage.deletePlantPhoto(plantId, photo.id);
    }
  }

  Map<String, dynamic> _galleryWritePayload(List<PlantPhoto> photos) {
    if (photos.isEmpty) {
      return {
        'images': <Map<String, dynamic>>[],
        'imageUrl': null,
        'imageThumbUrl': null,
      };
    }
    final newest = photos.first;
    return {
      'images': photos.map((p) => p.toMap()).toList(),
      'imageUrl': newest.imageUrl,
      'imageThumbUrl': newest.imageThumbUrl,
    };
  }

  Future<void> updatePlant({
    required String plantId,
    required String genus,
    required String species,
    String? cultivar,
    String? plantFamily,
    Variegation variegation = Variegation.none,
    String tradingName = '',
    required String nickname,
    int? wateringFrequency,
    int initialLeafCount = 0,
    required int stage,
    List<PlantMember>? members,
    int? fertilizingFrequencyDays,
    bool isFertilizingFrequencyCustom = false,
  }) async {
    final trimmedGenus = genus.trim();
    final trimmedSpecies = species.trim();
    final trimmedCultivar = cultivar?.trim();
    final trimmedFamily = plantFamily?.trim();
    final trimmedTradingName = tradingName.trim();
    final safeInitialLeafCount =
        initialLeafCount < 0 ? 0 : initialLeafCount;
    final resolvedFrequency = _resolveFertilizingFrequency(
      stage: stage,
      isCustom: isFertilizingFrequencyCustom,
      requestedFrequencyDays: fertilizingFrequencyDays,
    );

    final updates = <String, dynamic>{
      'genus': trimmedGenus,
      'species': trimmedSpecies,
      'cultivar':
          (trimmedCultivar == null || trimmedCultivar.isEmpty)
              ? null
              : trimmedCultivar,
      'plantFamily':
          (trimmedFamily == null || trimmedFamily.isEmpty) ? null : trimmedFamily,
      'variegation': variegation.storageValue,
      'tradingName': trimmedTradingName,
      'nickname': nickname,
      'wateringFrequency': wateringFrequency,
      'fertilizingFrequencyDays': resolvedFrequency,
      'isFertilizingFrequencyCustom': isFertilizingFrequencyCustom,
      'initialLeafCount': safeInitialLeafCount,
      'stage': stage,
      'name': FieldValue.delete(),
      'family': FieldValue.delete(),
    };

    if (members != null) {
      final capped = members.take(3).toList();
      updates['members'] = capped.map((m) => m.toMap()).toList();
      if (capped.length >= 2) {
        updates['cultivar'] = null;
      }
    }

    await _plantsRef.doc(plantId).update(updates);

    await _plantSpeciesService.ensureSpecies(
      species: trimmedSpecies,
      genus: trimmedGenus,
      plantFamily: trimmedFamily,
    );

    await _rescheduleNotifications(plantId);
  }

  Future<void> updatePlantsPlantFamily({
    required Iterable<String> plantIds,
    required String plantFamily,
  }) async {
    final batch = _firestore.batch();
    final trimmed = plantFamily.trim();
    final value = trimmed.isEmpty ? null : trimmed;

    for (final plantId in plantIds) {
      batch.update(
        _plantsRef.doc(plantId),
        {'plantFamily': value},
      );
    }

    await batch.commit();
  }

  Future<void> _deleteQueryInBatches(
    Query<Map<String, dynamic>> query, {
    int pageSize = 200,
  }) async {
    while (true) {
      final snapshot = await query.limit(pageSize).get();
      if (snapshot.docs.isEmpty) break;

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      if (snapshot.docs.length < pageSize) break;
    }
  }

  Future<void> _deletePlantSubtree(String plantId) async {
    final plantRef = _plantsRef.doc(plantId);
    final plantSnap = await plantRef.get();
    final plant = plantSnap.exists ? Plant.fromDocument(plantSnap) : null;

    await _deleteQueryInBatches(plantRef.collection('watering'));
    await _deleteQueryInBatches(plantRef.collection('fertilizing'));
    await _deleteQueryInBatches(plantRef.collection('repotting'));
    await _deleteQueryInBatches(plantRef.collection('notes'));
    await _deleteQueryInBatches(plantRef.collection('growthEvents'));

    final propagations = await _firestore
        .collection('users')
        .doc(uid)
        .collection('propagations')
        .where('parentPlantId', isEqualTo: plantId)
        .get();

    for (final prop in propagations.docs) {
      await _deleteQueryInBatches(prop.reference.collection('stageHistory'));
      await _deleteQueryInBatches(prop.reference.collection('notes'));
      await prop.reference.delete();
    }

    await StorageService().deleteAllPlantImages(
      plantId: plantId,
      photoIds: plant?.galleryPhotos.map((p) => p.id) ?? const <String>[],
    );
    await plantRef.delete();
  }

  Future<void> deletePlants(Iterable<String> plantIds) async {
    for (final plantId in plantIds) {
      await _deletePlantSubtree(plantId);
    }
  }

  /// Deletes every plant document (active + archived) and their subtrees.
  Future<void> deleteAllUserPlants() async {
    while (true) {
      final snapshot = await _plantsRef.limit(50).get();
      if (snapshot.docs.isEmpty) break;
      for (final doc in snapshot.docs) {
        await _deletePlantSubtree(doc.id);
      }
      if (snapshot.docs.length < 50) break;
    }
  }
}
