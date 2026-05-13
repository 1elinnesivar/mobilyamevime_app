import '../../../core/api/api_client.dart';
import '../../../core/storage/token_storage.dart';

class AuthUser {
  const AuthUser({
    required this.id,
    required this.name,
    required this.username,
    required this.email,
    required this.role,
  });

  final int id;
  final String name;
  final String username;
  final String? email;
  final String role;

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: _int(json['id']),
      name: (json['name'] ?? '').toString(),
      username: (json['username'] ?? '').toString(),
      email: json['email']?.toString(),
      role: (json['role'] ?? '').toString(),
    );
  }

  static int _int(dynamic value) {
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse((value ?? '').toString()) ?? 0;
  }
}

class AuthRepository {
  AuthRepository({
    required ApiClient apiClient,
    required TokenStorage tokenStorage,
  })  : _apiClient = apiClient,
        _tokenStorage = tokenStorage;

  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  Future<AuthUser> login({
    required String username,
    required String password,
  }) async {
    final response = await _apiClient.post(
      'auth.login',
      auth: false,
      payload: {
        'username': username,
        'password': password,
      },
    );
    final token = response.data['token']?.toString();
    if (token == null || token.isEmpty) {
      throw Exception('Token alinamadi.');
    }
    await _tokenStorage.write(token);

    final userData = response.data['user'];
    if (userData is Map<String, dynamic>) {
      return AuthUser.fromJson(userData);
    }
    return me();
  }

  Future<AuthUser> me() async {
    final response = await _apiClient.post('auth.me');
    final userData = response.data['user'];
    if (userData is Map<String, dynamic>) {
      return AuthUser.fromJson(userData);
    }
    return AuthUser.fromJson(response.data);
  }

  Future<void> logout() async {
    try {
      await _apiClient.post('auth.logout');
    } finally {
      await _tokenStorage.clear();
    }
  }

  Future<bool> hasToken() async {
    final token = await _tokenStorage.read();
    return token != null && token.isNotEmpty;
  }

  Future<void> clearToken() => _tokenStorage.clear();
}
