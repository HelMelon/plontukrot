import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PlantService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final String uid = FirebaseAuth.instance.currentUser!.uid;

  Future<void> addPlant({required String name, String nickname = ''}) async {
    await _firestore.collection('users').doc(uid).collection('plants').add({
      'name': name,
      'nickname': nickname,
      'imageUrl': null,
      'wateringFrequency': null,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot> getPlants() {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('plants')
        .orderBy('createdAt', descending: true)
        .snapshots();
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
    int? wateringFrequency,
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
        });
  }
}
