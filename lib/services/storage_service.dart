import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  final String uid = FirebaseAuth.instance.currentUser!.uid;

  Future<String> uploadPlantImageWeb({
    required Uint8List imageBytes,
    required String plantId,
  }) async {
    final ref = _storage.ref().child('plants').child(uid).child('$plantId.jpg');

    await ref.putData(imageBytes);

    return await ref.getDownloadURL();
  }
}
