import 'model_helpers.dart';
import 'plant.dart';

enum GiftStatus {
  pending,
  accepted,
  declined,
  cancelled;

  String get code => name;

  static GiftStatus fromCode(dynamic code) {
    return readEnum(code, GiftStatus.values, GiftStatus.pending);
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
    final raw = readField(data, 'plantSnapshot');
    final snapshot = raw is Map
        ? Map<String, dynamic>.from(raw)
        : <String, dynamic>{};
    return IncomingGift(
      id: id,
      fromUid: readString(data, 'fromUid')?.trim() ?? '',
      fromPlantId: readString(data, 'fromPlantId')?.trim() ?? '',
      fromDisplayName: readString(data, 'fromDisplayName')?.trim(),
      message: readString(data, 'message')?.trim(),
      createdAt: readDate(data, 'createdAt'),
      status: GiftStatus.fromCode(readField(data, 'status')),
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
      recipientUid: (readString(data, 'recipientUid') ??
                  readString(data, 'toUid'))
              ?.trim() ??
          '',
      plantId: (readString(data, 'plantId') ??
                  readString(data, 'fromPlantId'))
              ?.trim() ??
          '',
      status: GiftStatus.fromCode(readField(data, 'status')),
      createdAt: readDate(data, 'createdAt'),
    );
  }
}
