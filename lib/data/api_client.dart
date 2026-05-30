import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Central HTTP client for the ISMVCC backend.
class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  /// Backend host. Paths below include '/api', so baseUrl must NOT end with '/api'.
  /// Final URL = https://ihs.cc/WaterApi + /api/... = https://ihs.cc/WaterApi/api/...
  static const String baseUrl = 'https://ihs.cc/WaterApi';

  static const _tokenKey = 'ismvcc.token.v1';
  static const _userKey = 'ismvcc.user.v1';

  String? _token;
  Map<String, dynamic>? _user;

  Future<void> loadSession() async {
    final p = await SharedPreferences.getInstance();
    _token = p.getString(_tokenKey);
    final raw = p.getString(_userKey);
    if (raw != null && raw.isNotEmpty) {
      try { _user = jsonDecode(raw) as Map<String, dynamic>; } catch (_) { _user = null; }
    }
  }

  String? get token => _token;
  Map<String, dynamic>? get currentUser => _user;
  bool get isAuthed => _token != null && _token!.isNotEmpty;
  String get role => (_user?['role'] as String?) ?? 'Fan';
  bool get isSuperAdmin => role == 'SuperAdmin';
  bool get isAdmin => role == 'Admin';
  bool get isCaptain => role == 'Captain';
  bool get isScorer => role == 'Scorer';

  // Permission helpers — mirror backend [Authorize] rules. Single source of truth
  // for hiding create/edit/delete UI from viewers.
  bool get canManageTeams => isSuperAdmin || isAdmin;
  bool get canManageTournaments => isSuperAdmin || isScorer;
  bool get canManageMatches => isSuperAdmin || isScorer;
  bool get canManagePlayers => isSuperAdmin || isCaptain;
  bool get canScore => isSuperAdmin || isScorer;

  /// Resolve a backend image path ("/files/...") to a full URL.
  static String? imageUrl(String? path) {
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http')) return path;
    return '$baseUrl$path';
  }

  Future<void> saveSession(String token, Map<String, dynamic> user) async {
    _token = token;
    _user = user;
    final p = await SharedPreferences.getInstance();
    await p.setString(_tokenKey, token);
    await p.setString(_userKey, jsonEncode(user));
  }

  Future<void> clearSession() async {
    _token = null;
    _user = null;
    final p = await SharedPreferences.getInstance();
    await p.remove(_tokenKey);
    await p.remove(_userKey);
  }

  Map<String, String> _headers({bool json = true}) {
    final h = <String, String>{};
    if (json) h['Content-Type'] = 'application/json';
    if (_token != null) h['Authorization'] = 'Bearer $_token';
    return h;
  }

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    final qs = query?.entries
        .where((e) => e.value != null)
        .map((e) => '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value.toString())}')
        .join('&');
    final suffix = (qs == null || qs.isEmpty) ? '' : '?$qs';
    return Uri.parse('$baseUrl$path$suffix');
  }

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) async {
    final r = await http.get(_uri(path, query), headers: _headers(json: false));
    return _decode(r);
  }

  Future<dynamic> post(String path, [Object? body]) async {
    final r = await http.post(_uri(path), headers: _headers(), body: body == null ? null : jsonEncode(body));
    return _decode(r);
  }

  Future<dynamic> put(String path, [Object? body]) async {
    final r = await http.put(_uri(path), headers: _headers(), body: body == null ? null : jsonEncode(body));
    return _decode(r);
  }

  Future<dynamic> delete(String path) async {
    final r = await http.delete(_uri(path), headers: _headers(json: false));
    return _decode(r);
  }

  dynamic _decode(http.Response r) {
    final body = r.body.isEmpty ? null : jsonDecode(r.body);
    if (r.statusCode >= 200 && r.statusCode < 300) return body;
    final msg = (body is Map && body['message'] != null) ? body['message'] : r.reasonPhrase ?? 'Request failed';
    throw ApiException(r.statusCode, msg.toString(), body);
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String message;
  final dynamic body;
  ApiException(this.statusCode, this.message, [this.body]);
  @override
  String toString() => 'ApiException($statusCode): $message';
}
