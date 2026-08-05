import 'package:cloud_firestore/cloud_firestore.dart';

import 'firestore_helpers.dart';

enum FinanceEntryType {
  income,
  expense;

  String get code => name;

  static FinanceEntryType fromCode(String? code) {
    return FinanceEntryType.values.firstWhere(
      (value) => value.name == code,
      orElse: () => FinanceEntryType.expense,
    );
  }
}

enum FinanceEntrySource {
  manual,
  propagationSale,
  wishListPurchase,
  soilComponent,
  fertilizer,
  purchasedFertilizer,
  soilMix;

  String get code => name;

  static FinanceEntrySource fromCode(String? code) {
    return FinanceEntrySource.values.firstWhere(
      (value) => value.name == code,
      orElse: () => FinanceEntrySource.manual,
    );
  }
}

class FinanceEntry {
  final String id;
  final String title;
  final double amount;
  final FinanceEntryType type;
  final FinanceEntrySource source;
  final DateTime date;
  final String? note;
  final String? propagationId;
  final String? wishListItemId;
  final int? quantity;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const FinanceEntry({
    required this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.source,
    required this.date,
    this.note,
    this.propagationId,
    this.wishListItemId,
    this.quantity,
    this.createdAt,
    this.updatedAt,
  });

  bool get isIncome => type == FinanceEntryType.income;
  bool get isExpense => type == FinanceEntryType.expense;

  factory FinanceEntry.fromMap(String id, Map<String, dynamic> data) {
    return FinanceEntry(
      id: id,
      title: data['title'] as String? ?? '',
      amount: (data['amount'] as num?)?.toDouble() ?? 0,
      type: FinanceEntryType.fromCode(data['type'] as String?),
      source: FinanceEntrySource.fromCode(data['source'] as String?),
      date: readTimestamp(data['date']) ?? DateTime.now(),
      note: data['note'] as String?,
      propagationId: data['propagationId'] as String?,
      wishListItemId: data['wishListItemId'] as String?,
      quantity: (data['quantity'] as num?)?.toInt(),
      createdAt: readTimestamp(data['createdAt']),
      updatedAt: readTimestamp(data['updatedAt']),
    );
  }

  factory FinanceEntry.fromFirestore(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    return FinanceEntry.fromMap(doc.id, doc.data());
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'amount': amount,
      'type': type.code,
      'source': source.code,
      'date': Timestamp.fromDate(date),
      if (note != null && note!.isNotEmpty) 'note': note,
      if (propagationId != null) 'propagationId': propagationId,
      if (wishListItemId != null) 'wishListItemId': wishListItemId,
      if (quantity != null) 'quantity': quantity,
      if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
    };
  }
}
