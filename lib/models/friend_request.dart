import 'firestore_helpers.dart';

enum FriendRequestStatus {
  pending,
  accepted,
  declined;

  String get code => name;

  static FriendRequestStatus fromCode(String? code) {
    return FriendRequestStatus.values.firstWhere(
      (value) => value.name == code,
      orElse: () => FriendRequestStatus.pending,
    );
  }
}

class FriendRequest {
  final String id;
  final String fromUid;
  final String toUid;
  final FriendRequestStatus status;
  final DateTime? createdAt;
  final String? fromDisplayName;
  final String? fromPhotoUrl;

  const FriendRequest({
    required this.id,
    required this.fromUid,
    required this.toUid,
    this.status = FriendRequestStatus.pending,
    this.createdAt,
    this.fromDisplayName,
    this.fromPhotoUrl,
  });

  factory FriendRequest.fromMap(String id, Map<String, dynamic> data) {
    return FriendRequest(
      id: id,
      fromUid: (data['fromUid'] as String?)?.trim() ?? '',
      toUid: (data['toUid'] as String?)?.trim() ?? '',
      status: FriendRequestStatus.fromCode(data['status'] as String?),
      createdAt: readTimestamp(data['createdAt']),
      fromDisplayName: (data['fromDisplayName'] as String?)?.trim(),
      fromPhotoUrl: (data['fromPhotoUrl'] as String?)?.trim(),
    );
  }
}
