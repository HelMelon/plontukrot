import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/finance_entry.dart';

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
    String? wishListItemId,
    int? quantity,
  }) async {
    final doc = await _entriesRef.add({
      'title': title.trim(),
      'amount': amount,
      'type': type.code,
      'source': source.code,
      'date': Timestamp.fromDate(date),
      if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
      if (propagationId != null) 'propagationId': propagationId,
      if (wishListItemId != null) 'wishListItemId': wishListItemId,
      if (quantity != null) 'quantity': quantity,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  Future<void> updateEntry({
    required String id,
    required String title,
    required double amount,
    required FinanceEntryType type,
    required DateTime date,
    String? note,
  }) async {
    await _entriesRef.doc(id).update({
      'title': title.trim(),
      'amount': amount,
      'type': type.code,
      'date': Timestamp.fromDate(date),
      'note': (note == null || note.trim().isEmpty)
          ? FieldValue.delete()
          : note.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteEntry(String id) async {
    await _entriesRef.doc(id).delete();
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
