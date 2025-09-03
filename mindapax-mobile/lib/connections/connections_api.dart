import 'dart:convert';
import 'dart:io' show Platform;
import 'package:http/http.dart' as http;
import '../auth/authorized_client.dart';
import '../auth/token_storage.dart';
import '../auth/auth_service.dart';
import '../env.dart';
import 'models.dart';

class ConnectionsApi {
  final TokenStorage _storage;
  final AuthService _auth;
  String get _baseUrl => _normalizeBaseUrl(apiBaseUrl);

  ConnectionsApi({TokenStorage? storage, AuthService? auth})
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

  Uri _uri(String path) => Uri.parse('$_baseUrl$path');

  Future<List<ConnectionItem>> getConnectionsForProfessional(int professionalId) async {
    final client = AuthorizedHttpClient(_storage);
    final uri = _uri('/connections/professional/$professionalId');
    http.Response res = await client.get(uri);
    if (res.statusCode == 401) {
      await _auth.refresh();
      final retry = AuthorizedHttpClient(_storage);
      res = await retry.get(uri);
    }
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final list = jsonDecode(res.body) as List<dynamic>;
      return list.map((e) => ConnectionItem.fromJson(e as Map<String, dynamic>)).toList(growable: false);
    }
    throw Exception('Failed to fetch connections: ${res.statusCode}');
  }

  Future<List<ConnectionItem>> getConnectionsForUser(int userId) async {
    final client = AuthorizedHttpClient(_storage);
    final uri = _uri('/connections/user/$userId');
    http.Response res = await client.get(uri);
    if (res.statusCode == 401) {
      await _auth.refresh();
      final retry = AuthorizedHttpClient(_storage);
      res = await retry.get(uri);
    }
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final list = jsonDecode(res.body) as List<dynamic>;
      return list.map((e) => ConnectionItem.fromJson(e as Map<String, dynamic>)).toList(growable: false);
    }
    throw Exception('Failed to fetch connections: ${res.statusCode}');
  }

  Future<ConnectionItem> updateStatus(int connectionId, ConnectionStatus status) async {
    final client = AuthorizedHttpClient(_storage);
    final uri = _uri('/connections/$connectionId/status?status=${status.toString().split('.').last}');
    http.Response res = await client.put(uri);
    if (res.statusCode == 401) {
      await _auth.refresh();
      final retry = AuthorizedHttpClient(_storage);
      res = await retry.put(uri);
    }
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      return ConnectionItem.fromJson(json);
    }
    throw Exception('Failed to update connection: ${res.statusCode}');
  }
}

