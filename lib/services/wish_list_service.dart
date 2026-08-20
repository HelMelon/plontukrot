import '../models/model_helpers.dart';
import '../models/wish_list_item.dart';
import 'api_client.dart';
import 'api_exception.dart';
import 'auth_service.dart';
import 'rest_stream.dart';

class WishListService {
  final ApiClient _api = ApiClient.instance;

  String get _uid => AuthService().requireUid;

  Future<List<WishListItem>> _fetchAll() async {
    final list = jsonMapList(await _api.get('/wish-list'));
    return list
        .map((m) => WishListItem.fromMap(readString(m, 'id') ?? '', m))
        .toList()
      ..sort((a, b) {
        final aAt = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bAt = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bAt.compareTo(aAt);
      });
  }

  Stream<List<WishListItem>> watchItemsForUser(String ownerUid) {
    if (ownerUid != _uid) {
      return restPollStream(() async => <WishListItem>[]);
    }
    return restPollStream(_fetchAll);
  }

  Stream<List<WishListItem>> watchItems() => watchItemsForUser(_uid);

  Future<void> addItem({
    required String nameEn,
    required String nameAlt,
  }) async {
    await _api.post('/wish-list', body: {
      'name_en': nameEn,
      'name_alt': nameAlt,
    });
  }

  Future<void> updateItem({
    required String id,
    required String nameEn,
    required String nameAlt,
  }) async {
    try {
      await _api.patch('/wish-list/$id', body: {
        'name_en': nameEn,
        'name_alt': nameAlt,
      });
    } on ApiException catch (error) {
      if (!error.isNotFound) rethrow;
    }
  }

  Future<void> deleteItem(String id) async {
    await _api.delete('/wish-list/$id');
  }
}
