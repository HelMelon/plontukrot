import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/finance_entry.dart';
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
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final StorageService _storage = StorageService();

  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  CollectionReference<Map<String, dynamic>> get _entriesRef =>
      _firestore.collection('users').doc(_uid).collection('financeEntries');

  Stream<List<FinanceEntry>> watchEntries() {
    return _entriesRef
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map(FinanceEntry.fromFirestore).toList(),
        );
  }

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
    final doc = await _entriesRef.add({
      'title': title.trim(),
      'amount': amount,
      'type': type.code,
      'source': source.code,
      'date': Timestamp.fromDate(date),
      if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
      if (propagationId != null) 'propagationId': propagationId,
      if (plantId != null) 'plantId': plantId,
      if (wishListItemId != null) 'wishListItemId': wishListItemId,
      if (quantity != null) 'quantity': quantity,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    if (receiptImages.isNotEmpty) {
      final receipts = await _uploadReceipts(
        entryId: doc.id,
        images: receiptImages,
      );
      if (receipts.isNotEmpty) {
        await _entriesRef.doc(doc.id).update({
          'receipts': receipts.map((r) => r.toMap()).toList(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    }

    return doc.id;
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
    final existing = await _entriesRef.doc(id).get();
    final current = existing.data() == null
        ? const <FinanceReceipt>[]
        : FinanceEntry.fromMap(id, existing.data()!).receipts;

    if (removeReceiptIds.isNotEmpty) {
      await _storage.deleteFinanceReceipts(
        entryId: id,
        receiptIds: removeReceiptIds,
      );
    }

    var next = (receipts ?? current)
        .where((r) => !removeReceiptIds.contains(r.id))
        .toList();

    if (newReceiptImages.isNotEmpty) {
      final slots = FinanceEntry.maxReceipts - next.length;
      if (slots > 0) {
        final uploaded = await _uploadReceipts(
          entryId: id,
          images: newReceiptImages.take(slots),
        );
        next = [...next, ...uploaded];
      }
    }

    await _entriesRef.doc(id).update({
      'title': title.trim(),
      'amount': amount,
      'type': type.code,
      'date': Timestamp.fromDate(date),
      'note': (note == null || note.trim().isEmpty)
          ? FieldValue.delete()
          : note.trim(),
      if (next.isEmpty)
        'receipts': FieldValue.delete()
      else
        'receipts': next.map((r) => r.toMap()).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteEntry(String id) async {
    final snapshot = await _entriesRef.doc(id).get();
    final data = snapshot.data();
    if (data != null) {
      final entry = FinanceEntry.fromMap(id, data);
      if (entry.receipts.isNotEmpty) {
        await _storage.deleteFinanceReceipts(
          entryId: id,
          receiptIds: entry.receipts.map((r) => r.id),
        );
      }
    }
    await _entriesRef.doc(id).delete();
  }

  Future<List<FinanceReceipt>> _uploadReceipts({
    required String entryId,
    required Iterable<Uint8List> images,
  }) async {
    final receipts = <FinanceReceipt>[];
    for (final bytes in images) {
      if (bytes.isEmpty) continue;
      final uploaded = await _storage.uploadFinanceReceipt(
        imageBytes: bytes,
        entryId: entryId,
      );
      receipts.add(
        FinanceReceipt(id: uploaded.receiptId, url: uploaded.url),
      );
    }
    return receipts;
  }

  /// Aggregates income/expense for the last [months] calendar months
  /// (including the current month), oldest → newest.
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
