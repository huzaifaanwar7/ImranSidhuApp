import 'api_client.dart';

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();
  final _api = ApiClient.instance;

  Future<Map<String, dynamic>> login(String username, String password) async {
    final res = await _api.post('/api/auth/login', {
      'username': username,
      'password': password,
    });
    final token = res['token'] as String;
    final user = Map<String, dynamic>.from(res['user'] as Map);
    await _api.saveSession(token, user);
    return user;
  }

  Future<Map<String, dynamic>> register({
    required String username,
    required String password,
    required String fullName,
    String? email,
    String? phone,
    String role = 'Fan',
  }) async {
    final res = await _api.post('/api/auth/register', {
      'username': username,
      'password': password,
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'role': role,
    });
    // Captains return without a token (Pending). Others return token+user.
    if (res['token'] != null) {
      final token = res['token'] as String;
      final user = Map<String, dynamic>.from(res['user'] as Map);
      await _api.saveSession(token, user);
      return user;
    }
    return Map<String, dynamic>.from(res as Map);
  }

  Future<void> logout() => _api.clearSession();
}
