import '../models/model_helpers.dart';
import '../models/incoming_gift.dart';
import '../models/plant.dart';
import '../models/plant_archive_reason.dart';
import 'api_client.dart';
import 'auth_service.dart';
import 'friends_service.dart';
import 'plant_service.dart';
import 'rest_stream.dart';

class GiftService {
  final ApiClient _api = ApiClient.instance;
  final PlantService _plantService = PlantService();
  final FriendsService _friendsService = FriendsService();

  String get uid => AuthService().requireUid;

  Stream<List<IncomingGift>> watchIncomingGifts() {
    return restPollStream(() async {
      final list = jsonMapList(await _api.get('/gifts/incoming'));
      return list
          .map((m) => IncomingGift.fromMap(readString(m, 'id') ?? '', m))
          .where((g) => g.status == GiftStatus.pending)
          .toList();
    });
  }

  Stream<List<OutgoingGift>> watchOutgoingGifts() {
    return restPollStream(() async {
      final list = jsonMapList(await _api.get('/gifts/outgoing'));
      return list
          .map((m) => OutgoingGift.fromMap(readString(m, 'id') ?? '', m))
          .toList();
    });
  }

  Map<String, dynamic> _plantSnapshot(Plant plant) => plant.toMap();

  Future<void> sendGift({
    required Plant plant,
    required String recipientUid,
    String? message,
  }) async {
    final recipient = recipientUid.trim();
    if (plant.isArchived) {
      throw StateError('Cannot gift an archived plant');
    }
    if (!await _friendsService.areFriends(recipient)) {
      throw StateError('Recipient must be a friend');
    }
    await _api.post('/gifts/outgoing', body: {
      'to_uid': recipient,
      'from_plant_id': plant.id,
      'plant_snapshot': _plantSnapshot(plant),
      'status': GiftStatus.pending.index,
    });
  }

  Future<void> declineGift(IncomingGift gift) async {
    try {
      await _api.patch('/gifts/incoming/${gift.id}', body: {
        'status': GiftStatus.declined.index,
      });
    } catch (_) {}
  }

  Future<String> acceptGift(IncomingGift gift) async {
    final preview = gift.previewPlant;
    final newPlantId = await _plantService.addPlant(
      genus: preview.genus,
      species: preview.species,
      cultivar: preview.cultivar,
      plantFamily: preview.plantFamily,
      variegation: preview.variegation,
      tradingName: preview.tradingName,
      nickname: preview.nickname,
      stage: preview.stage,
      initialLeafCount: preview.initialLeafCount,
      members: preview.members,
    );
    try {
      await _api.patch('/gifts/incoming/${gift.id}', body: {
        'status': GiftStatus.accepted.index,
      });
    } catch (_) {}
    return newPlantId;
  }

  Future<void> processAcceptedOutgoingGifts() async {
    final list = jsonMapList(await _api.get('/gifts/outgoing'));
    for (final map in list) {
      final gift = OutgoingGift.fromMap(readString(map, 'id') ?? '', map);
      if (gift.status != GiftStatus.accepted) continue;
      try {
        final plant = await _plantService.getPlant(gift.plantId);
        if (plant != null && !plant.isArchived) {
          await _plantService.archivePlant(
            plantId: gift.plantId,
            reason: PlantArchiveReason.gifted,
            giftedToUid: gift.recipientUid,
          );
        }
      } catch (_) {}
    }
  }

  Future<void> cancelOutgoingGift(OutgoingGift gift) async {
    if (gift.status != GiftStatus.pending) return;
    try {
      await _api.patch('/gifts/outgoing/${gift.id}', body: {
        'status': GiftStatus.cancelled.index,
      });
    } catch (_) {}
  }
}
