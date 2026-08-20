import 'model_helpers.dart';
import 'propagation_method.dart';
import 'propagation_status.dart';

class Propagation {
  final String id;
  final String parentPlantId;
  final String parentPlantName;
  final String parentPlantFamily;
  final PropagationMethod method;
  final int quantity;
  final int quantityAlive;
  final int soldQuantity;
  final int giftedQuantity;
  final int tradedQuantity;
  final int lostQuantity;
  final int stage;
  final PropagationStatus status;
  final DateTime startedAt;
  final DateTime? soldAt;
  final DateTime? archivedAt;
  final DateTime? expiresAt;
  final DateTime? createdAt;

  const Propagation({
    required this.id,
    required this.parentPlantId,
    required this.parentPlantName,
    required this.parentPlantFamily,
    required this.method,
    required this.quantity,
    required this.quantityAlive,
    required this.soldQuantity,
    this.giftedQuantity = 0,
    this.tradedQuantity = 0,
    required this.lostQuantity,
    required this.stage,
    required this.status,
    required this.startedAt,
    this.soldAt,
    this.archivedAt,
    this.expiresAt,
    this.createdAt,
  });

  bool get isActive => status == PropagationStatus.active && quantityAlive > 0;

  bool get isArchived => status.isArchivedStatus;

  bool get isArchiveVisible {
    if (!isArchived) return false;
    final expires = expiresAt;
    if (expires == null) return true;
    return expires.isAfter(DateTime.now());
  }

  int get daysSinceStart {
    final now = DateTime.now();
    final start = DateTime(startedAt.year, startedAt.month, startedAt.day);
    final today = DateTime(now.year, now.month, now.day);
    return today.difference(start).inDays;
  }

  factory Propagation.fromMap(String id, Map<String, dynamic> data) {
    final quantity = readInt(data, 'quantity') ?? 0;
    final quantityAlive = readInt(data, 'quantityAlive') ?? quantity;

    return Propagation(
      id: id,
      parentPlantId: readString(data, 'parentPlantId') ?? '',
      parentPlantName: readString(data, 'parentPlantName') ?? '',
      parentPlantFamily: readString(data, 'parentPlantFamily') ?? '',
      method: PropagationMethod.fromCode(readField(data, 'method')),
      quantity: quantity,
      quantityAlive: quantityAlive,
      soldQuantity: readInt(data, 'soldQuantity') ?? 0,
      giftedQuantity: readInt(data, 'giftedQuantity') ?? 0,
      tradedQuantity: readInt(data, 'tradedQuantity') ?? 0,
      lostQuantity: readInt(data, 'lostQuantity') ?? 0,
      stage: readInt(data, 'stage') ?? 1,
      status: PropagationStatus.fromCode(readField(data, 'status')),
      startedAt: readDate(data, 'startedAt') ?? DateTime.now(),
      soldAt: readDate(data, 'soldAt'),
      archivedAt: readDate(data, 'archivedAt'),
      expiresAt: readDate(data, 'expiresAt'),
      createdAt: readDate(data, 'createdAt'),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'parentPlantId': parentPlantId,
      'parent_plant_id': parentPlantId,
      'parentPlantName': parentPlantName,
      'parent_plant_name': parentPlantName,
      'parentPlantFamily': parentPlantFamily,
      'parent_plant_family': parentPlantFamily,
      'method': method.index,
      'quantity': quantity,
      'quantityAlive': quantityAlive,
      'quantity_alive': quantityAlive,
      'soldQuantity': soldQuantity,
      'sold_quantity': soldQuantity,
      'giftedQuantity': giftedQuantity,
      'gifted_quantity': giftedQuantity,
      'tradedQuantity': tradedQuantity,
      'traded_quantity': tradedQuantity,
      'lostQuantity': lostQuantity,
      'lost_quantity': lostQuantity,
      'stage': stage,
      'status': status.index,
      'startedAt': isoOrNull(startedAt),
      'started_at': isoOrNull(startedAt),
      if (soldAt != null) 'soldAt': isoOrNull(soldAt),
      if (soldAt != null) 'sold_at': isoOrNull(soldAt),
      if (archivedAt != null) 'archivedAt': isoOrNull(archivedAt),
      if (expiresAt != null) 'expiresAt': isoOrNull(expiresAt),
      if (createdAt != null) 'createdAt': isoOrNull(createdAt),
      if (createdAt != null) 'created_at': isoOrNull(createdAt),
    };
  }
}
