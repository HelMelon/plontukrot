import 'model_helpers.dart';

enum FriendRequestStatus {
  pending,
  accepted,
  declined;

  String get code => name;

  static FriendRequestStatus fromCode(dynamic code) {
    return readEnum(
      code,
      FriendRequestStatus.values,
      FriendRequestStatus.pending,
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
      fromUid: readString(data, 'fromUid')?.trim() ?? '',
      toUid: readString(data, 'toUid')?.trim() ?? '',
      status: FriendRequestStatus.fromCode(readField(data, 'status')),
      createdAt: readDate(data, 'createdAt'),
      fromDisplayName: readString(data, 'fromDisplayName')?.trim(),
      fromPhotoUrl: readString(data, 'fromPhotoUrl')?.trim(),
    );
  }
}
