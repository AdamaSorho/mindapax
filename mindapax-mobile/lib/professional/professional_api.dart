import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io' show Platform;
import '../auth/authorized_client.dart';
import '../auth/token_storage.dart';
import '../auth/auth_service.dart';
import '../auth/jwt.dart';
import '../env.dart';
import 'models.dart';

class ProfessionalApi {
  final TokenStorage _storage;
  final AuthService _auth;
  String get _baseUrl => _normalizeBaseUrl(apiBaseUrl);

  ProfessionalApi({TokenStorage? storage, AuthService? auth})
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

  Uri _uri(String path, [Map<String, String>? query]) {
    final uri = Uri.parse('$_baseUrl$path');
    if (query == null || query.isEmpty) return uri;
    return uri.replace(queryParameters: {
      ...uri.queryParameters,
      ...query,
    });
  }

  Future<PagedResponse<Professional>> search(ProfessionalFilterParams filters) async {
    final client = AuthorizedHttpClient(_storage);
    final uri = _uri('/professionals', filters.toQueryParams());
    http.Response res = await client.get(uri);
    if (res.statusCode == 401) {
      await _auth.refresh();
      final retry = AuthorizedHttpClient(_storage);
      res = await retry.get(uri);
    }
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      return PagedResponse.fromJson(json, (j) => Professional.fromJson(j as Map<String, dynamic>));
    }
    throw Exception('Failed to fetch professionals: ${res.statusCode}');
  }

  Future<void> connectWithProfessional(int professionalId) async {
    final token = await _storage.getAccessToken();
    final payload = token != null ? decodeJwtPayload(token) : null;
    final userId = payload?['id'];
    if (userId == null) throw Exception('Missing user id');
    final client = AuthorizedHttpClient(_storage);
    final uri = _uri('/connections/$userId');
    http.Response res = await client.post(uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'professionalId': professionalId}));
    if (res.statusCode == 401) {
      await _auth.refresh();
      final retry = AuthorizedHttpClient(_storage);
      res = await retry.post(uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'professionalId': professionalId}));
    }
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Failed to connect: ${res.statusCode}');
    }
  }
}
