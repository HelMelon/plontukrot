import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/wish_list_item.dart';

class WishListService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  CollectionReference<Map<String, dynamic>> get _wishListRef =>
      _firestore.collection('users').doc(_uid).collection('wishList');

  Stream<List<WishListItem>> watchItems() {
    return _wishListRef
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map(WishListItem.fromFirestore).toList(),
        );
  }

  Future<void> addItem({
    required String nameEn,
    required String nameAlt,
  }) async {
    await _wishListRef.add({
      'nameEn': nameEn,
      'nameAlt': nameAlt,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateItem({
    required String id,
    required String nameEn,
    required String nameAlt,
  }) async {
    await _wishListRef.doc(id).update({
      'nameEn': nameEn,
      'nameAlt': nameAlt,
      'updatedAt': FieldValue.serverTimestamp(),
      'nameRu': FieldValue.delete(),
    });
  }

  Future<void> deleteItem(String id) async {
    await _wishListRef.doc(id).delete();
  }
}
