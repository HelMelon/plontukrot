import 'package:cloud_firestore/cloud_firestore.dart';

import 'firestore_helpers.dart';

class WateringEntry {
  final String? id;
  final DateTime wateredAt;
  final DateTime? nextWatering;

  const WateringEntry({
    this.id,
    required this.wateredAt,
    this.nextWatering,
  });

  factory WateringEntry.fromMap(String? id, Map<String, dynamic> data) {
    return WateringEntry(
      id: id,
      wateredAt: readTimestamp(data['wateredAt']) ?? DateTime.now(),
      nextWatering: readTimestamp(data['nextWatering']),
    );
  }

  factory WateringEntry.fromFirestore(QueryDocumentSnapshot doc) {
    return WateringEntry.fromMap(
      doc.id,
      doc.data() as Map<String, dynamic>,
    );
  }
}
