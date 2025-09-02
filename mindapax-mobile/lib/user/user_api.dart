import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io' show Platform;
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
}
