import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../models/incoming_gift.dart';
import '../models/plant.dart';
import '../models/plant_archive_reason.dart';
import '../models/plant_photo.dart';
import 'friends_service.dart';
import 'plant_service.dart';
import 'storage_service.dart';

class GiftService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final PlantService _plantService = PlantService();
  final StorageService _storageService = StorageService();
  final FriendsService _friendsService = FriendsService();

  String get uid => FirebaseAuth.instance.currentUser!.uid;

  CollectionReference<Map<String, dynamic>> _incomingRef(String userId) =>
      _firestore.collection('users').doc(userId).collection('incomingGifts');

  CollectionReference<Map<String, dynamic>> _outgoingRef(String userId) =>
      _firestore.collection('users').doc(userId).collection('outgoingGifts');

  Stream<List<IncomingGift>> watchIncomingGifts() {
    return _incomingRef(uid).snapshots().map(
      (snapshot) => snapshot.docs
          .map((doc) => IncomingGift.fromMap(doc.id, doc.data()))
          .where((g) => g.status == GiftStatus.pending)
          .toList(),
    );
  }

  Stream<List<OutgoingGift>> watchOutgoingGifts() {
    return _outgoingRef(uid).snapshots().map(
      (snapshot) => snapshot.docs
          .map((doc) => OutgoingGift.fromMap(doc.id, doc.data()))
          .toList(),
    );
  }

  /// Gift card fields only — no care history.
  Map<String, dynamic> _plantSnapshot(Plant plant) {
    return {
      'genus': plant.genus,
      'species': plant.species,
      'cultivar': plant.cultivar,
      'plantFamily': plant.plantFamily,
      'variegation': plant.variegation.storageValue,
      'tradingName': plant.tradingName,
      'nickname': plant.nickname,
      'stage': plant.stage,
      'imageUrl': plant.imageUrl,
      'imageThumbUrl': plant.imageThumbUrl,
      'images': plant.images.map((p) => p.toMap()).toList(),
      'initialLeafCount': plant.initialLeafCount,
      if (plant.members.isNotEmpty)
        'members': plant.members.map((m) => m.toMap()).toList(),
    };
  }

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

    final myName = FirebaseAuth.instance.currentUser?.displayName?.trim();
    final giftId = _outgoingRef(uid).doc().id;
    final trimmedMessage = message?.trim();

    final incoming = <String, dynamic>{
      'fromUid': uid,
      'fromPlantId': plant.id,
      'plantSnapshot': _plantSnapshot(plant),
      'createdAt': FieldValue.serverTimestamp(),
      'status': GiftStatus.pending.code,
      if (myName != null && myName.isNotEmpty) 'fromDisplayName': myName,
      if (trimmedMessage != null && trimmedMessage.isNotEmpty)
        'message': trimmedMessage,
    };

    final outgoing = <String, dynamic>{
      'recipientUid': recipient,
      'plantId': plant.id,
      'createdAt': FieldValue.serverTimestamp(),
      'status': GiftStatus.pending.code,
    };

    final batch = _firestore.batch();
    batch.set(_incomingRef(recipient).doc(giftId), incoming);
    batch.set(_outgoingRef(uid).doc(giftId), outgoing);
    await batch.commit();
  }

  Future<void> declineGift(IncomingGift gift) async {
    final batch = _firestore.batch();
    batch.set(_incomingRef(uid).doc(gift.id), {
      'status': GiftStatus.declined.code,
    }, SetOptions(merge: true));
    batch.set(_outgoingRef(gift.fromUid).doc(gift.id), {
      'status': GiftStatus.declined.code,
    }, SetOptions(merge: true));
    await batch.commit();
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
      await _copyPhotos(
        source: preview,
        newPlantId: newPlantId,
      );
    } catch (_) {
      // Plant card still created; photos may be missing.
    }

    final batch = _firestore.batch();
    batch.set(_incomingRef(uid).doc(gift.id), {
      'status': GiftStatus.accepted.code,
    }, SetOptions(merge: true));
    batch.set(_outgoingRef(gift.fromUid).doc(gift.id), {
      'status': GiftStatus.accepted.code,
    }, SetOptions(merge: true));
    await batch.commit();

    return newPlantId;
  }

  Future<void> _copyPhotos({
    required Plant source,
    required String newPlantId,
  }) async {
    final gallery = source.galleryPhotos;
    if (gallery.isEmpty) return;

    PlantPhoto? newest;
    for (final photo in gallery) {
      final bytes = await _downloadBytes(photo.imageUrl);
      if (bytes == null || bytes.isEmpty) continue;
      final uploaded = await _storageService.uploadPlantPhoto(
        imageBytes: bytes,
        plantId: newPlantId,
      );
      await _plantService.addPlantPhoto(
        plantId: newPlantId,
        photoId: uploaded.photoId,
        imageUrl: uploaded.imageUrl,
        imageThumbUrl: uploaded.imageThumbUrl,
      );
      newest ??= PlantPhoto(
        id: uploaded.photoId,
        imageUrl: uploaded.imageUrl,
        imageThumbUrl: uploaded.imageThumbUrl,
        addedAt: DateTime.now(),
      );
    }
  }

  Future<Uint8List?> _downloadBytes(String url) async {
    final trimmed = url.trim();
    if (trimmed.isEmpty) return null;
    final response = await http.get(Uri.parse(trimmed));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      return null;
    }
    return response.bodyBytes;
  }

  /// Archive plants for gifts the recipient already accepted.
  Future<void> processAcceptedOutgoingGifts() async {
    final snap = await _outgoingRef(uid).get();

    for (final doc in snap.docs) {
      final gift = OutgoingGift.fromMap(doc.id, doc.data());
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
        await doc.reference.set({
          'status': GiftStatus.cancelled.code,
          'archivedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (_) {
        // Retry on next launch.
      }
    }
  }

  Future<void> cancelOutgoingGift(OutgoingGift gift) async {
    if (gift.status != GiftStatus.pending) return;
    final batch = _firestore.batch();
    batch.set(_outgoingRef(uid).doc(gift.id), {
      'status': GiftStatus.cancelled.code,
    }, SetOptions(merge: true));
    batch.set(_incomingRef(gift.recipientUid).doc(gift.id), {
      'status': GiftStatus.cancelled.code,
    }, SetOptions(merge: true));
    await batch.commit();
  }
}
