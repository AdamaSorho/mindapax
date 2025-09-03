import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../auth/authorized_client.dart';
import '../auth/token_storage.dart';
import '../auth/auth_service.dart';
import '../auth/jwt.dart';
import '../env.dart';
import '../professional/models.dart' show PagedResponse; // reuse generic
import 'models.dart';

class SessionsApi {
  final TokenStorage _storage;
  final AuthService _auth;
  String get _baseUrl => _normalizeBaseUrl(apiBaseUrl);

  SessionsApi({TokenStorage? storage, AuthService? auth})
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

  Future<PagedResponse<Session>> getSessions(SessionQueryParams params) async {
    final client = AuthorizedHttpClient(_storage);

    // If caller didn't provide userId, derive from JWT for safety (frontend always sends it)
    int userId = params.userId;
    if (userId == 0) {
      final token = await _storage.getAccessToken();
      final payload = token != null ? decodeJwtPayload(token) : null;
      userId = (payload?['id'] as num?)?.toInt() ?? 0;
    }

    final query = SessionQueryParams(
      userId: userId,
      filter: params.filter,
      date: params.date,
      status: params.status,
      page: params.page,
      size: params.size,
      sort: params.sort,
    ).toQueryParams();

    final uri = _uri('/sessions/by-user', query);
    assert(() {
      debugPrint('[SessionsApi] GET $uri');
      return true;
    }());
    http.Response res = await client.get(uri);
    if (res.statusCode == 401 || res.statusCode == 403) {
      await _auth.refresh();
      final retry = AuthorizedHttpClient(_storage);
      res = await retry.get(uri);
    }
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      return PagedResponse.fromJson(json, (j) => Session.fromJson(j as Map<String, dynamic>));
    }
    throw Exception('Failed to fetch sessions: ${res.statusCode}');
  }

  Future<ZoomSignatureResponse> getZoomMeetingSignature(int sessionId) async {
    final client = AuthorizedHttpClient(_storage);
    final uri = _uri('/sessions/$sessionId/join-video');
    http.Response res = await client.post(uri, headers: {'Content-Type': 'application/json'});
    if (res.statusCode == 401) {
      await _auth.refresh();
      final retry = AuthorizedHttpClient(_storage);
      res = await retry.post(uri, headers: {'Content-Type': 'application/json'});
    }
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      return ZoomSignatureResponse.fromJson(json);
    }
    throw Exception('Failed to get meeting signature: ${res.statusCode}');
  }

  Future<Session> scheduleSessionByProfessional({
    required int userId,
    required String startTimeIso,
    required int durationMinutes,
    required SessionMode mode,
    String? notes,
  }) async {
    final client = AuthorizedHttpClient(_storage);
    final uri = _uri('/sessions/professional/schedule');
    final body = jsonEncode({
      'userId': userId,
      'startTime': startTimeIso,
      'durationMinutes': durationMinutes,
      'mode': sessionModeToString(mode),
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    });
    http.Response res = await client.post(uri, headers: {'Content-Type': 'application/json'}, body: body);
    if (res.statusCode == 401) {
      await _auth.refresh();
      final retry = AuthorizedHttpClient(_storage);
      res = await retry.post(uri, headers: {'Content-Type': 'application/json'}, body: body);
    }
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      return Session.fromJson(json);
    }
    throw Exception('Failed to schedule session: ${res.statusCode}');
  }
}
