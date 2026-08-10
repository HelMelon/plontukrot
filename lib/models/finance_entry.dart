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
  plantSale,
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

/// Receipt image metadata stored on a finance entry (URL only; no list thumbs).
class FinanceReceipt {
  final String id;
  final String url;

  const FinanceReceipt({
    required this.id,
    required this.url,
  });

  factory FinanceReceipt.fromMap(Map<String, dynamic> data) {
    return FinanceReceipt(
      id: (data['id'] as String?)?.trim() ?? '',
      url: (data['url'] as String?)?.trim() ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'url': url,
      };

  bool get isValid => id.isNotEmpty && url.isNotEmpty;
}

class FinanceEntry {
  static const int maxReceipts = 5;

  final String id;
  final String title;
  final double amount;
  final FinanceEntryType type;
  final FinanceEntrySource source;
  final DateTime date;
  final String? note;
  final String? propagationId;
  final String? plantId;
  final String? wishListItemId;
  final int? quantity;
  final List<FinanceReceipt> receipts;
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
    this.plantId,
    this.wishListItemId,
    this.quantity,
    this.receipts = const [],
    this.createdAt,
    this.updatedAt,
  });

  bool get isIncome => type == FinanceEntryType.income;
  bool get isExpense => type == FinanceEntryType.expense;
  bool get hasReceipts => receipts.isNotEmpty;

  factory FinanceEntry.fromMap(String id, Map<String, dynamic> data) {
    final rawReceipts = data['receipts'];
    final receipts = <FinanceReceipt>[];
    if (rawReceipts is List) {
      for (final item in rawReceipts) {
        if (item is Map<String, dynamic>) {
          final receipt = FinanceReceipt.fromMap(item);
          if (receipt.isValid) receipts.add(receipt);
        } else if (item is Map) {
          final receipt = FinanceReceipt.fromMap(
            Map<String, dynamic>.from(item),
          );
          if (receipt.isValid) receipts.add(receipt);
        }
      }
    }

    return FinanceEntry(
      id: id,
      title: data['title'] as String? ?? '',
      amount: (data['amount'] as num?)?.toDouble() ?? 0,
      type: FinanceEntryType.fromCode(data['type'] as String?),
      source: FinanceEntrySource.fromCode(data['source'] as String?),
      date: readTimestamp(data['date']) ?? DateTime.now(),
      note: data['note'] as String?,
      propagationId: data['propagationId'] as String?,
      plantId: data['plantId'] as String?,
      wishListItemId: data['wishListItemId'] as String?,
      quantity: (data['quantity'] as num?)?.toInt(),
      receipts: receipts,
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
      if (plantId != null) 'plantId': plantId,
      if (wishListItemId != null) 'wishListItemId': wishListItemId,
      if (quantity != null) 'quantity': quantity,
      if (receipts.isNotEmpty)
        'receipts': receipts.map((r) => r.toMap()).toList(),
      if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
    };
  }
}
