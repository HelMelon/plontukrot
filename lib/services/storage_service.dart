import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  final String uid = FirebaseAuth.instance.currentUser!.uid;

  Reference _plantImageRef(String plantId) {
    return _storage.ref().child('plants').child(uid).child('$plantId.jpg');
  }

  Future<String> uploadPlantImageWeb({
    required Uint8List imageBytes,
    required String plantId,
  }) async {
    final ref = _plantImageRef(plantId);

    await ref.putData(
      imageBytes,
      SettableMetadata(contentType: 'image/jpeg'),
    );

    return await ref.getDownloadURL();
  }

  Future<void> deletePlantImage(String plantId) async {
    try {
      await _plantImageRef(plantId).delete();
    } on FirebaseException catch (e) {
      if (e.code != 'object-not-found') rethrow;
    }
  }
}
