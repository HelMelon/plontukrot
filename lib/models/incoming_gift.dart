import 'firestore_helpers.dart';
import 'plant.dart';

enum GiftStatus {
  pending,
  accepted,
  declined,
  cancelled;

  String get code => name;

  static GiftStatus fromCode(String? code) {
    return GiftStatus.values.firstWhere(
      (value) => value.name == code,
      orElse: () => GiftStatus.pending,
    );
  }
}

/// Offer waiting in the recipient's inbox.
class IncomingGift {
  final String id;
  final String fromUid;
  final String fromPlantId;
  final String? fromDisplayName;
  final String? message;
  final DateTime? createdAt;
  final GiftStatus status;
  final Map<String, dynamic> plantSnapshot;

  const IncomingGift({
    required this.id,
    required this.fromUid,
    required this.fromPlantId,
    this.fromDisplayName,
    this.message,
    this.createdAt,
    this.status = GiftStatus.pending,
    this.plantSnapshot = const {},
  });

  Plant get previewPlant => Plant.fromMap(fromPlantId, plantSnapshot);

  factory IncomingGift.fromMap(String id, Map<String, dynamic> data) {
    final raw = data['plantSnapshot'];
    final snapshot = raw is Map
        ? Map<String, dynamic>.from(raw)
        : <String, dynamic>{};
    return IncomingGift(
      id: id,
      fromUid: (data['fromUid'] as String?)?.trim() ?? '',
      fromPlantId: (data['fromPlantId'] as String?)?.trim() ?? '',
      fromDisplayName: (data['fromDisplayName'] as String?)?.trim(),
      message: (data['message'] as String?)?.trim(),
      createdAt: readTimestamp(data['createdAt']),
      status: GiftStatus.fromCode(data['status'] as String?),
      plantSnapshot: snapshot,
    );
  }
}

/// Sender-side gift tracking so the client can archive after accept.
class OutgoingGift {
  final String id;
  final String recipientUid;
  final String plantId;
  final GiftStatus status;
  final DateTime? createdAt;

  const OutgoingGift({
    required this.id,
    required this.recipientUid,
    required this.plantId,
    this.status = GiftStatus.pending,
    this.createdAt,
  });

  factory OutgoingGift.fromMap(String id, Map<String, dynamic> data) {
    return OutgoingGift(
      id: id,
      recipientUid: (data['recipientUid'] as String?)?.trim() ?? '',
      plantId: (data['plantId'] as String?)?.trim() ?? '',
      status: GiftStatus.fromCode(data['status'] as String?),
      createdAt: readTimestamp(data['createdAt']),
    );
  }
}
