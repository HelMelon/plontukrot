import '../models/balcony_day_temp.dart';
import 'api_client.dart';
import 'rest_stream.dart';

/// Balcony temperature history (last 3 days).
class BalconyService {
  final ApiClient _api = ApiClient.instance;

  /// Per-day balcony temperature summary for the last 3 days.
  Future<List<BalconyDayTemp>> getHistory() async {
    final list = jsonMapList(await _api.get('/balcony/history'));
    return [for (final m in list) BalconyDayTemp.fromMap(m)];
  }

  /// Live stream of the history (re-polls every 30s).
  Stream<List<BalconyDayTemp>> watchHistory() {
    return restPollStream(getHistory);
  }
}
