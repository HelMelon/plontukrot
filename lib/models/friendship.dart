import 'firestore_helpers.dart';

class Friendship {
  final String friendUid;
  final DateTime? since;
  final String? displayNameSnap;
  final String? photoUrlSnap;

  const Friendship({
    required this.friendUid,
    this.since,
    this.displayNameSnap,
    this.photoUrlSnap,
  });

  String get displayLabel {
    final name = displayNameSnap?.trim();
    if (name != null && name.isNotEmpty) return name;
    return friendUid;
  }

  factory Friendship.fromMap(String friendUid, Map<String, dynamic> data) {
    return Friendship(
      friendUid: friendUid,
      since: readTimestamp(data['since']),
      displayNameSnap: (data['displayNameSnap'] as String?)?.trim(),
      photoUrlSnap: (data['photoUrlSnap'] as String?)?.trim(),
    );
  }
}
