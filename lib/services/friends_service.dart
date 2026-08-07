import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/collection_visibility.dart';
import '../models/friend_request.dart';
import '../models/friendship.dart';

class FriendsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String get uid => FirebaseAuth.instance.currentUser!.uid;

  DocumentReference<Map<String, dynamic>> _userDoc([String? userId]) =>
      _firestore.collection('users').doc(userId ?? uid);

  CollectionReference<Map<String, dynamic>> _friendsRef([String? userId]) =>
      _userDoc(userId).collection('friends');

  CollectionReference<Map<String, dynamic>> _requestsRef([String? userId]) =>
      _userDoc(userId).collection('friendRequests');

  Stream<List<Friendship>> watchFriends() {
    return _friendsRef().snapshots().map(
      (snapshot) => snapshot.docs
          .map((doc) => Friendship.fromMap(doc.id, doc.data()))
          .toList()
        ..sort(
          (a, b) => a.displayLabel.toLowerCase().compareTo(
            b.displayLabel.toLowerCase(),
          ),
        ),
    );
  }

  Stream<List<FriendRequest>> watchIncomingRequests() {
    return _requestsRef().snapshots().map(
      (snapshot) => snapshot.docs
          .map((doc) => FriendRequest.fromMap(doc.id, doc.data()))
          .where(
            (r) =>
                r.toUid == uid && r.status == FriendRequestStatus.pending,
          )
          .toList(),
    );
  }

  Stream<List<FriendRequest>> watchOutgoingRequests() {
    return _requestsRef().snapshots().map(
      (snapshot) => snapshot.docs
          .map((doc) => FriendRequest.fromMap(doc.id, doc.data()))
          .where(
            (r) =>
                r.fromUid == uid && r.status == FriendRequestStatus.pending,
          )
          .toList(),
    );
  }

  Future<Map<String, dynamic>?> fetchPublicProfile(String userId) async {
    final trimmed = userId.trim();
    if (trimmed.isEmpty) return null;
    final snap = await _userDoc(trimmed).get();
    if (!snap.exists) return null;
    return snap.data();
  }

  Future<void> sendFriendRequest(String toUid) async {
    final target = toUid.trim();
    if (target.isEmpty) {
      throw ArgumentError('Friend uid is required');
    }
    if (target == uid) {
      throw StateError('Cannot add yourself');
    }

    final existingFriend = await _friendsRef().doc(target).get();
    if (existingFriend.exists) {
      throw StateError('Already friends');
    }

    final myProfile = await _userDoc().get();
    final myData = myProfile.data() ?? {};
    final displayName = (myData['name'] as String?)?.trim();
    final photoUrl = FirebaseAuth.instance.currentUser?.photoURL;

    final requestId = '${uid}_$target';
    final payload = <String, dynamic>{
      'fromUid': uid,
      'toUid': target,
      'status': FriendRequestStatus.pending.code,
      'createdAt': FieldValue.serverTimestamp(),
      if (displayName != null && displayName.isNotEmpty)
        'fromDisplayName': displayName,
      if (photoUrl != null && photoUrl.isNotEmpty) 'fromPhotoUrl': photoUrl,
    };

    final batch = _firestore.batch();
    batch.set(_requestsRef().doc(requestId), payload);
    batch.set(_requestsRef(target).doc(requestId), payload);
    await batch.commit();
  }

  Future<void> acceptFriendRequest(FriendRequest request) async {
    if (request.toUid != uid) {
      throw StateError('Not the request recipient');
    }

    final fromProfile = await _userDoc(request.fromUid).get();
    final fromData = fromProfile.data() ?? {};
    final myProfile = await _userDoc().get();
    final myData = myProfile.data() ?? {};

    final fromName =
        (fromData['name'] as String?)?.trim() ?? request.fromDisplayName;
    final myName = (myData['name'] as String?)?.trim();
    final fromPhoto =
        request.fromPhotoUrl ??
        (fromData['photoUrl'] as String?)?.trim();
    final myPhoto = FirebaseAuth.instance.currentUser?.photoURL;

    final batch = _firestore.batch();
    final now = FieldValue.serverTimestamp();

    batch.set(_friendsRef().doc(request.fromUid), {
      'since': now,
      if (fromName != null && fromName.isNotEmpty) 'displayNameSnap': fromName,
      if (fromPhoto != null && fromPhoto.isNotEmpty) 'photoUrlSnap': fromPhoto,
    });
    batch.set(_friendsRef(request.fromUid).doc(uid), {
      'since': now,
      if (myName != null && myName.isNotEmpty) 'displayNameSnap': myName,
      if (myPhoto != null && myPhoto.isNotEmpty) 'photoUrlSnap': myPhoto,
    });

    batch.set(_requestsRef().doc(request.id), {
      'status': FriendRequestStatus.accepted.code,
    }, SetOptions(merge: true));
    batch.set(_requestsRef(request.fromUid).doc(request.id), {
      'status': FriendRequestStatus.accepted.code,
    }, SetOptions(merge: true));

    await batch.commit();
  }

  Future<void> declineFriendRequest(FriendRequest request) async {
    if (request.toUid != uid) {
      throw StateError('Not the request recipient');
    }
    final batch = _firestore.batch();
    batch.set(_requestsRef().doc(request.id), {
      'status': FriendRequestStatus.declined.code,
    }, SetOptions(merge: true));
    batch.set(_requestsRef(request.fromUid).doc(request.id), {
      'status': FriendRequestStatus.declined.code,
    }, SetOptions(merge: true));
    await batch.commit();
  }

  Future<void> cancelOutgoingRequest(FriendRequest request) async {
    if (request.fromUid != uid) {
      throw StateError('Not the request sender');
    }
    final batch = _firestore.batch();
    batch.delete(_requestsRef().doc(request.id));
    batch.delete(_requestsRef(request.toUid).doc(request.id));
    await batch.commit();
  }

  Future<void> removeFriend(String friendUid) async {
    final target = friendUid.trim();
    final batch = _firestore.batch();
    batch.delete(_friendsRef().doc(target));
    batch.delete(_friendsRef(target).doc(uid));
    await batch.commit();
  }

  Future<bool> areFriends(String otherUid) async {
    final snap = await _friendsRef().doc(otherUid.trim()).get();
    return snap.exists;
  }

  Future<void> updateCollectionVisibility(CollectionVisibility visibility) async {
    await _userDoc().set({
      'collectionVisibility': visibility.code,
    }, SetOptions(merge: true));
  }
}
