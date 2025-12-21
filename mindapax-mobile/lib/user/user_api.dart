import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io' show File, Platform;
import '../auth/authorized_client.dart';
import '../auth/token_storage.dart';
import '../auth/auth_service.dart';
import '../env.dart';

class UserApi {
  final TokenStorage _storage;
  final AuthService _auth;
  String get _baseUrl => _normalizeBaseUrl(apiBaseUrl);

  UserApi({TokenStorage? storage, AuthService? auth})
      : _storage = storage ?? TokenStorage(),
        _auth = auth ?? AuthService();

  static String _normalizeBaseUrl(String value) {
    final cleaned = value.replaceAll(RegExp(r'/+$'), '');
    try {
      final u = Uri.parse(cleaned);
      if (u.host == 'localhost' && Platform.isAndroid) {
        return cleaned.replaceFirst('localhost', '10.0.2.2');
      }
      return cleaned;
    } catch (_) {
      return cleaned;
    }
  }

  Future<Map<String, dynamic>> getUserById(int id) async {
    final client = AuthorizedHttpClient(_storage);
    final uri = Uri.parse('$_baseUrl/users/$id');
    http.Response res = await client.get(uri);
    if (res.statusCode == 401) {
      await _auth.refresh();
      final retryClient = AuthorizedHttpClient(_storage);
      res = await retryClient.get(uri);
    }
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to fetch user: ${res.statusCode}');
  }

  Future<List<UserBasic>> getConnectedUsers(
      {int page = 0, int size = 50}) async {
    final client = AuthorizedHttpClient(_storage);
    final uri = Uri.parse(
        '$_baseUrl/professionals/me/connected-users?page=$page&size=$size');
    http.Response res = await client.get(uri);
    if (res.statusCode == 401) {
      await _auth.refresh();
      final retryClient = AuthorizedHttpClient(_storage);
      res = await retryClient.get(uri);
    }
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      final content = (json['content'] as List<dynamic>? ?? const []);
      return content
          .map<UserBasic>((e) => UserBasic.fromJson(e as Map<String, dynamic>))
          .toList(growable: false);
    }
    throw Exception('Failed to fetch connected users: ${res.statusCode}');
  }

  Future<Map<String, dynamic>> updateProfile({
    required int id,
    String? firstName,
    String? lastName,
    String? phone,
    String? location,
    File? avatarFile,
    bool removeAvatar = false,
  }) async {
    Future<http.Response> sendRequest() async {
      final uri = Uri.parse('$_baseUrl/users/$id/profile');
      final request = http.MultipartRequest('PUT', uri);
      final token = await _storage.getAccessToken();
      if (token != null && token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      if (firstName != null) request.fields['firstName'] = firstName;
      if (lastName != null) request.fields['lastName'] = lastName;
      if (phone != null) request.fields['phone'] = phone;
      if (location != null) request.fields['location'] = location;
      if (removeAvatar) request.fields['removeAvatar'] = 'true';
      if (avatarFile != null) {
        request.files
            .add(await http.MultipartFile.fromPath('avatar', avatarFile.path));
      }
      final streamed = await request.send();
      return http.Response.fromStream(streamed);
    }

    http.Response res = await sendRequest();
    if (res.statusCode == 401) {
      await _auth.refresh();
      res = await sendRequest();
    }
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to update profile: ${res.statusCode}');
  }
}

class UserBasic {
  final int id;
  final String firstName;
  final String lastName;
  UserBasic(
      {required this.id, required this.firstName, required this.lastName});
  factory UserBasic.fromJson(Map<String, dynamic> j) {
    return UserBasic(
      id: (j['id'] as num?)?.toInt() ?? 0,
      firstName: j['firstName']?.toString() ?? '',
      lastName: j['lastName']?.toString() ?? '',
    );
  }
}
