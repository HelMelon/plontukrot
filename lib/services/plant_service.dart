import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/plant.dart';

class PlantService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final String uid = FirebaseAuth.instance.currentUser!.uid;

  Future<void> addPlant({
    required String name,
    String nickname = '',
    String family = '',
    required int stage,
  }) async {
    await _firestore.collection('users').doc(uid).collection('plants').add({
      'name': name,
      'nickname': nickname,
      'stage': stage,
      'imageUrl': null,
      'wateringFrequency': null,
      'family': family,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<Plant>> getPlants() {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('plants')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(Plant.fromFirestore).toList());
  }

  Future<void> updatePlantImage({
    required String plantId,
    required String imageUrl,
  }) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('plants')
        .doc(plantId)
        .update({'imageUrl': imageUrl});
  }

  Future<void> updatePlant({
    required String plantId,
    required String name,
    required String nickname,
    required String family,
    int? wateringFrequency,
    required int stage,
  }) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('plants')
        .doc(plantId)
        .update({
      'name': name,
      'nickname': nickname,
      'wateringFrequency': wateringFrequency,
      'stage': stage,
      'family': family,
    });
  }
}
