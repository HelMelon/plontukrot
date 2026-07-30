import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/plant.dart';
import '../models/variegation.dart';
import 'plant_species_service.dart';

class PlantService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final PlantSpeciesService _plantSpeciesService = PlantSpeciesService();

  final String uid = FirebaseAuth.instance.currentUser!.uid;

  CollectionReference<Map<String, dynamic>> get _plantsRef =>
      _firestore.collection('users').doc(uid).collection('plants');

  Future<void> addPlant({
    required String genus,
    required String species,
    String? cultivar,
    String? plantFamily,
    Variegation variegation = Variegation.none,
    String tradingName = '',
    String nickname = '',
    required int stage,
  }) async {
    final trimmedGenus = genus.trim();
    final trimmedSpecies = species.trim();
    final trimmedCultivar = cultivar?.trim();
    final trimmedFamily = plantFamily?.trim();
    final trimmedTradingName = tradingName.trim();

    await _plantsRef.add({
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
      'wateringFrequency': null,
      'createdAt': FieldValue.serverTimestamp(),
      'careHistoryMigrated': true,
      'botanicalFieldsMigrated': true,
    });

    await _plantSpeciesService.ensureSpecies(
      species: trimmedSpecies,
      genus: trimmedGenus,
      plantFamily: trimmedFamily,
    );
  }

  Stream<List<Plant>> getPlants() {
    return _plantsRef
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(Plant.fromFirestore).toList());
  }

  Stream<Plant?> watchPlant(String plantId) {
    return _plantsRef
        .doc(plantId)
        .snapshots()
        .map((doc) => doc.exists ? Plant.fromDocument(doc) : null);
  }

  Future<void> migrateCareDates(Iterable<Plant> plants) async {
    final plantsToMigrate = plants.where(
      (plant) => !plant.careHistoryMigrated,
    );

    await Future.wait(plantsToMigrate.map((plant) async {
      final plantRef = _plantsRef.doc(plant.id);
      final results = await Future.wait([
        plantRef
            .collection('watering')
            .orderBy('wateredAt', descending: true)
            .limit(1)
            .get(),
        plantRef
            .collection('fertilizing')
            .orderBy('appliedAt', descending: true)
            .limit(1)
            .get(),
      ]);
      final watering = results[0];
      final fertilizing = results[1];
      final updates = <String, dynamic>{'careHistoryMigrated': true};

      if (watering.docs.isNotEmpty) {
        updates['lastWateredAt'] = watering.docs.first.data()['wateredAt'];
      }
      if (fertilizing.docs.isNotEmpty) {
        updates['lastFertilizedAt'] =
            fertilizing.docs.first.data()['appliedAt'];
      }

      await plantRef.update(updates);
    }));
  }

  Future<void> migrateBotanicalFields(Iterable<Plant> plants) async {
    final plantsToMigrate =
        plants.where((plant) => !plant.botanicalFieldsMigrated).toList();

    await Future.wait(plantsToMigrate.map((plant) async {
      final plantRef = _plantsRef.doc(plant.id);
      final snap = await plantRef.get();
      final data = snap.data() ?? <String, dynamic>{};

      final species = (data['species'] as String? ??
              data['name'] as String? ??
              plant.species)
          .trim();
      final rawFamily =
          data['plantFamily'] as String? ?? data['family'] as String?;
      final trimmedFamily = rawFamily?.trim();
      final plantFamily =
          (trimmedFamily == null || trimmedFamily.isEmpty) ? null : trimmedFamily;
      final genus = (data['genus'] as String? ?? plant.genus).trim();

      await plantRef.update({
        'species': species,
        'genus': genus,
        'plantFamily': plantFamily,
        'name': FieldValue.delete(),
        'family': FieldValue.delete(),
        'botanicalFieldsMigrated': true,
      });
    }));

    final speciesSeed = <String, Plant>{};
    for (final plant in plants) {
      final species = plant.species.trim();
      if (species.isEmpty) continue;
      speciesSeed.putIfAbsent(species, () => plant);
    }
    // Re-read migrated values: use in-memory plants with fallbacks already applied.
    for (final entry in speciesSeed.entries) {
      final plant = entry.value;
      await _plantSpeciesService.ensureSpecies(
        species: entry.key,
        genus: plant.genus,
        plantFamily: plant.plantFamily,
      );
    }
  }

  Future<void> updatePlantImage({
    required String plantId,
    required String imageUrl,
  }) async {
    await _plantsRef.doc(plantId).update({'imageUrl': imageUrl});
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
    required int stage,
  }) async {
    final trimmedGenus = genus.trim();
    final trimmedSpecies = species.trim();
    final trimmedCultivar = cultivar?.trim();
    final trimmedFamily = plantFamily?.trim();
    final trimmedTradingName = tradingName.trim();

    await _plantsRef.doc(plantId).update({
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
      'stage': stage,
      'botanicalFieldsMigrated': true,
      'name': FieldValue.delete(),
      'family': FieldValue.delete(),
    });

    await _plantSpeciesService.ensureSpecies(
      species: trimmedSpecies,
      genus: trimmedGenus,
      plantFamily: trimmedFamily,
    );
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

  Future<void> deletePlants(Iterable<String> plantIds) async {
    final batch = _firestore.batch();

    for (final plantId in plantIds) {
      batch.delete(_plantsRef.doc(plantId));
    }

    await batch.commit();
  }
}
