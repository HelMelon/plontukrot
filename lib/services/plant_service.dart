import '../core/season/fertilizing_season_controller.dart';
import '../models/fertilizing_frequency.dart';
import '../models/model_helpers.dart';
import '../models/plant.dart';
import '../models/plant_archive_reason.dart';
import '../models/plant_member.dart';
import '../models/plant_photo.dart';
import '../models/variegation.dart';
import 'api_client.dart';
import 'api_exception.dart';
import 'auth_service.dart';
import 'fertilizing_notification_service.dart';
import 'app_crash_reporting.dart';
import 'plant_species_service.dart';
import 'rest_stream.dart';
import 'storage_service.dart';

class PlantService {
  static const archiveRetention = Duration(days: 730);

  final ApiClient _api = ApiClient.instance;
  final PlantSpeciesService _plantSpeciesService = PlantSpeciesService();

  String get uid => AuthService().requireUid;

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
    try {
      final plant = await getPlant(plantId);
      if (plant != null) {
        await FertilizingNotificationService.instance.rescheduleForPlant(plant);
      }
    } catch (error, stack) {
      try {
        await AppCrashReporting.instance.recordError(
          error,
          stack,
          reason: 'plant_notification_reschedule_failed',
        );
      } catch (_) {}
    }
  }

  Future<List<PlantPhoto>> _fetchPhotos(String plantId) async {
    try {
      final list = jsonMapList(await _api.get('/plants/$plantId/photos'));
      final photos = list
          .map((m) => PlantPhoto.fromMap(m))
          .where((p) => p.imageUrl.isNotEmpty)
          .toList();
      photos.sort((a, b) => b.addedAt.compareTo(a.addedAt));
      return photos;
    } on ApiException {
      return const [];
    }
  }

  Plant _plantFrom(Map<String, dynamic> map, List<PlantPhoto> photos) {
    final id = readString(map, 'id') ?? '';
    final merged = Map<String, dynamic>.from(map);
    if (photos.isNotEmpty) {
      merged['images'] = photos.map((p) => p.toMap()).toList();
      merged['imageUrl'] = photos.first.imageUrl;
      merged['imageThumbUrl'] = photos.first.imageThumbUrl;
    }
    return Plant.fromMap(id, merged);
  }

  /// Parse a plant map, using the photos already embedded in the response
  /// (backend includes them in GET /plants). Keeps home grid to one request.
  Plant _plantFromMap(Map<String, dynamic> map) {
    final rawPhotos = readField(map, 'photos');
    final photos = (rawPhotos is List)
        ? rawPhotos
            .whereType<Map>()
            .map((e) => PlantPhoto.fromMap(Map<String, dynamic>.from(e)))
            .where((p) => p.imageUrl.isNotEmpty)
            .toList()
        : const <PlantPhoto>[];
    photos.sort((a, b) => b.addedAt.compareTo(a.addedAt));
    return _plantFrom(map, photos);
  }

  Future<List<Plant>> _fetchAllPlants() async {
    final list = jsonMapList(await _api.get('/plants'));
    return [for (final map in list) _plantFromMap(map)];
  }

  Future<void> markFertilizedToday(String plantId) async {
    final today = DateTime.now();
    final normalized = DateTime(today.year, today.month, today.day);
    await _patchPlant(plantId, {
      'last_fertilized_at': isoDate(normalized),
    });
    await _rescheduleNotifications(plantId);
  }

  Future<void> _patchPlant(String plantId, Map<String, dynamic> body) async {
    try {
      await _api.patch('/plants/$plantId', body: body);
    } on ApiException catch (error) {
      if (!error.isNotFound) rethrow;
    }
  }

  Future<void> recalculateAutoFertilizingFrequencies() async {
    final plants = await _fetchAllPlants();
    for (final plant in plants) {
      if (plant.isArchived || plant.isFertilizingFrequencyCustom) continue;
      final resolved = _resolveFertilizingFrequency(
        stage: plant.stage,
        isCustom: false,
        requestedFrequencyDays: null,
      );
      if (resolved != plant.fertilizingFrequencyDays) {
        await _patchPlant(plant.id, {
          'fertilizing_frequency_days': resolved,
        });
      }
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
    int? wateringFrequency,
    int? fertilizingFrequencyDays,
    bool isFertilizingFrequencyCustom = false,
  }) async {
    final trimmedGenus = genus.trim();
    final trimmedSpecies = species.trim();
    final trimmedCultivar = cultivar?.trim();
    final trimmedFamily = plantFamily?.trim();
    final trimmedTradingName = tradingName.trim();
    final safeInitialLeafCount = initialLeafCount < 0 ? 0 : initialLeafCount;
    final resolvedFrequency = _resolveFertilizingFrequency(
      stage: stage,
      isCustom: isFertilizingFrequencyCustom,
      requestedFrequencyDays: fertilizingFrequencyDays,
    );

    final created = jsonMap(
      await _api.post('/plants', body: {
        'genus': trimmedGenus,
        'species': trimmedSpecies,
        'cultivar':
            (trimmedCultivar == null || trimmedCultivar.isEmpty)
                ? null
                : trimmedCultivar,
        'plant_family':
            (trimmedFamily == null || trimmedFamily.isEmpty) ? null : trimmedFamily,
        'variegation': variegation.index,
        'trading_name': trimmedTradingName,
        'nickname': nickname,
        'stage': stage,
        'watering_frequency': wateringFrequency,
        'fertilizing_frequency_days': resolvedFrequency,
        'initial_leaf_count': safeInitialLeafCount,
      }),
    );
    final id = readString(created, 'id') ?? '';

    await _plantSpeciesService.ensureSpecies(
      species: trimmedSpecies,
      genus: trimmedGenus,
      plantFamily: trimmedFamily,
    );

    await _rescheduleNotifications(id);
    return id;
  }

  Stream<List<Plant>> getPlantsForUser(String ownerUid) {
    if (ownerUid != uid) {
      // Viewing another user's collection is not on the REST surface yet.
      return restPollStream(() async => <Plant>[]);
    }
    return restPollStream(() async {
      final plants = await _fetchAllPlants();
      return plants.where((plant) => !plant.isArchived).toList()
        ..sort((a, b) {
          final aAt = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final bAt = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          return bAt.compareTo(aAt);
        });
    });
  }

  Stream<List<Plant>> getPlants() => getPlantsForUser(uid);

  Stream<Plant?> watchPlantForUser(String ownerUid, String plantId) {
    return restPollStream(() => getPlant(plantId));
  }

  Stream<Plant?> watchPlant(String plantId) => watchPlantForUser(uid, plantId);

  Future<Plant?> getPlant(String plantId) async {
    final plants = await _fetchAllPlants();
    for (final plant in plants) {
      if (plant.id == plantId) return plant;
    }
    return null;
  }

  Stream<List<Plant>> watchArchivedPlants() {
    return restPollStream(() async {
      final plants = await _fetchAllPlants();
      return plants.where((plant) => plant.isArchiveVisible).toList()
        ..sort((a, b) {
          final aAt = a.archivedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final bAt = b.archivedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          return bAt.compareTo(aAt);
        });
    });
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
      'archived_at': isoDate(at),
      'expires_at': isoDate(at.add(archiveRetention)),
      'archive_reason': reason.code,
      if (trimmedNote != null && trimmedNote.isNotEmpty)
        'archive_note': trimmedNote,
      if (mergedIntoPlantId != null) 'merged_into_plant_id': mergedIntoPlantId,
      if (giftedToUid != null) 'gifted_to_uid': giftedToUid,
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
    await _patchPlant(
      plantId,
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

    final groupId = await addPlant(
      genus: genus,
      species: species,
      plantFamily: plantFamily,
      tradingName: tradingName,
      nickname: nickname,
      stage: stage,
      fertilizingFrequencyDays: fertilizingFrequencyDays,
      isFertilizingFrequencyCustom: isFertilizingFrequencyCustom,
      members: members,
    );

    final now = DateTime.now();
    for (final source in sources) {
      await archivePlant(
        plantId: source.id,
        reason: PlantArchiveReason.merged,
        at: now,
        mergedIntoPlantId: groupId,
      );
    }
    return groupId;
  }

  Future<void> purgeExpiredArchived() async {
    final now = DateTime.now();
    final plants = await _fetchAllPlants();
    for (final plant in plants) {
      if (!plant.isArchived) continue;
      final expires = plant.expiresAt;
      if (expires != null && expires.isBefore(now)) {
        await _deletePlantSubtree(plant.id);
      }
    }
  }

  Future<void> updatePlantImage({
    required String plantId,
    required String imageUrl,
    String? imageThumbUrl,
  }) async {
    await addPlantPhoto(
      plantId: plantId,
      photoId: DateTime.now().microsecondsSinceEpoch.toString(),
      imageUrl: imageUrl,
      imageThumbUrl: imageThumbUrl ?? imageUrl,
    );
  }

  Future<void> addPlantPhoto({
    required String plantId,
    required String photoId,
    required String imageUrl,
    required String imageThumbUrl,
    DateTime? addedAt,
  }) async {
    final photos = await _fetchPhotos(plantId);
    final evicted = <PlantPhoto>[];
    final next = List<PlantPhoto>.from(photos);
    while (next.length >= Plant.maxGalleryPhotos) {
      evicted.add(next.removeLast());
    }
    await _api.post('/plants/$plantId/photos', body: {
      'image_url': imageUrl,
      'image_thumb_url': imageThumbUrl,
      'is_legacy': photoId == PlantPhoto.legacyId,
    });
    for (final old in evicted) {
      await StorageService().deletePlantPhoto(plantId, old.id);
    }
  }

  Future<void> removePlantPhoto({
    required String plantId,
    required String photoId,
  }) async {
    await StorageService().deletePlantPhoto(plantId, photoId);
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
    final safeInitialLeafCount = initialLeafCount < 0 ? 0 : initialLeafCount;
    final resolvedFrequency = _resolveFertilizingFrequency(
      stage: stage,
      isCustom: isFertilizingFrequencyCustom,
      requestedFrequencyDays: fertilizingFrequencyDays,
    );

    await _patchPlant(plantId, {
      'genus': trimmedGenus,
      'species': trimmedSpecies,
      'cultivar':
          (trimmedCultivar == null || trimmedCultivar.isEmpty)
              ? null
              : trimmedCultivar,
      'plant_family':
          (trimmedFamily == null || trimmedFamily.isEmpty) ? null : trimmedFamily,
      'variegation': variegation.index,
      'trading_name': trimmedTradingName,
      'nickname': nickname,
      'watering_frequency': wateringFrequency,
      'fertilizing_frequency_days': resolvedFrequency,
      'initial_leaf_count': safeInitialLeafCount,
      'stage': stage,
    });

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
    final trimmed = plantFamily.trim();
    final value = trimmed.isEmpty ? null : trimmed;
    for (final plantId in plantIds) {
      await _patchPlant(plantId, {'plant_family': value});
    }
  }

  Future<void> _deletePlantSubtree(String plantId) async {
    try {
      await _api.delete('/plants/$plantId');
    } on ApiException catch (error) {
      if (!error.isNotFound) rethrow;
    }
    await FertilizingNotificationService.instance.cancelForPlant(plantId);
  }

  Future<void> deletePlants(Iterable<String> plantIds) async {
    for (final plantId in plantIds) {
      await _deletePlantSubtree(plantId);
    }
  }

  Future<void> deleteAllUserPlants() async {
    final plants = await _fetchAllPlants();
    for (final plant in plants) {
      await _deletePlantSubtree(plant.id);
    }
  }
}
