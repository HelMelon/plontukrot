import '../models/collection_visibility.dart';
import '../models/friend_request.dart';
import '../models/friendship.dart';
import '../models/model_helpers.dart';
import 'api_client.dart';
import 'api_exception.dart';
import 'auth_service.dart';
import 'user_profile_service.dart';
import 'rest_stream.dart';

class FriendsService {
  final ApiClient _api = ApiClient.instance;

  String get uid => AuthService().requireUid;

  Future<List<Friendship>> _fetchFriends() async {
    final list = jsonMapList(await _api.get('/friends'));
    final me = uid;
    final friends = <Friendship>[];
    for (final map in list) {
      final userA =
          readString(map, 'user_a') ?? readString(map, 'userA') ?? '';
      final userB =
          readString(map, 'user_b') ?? readString(map, 'userB') ?? '';
      final friendUid = userA == me ? userB : userA;
      if (friendUid.isEmpty) continue;
      friends.add(Friendship.fromMap(friendUid, map));
    }
    friends.sort(
      (a, b) => a.displayLabel.toLowerCase().compareTo(
            b.displayLabel.toLowerCase(),
          ),
    );
    return friends;
  }

  Future<List<FriendRequest>> _fetchRequests() async {
    final list = jsonMapList(await _api.get('/friend-requests'));
    return list
        .map((m) => FriendRequest.fromMap(readString(m, 'id') ?? '', m))
        .toList();
  }

  Stream<List<Friendship>> watchFriends() => restPollStream(_fetchFriends);

  Stream<List<FriendRequest>> watchIncomingRequests() {
    return restPollStream(() async {
      return (await _fetchRequests())
          .where(
            (r) => r.toUid == uid && r.status == FriendRequestStatus.pending,
          )
          .toList();
    });
  }

  Stream<List<FriendRequest>> watchOutgoingRequests() {
    return restPollStream(() async {
      return (await _fetchRequests())
          .where(
            (r) => r.fromUid == uid && r.status == FriendRequestStatus.pending,
          )
          .toList();
    });
  }

  Future<Map<String, dynamic>?> fetchPublicProfile(String userId) async {
    final trimmed = userId.trim();
    if (trimmed.isEmpty) return null;
    if (trimmed == uid) {
      return UserProfileService().fetchMe();
    }
    return null;
  }

  Future<void> sendFriendRequest(String toUid) async {
    final target = toUid.trim();
    if (target.isEmpty) {
      throw ArgumentError('Friend uid is required');
    }
    if (target == uid) {
      throw StateError('Cannot add yourself');
    }
    final me = AuthService().currentUser;
    await _api.post('/friend-requests', body: {
      'to_uid': target,
      'from_display_name': me?.name,
      'from_photo_url': me?.photoUrl,
      'status': FriendRequestStatus.pending.index,
    });
  }

  Future<void> acceptFriendRequest(FriendRequest request) async {
    if (request.toUid != uid) {
      throw StateError('Not the request recipient');
    }
    await _api.patch(
      '/friend-requests/${request.id}/status',
      query: {'status_code': '${FriendRequestStatus.accepted.index}'},
    );
  }

  Future<void> declineFriendRequest(FriendRequest request) async {
    if (request.toUid != uid) {
      throw StateError('Not the request recipient');
    }
    await _api.patch(
      '/friend-requests/${request.id}/status',
      query: {'status_code': '${FriendRequestStatus.declined.index}'},
    );
  }

  Future<void> cancelOutgoingRequest(FriendRequest request) async {
    if (request.fromUid != uid) {
      throw StateError('Not the request sender');
    }
    try {
      await _api.delete('/friend-requests/${request.id}');
    } on ApiException catch (error) {
      if (!error.isNotFound) rethrow;
    }
  }

  Future<void> removeFriend(String friendUid) async {
    try {
      await _api.delete('/friends/${friendUid.trim()}');
    } on ApiException catch (error) {
      if (!error.isNotFound) rethrow;
    }
  }

  Future<bool> areFriends(String otherUid) async {
    final friends = await _fetchFriends();
    return friends.any((f) => f.friendUid == otherUid.trim());
  }

  Future<void> updateCollectionVisibility(
    CollectionVisibility visibility,
  ) async {
    await UserProfileService().patchProfile({
      'collection_visibility': visibility.code,
    });
  }
}
