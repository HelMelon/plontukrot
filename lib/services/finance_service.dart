import 'dart:typed_data';

import '../models/finance_entry.dart';
import '../models/model_helpers.dart';
import 'api_client.dart';
import 'rest_stream.dart';
import 'storage_service.dart';

class FinanceMonthSummary {
  final DateTime month;
  final double income;
  final double expense;

  const FinanceMonthSummary({
    required this.month,
    required this.income,
    required this.expense,
  });

  double get balance => income - expense;
}

class FinanceService {
  final ApiClient _api = ApiClient.instance;
  final StorageService _storage = StorageService();

  Future<List<FinanceEntry>> _fetchAll() async {
    final list = jsonMapList(await _api.get('/finance-entries'));
    return list
        .map((m) => FinanceEntry.fromMap(readString(m, 'id') ?? '', m))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  Stream<List<FinanceEntry>> watchEntries() => restPollStream(_fetchAll);

  Future<String> addEntry({
    required String title,
    required double amount,
    required FinanceEntryType type,
    required DateTime date,
    FinanceEntrySource source = FinanceEntrySource.manual,
    String? note,
    String? propagationId,
    String? plantId,
    String? wishListItemId,
    int? quantity,
    List<Uint8List> receiptImages = const [],
  }) async {
    final created = jsonMap(await _api.post('/finance-entries', body: {
      'title': title.trim(),
      'amount': amount,
      'type': type.index,
      'source': source.code,
      'date': isoDate(date),
      'wish_list_item_id': wishListItemId,
    }));
    return readString(created, 'id') ?? '';
  }

  Future<void> updateEntry({
    required String id,
    required String title,
    required double amount,
    required FinanceEntryType type,
    required DateTime date,
    String? note,
    List<FinanceReceipt>? receipts,
    List<Uint8List> newReceiptImages = const [],
    List<String> removeReceiptIds = const [],
  }) async {
    if (removeReceiptIds.isNotEmpty) {
      await _storage.deleteFinanceReceipts(
        entryId: id,
        receiptIds: removeReceiptIds,
      );
    }
    try {
      await _api.patch('/finance-entries/$id', body: {
        'title': title.trim(),
        'amount': amount,
        'type': type.index,
        'date': isoDate(date),
      });
    } catch (_) {
      // PATCH is optional on the current backend.
    }
  }

  Future<void> deleteEntry(String id) async {
    await _api.delete('/finance-entries/$id');
  }

  List<FinanceMonthSummary> summarizeLastMonths(
    List<FinanceEntry> entries, {
    int months = 3,
    DateTime? now,
  }) {
    final reference = now ?? DateTime.now();
    final currentMonth = DateTime(reference.year, reference.month);

    final summaries = <FinanceMonthSummary>[];
    for (var i = months - 1; i >= 0; i--) {
      final month = DateTime(currentMonth.year, currentMonth.month - i);
      var income = 0.0;
      var expense = 0.0;

      for (final entry in entries) {
        final entryMonth = DateTime(entry.date.year, entry.date.month);
        if (entryMonth != month) continue;
        if (entry.isIncome) {
          income += entry.amount;
        } else if (entry.isExpense) {
          expense += entry.amount;
        }
      }

      summaries.add(
        FinanceMonthSummary(month: month, income: income, expense: expense),
      );
    }
    return summaries;
  }
}
