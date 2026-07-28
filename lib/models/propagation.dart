import 'package:cloud_firestore/cloud_firestore.dart';

import 'firestore_helpers.dart';
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

  bool get isArchived =>
      status == PropagationStatus.sold || status == PropagationStatus.lost;

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
    final quantity = data['quantity'] as int? ?? 0;
    final quantityAlive = data['quantityAlive'] as int? ?? quantity;

    return Propagation(
      id: id,
      parentPlantId: data['parentPlantId'] as String? ?? '',
      parentPlantName: data['parentPlantName'] as String? ?? '',
      parentPlantFamily: data['parentPlantFamily'] as String? ?? '',
      method: PropagationMethod.fromCode(data['method'] as String?),
      quantity: quantity,
      quantityAlive: quantityAlive,
      soldQuantity: data['soldQuantity'] as int? ?? 0,
      lostQuantity: data['lostQuantity'] as int? ?? 0,
      stage: data['stage'] as int? ?? 1,
      status: PropagationStatus.fromCode(data['status'] as String?),
      startedAt: readTimestamp(data['startedAt']) ?? DateTime.now(),
      soldAt: readTimestamp(data['soldAt']),
      archivedAt: readTimestamp(data['archivedAt']),
      expiresAt: readTimestamp(data['expiresAt']),
      createdAt: readTimestamp(data['createdAt']),
    );
  }

  factory Propagation.fromFirestore(QueryDocumentSnapshot doc) {
    return Propagation.fromMap(doc.id, doc.data() as Map<String, dynamic>);
  }

  Map<String, dynamic> toMap() {
    return {
      'parentPlantId': parentPlantId,
      'parentPlantName': parentPlantName,
      'parentPlantFamily': parentPlantFamily,
      'method': method.code,
      'quantity': quantity,
      'quantityAlive': quantityAlive,
      'soldQuantity': soldQuantity,
      'lostQuantity': lostQuantity,
      'stage': stage,
      'status': status.code,
      'startedAt': Timestamp.fromDate(startedAt),
      if (soldAt != null) 'soldAt': Timestamp.fromDate(soldAt!),
      if (archivedAt != null) 'archivedAt': Timestamp.fromDate(archivedAt!),
      if (expiresAt != null) 'expiresAt': Timestamp.fromDate(expiresAt!),
      if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
    };
  }
}
