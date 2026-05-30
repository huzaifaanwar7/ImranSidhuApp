import 'api_client.dart';

/// Thin wrapper around the global rankings endpoints.
/// Ratings are computed server-side per the ISMVCC formulas.
class RankingsService {
  RankingsService._();
  static final RankingsService instance = RankingsService._();
  final _api = ApiClient.instance;

  Future<List<Map<String, dynamic>>> batting({int top = 100}) =>
      _fetch('/api/rankings/batting', top);

  Future<List<Map<String, dynamic>>> bowling({int top = 100}) =>
      _fetch('/api/rankings/bowling', top);

  Future<List<Map<String, dynamic>>> teams() => _fetch('/api/rankings/teams', null);

  Future<List<Map<String, dynamic>>> _fetch(String path, int? top) async {
    final res = await _api.get(path, query: top == null ? null : {'top': top});
    final list = (res as List?) ?? const [];
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }
}
