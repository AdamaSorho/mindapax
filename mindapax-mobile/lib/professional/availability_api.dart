import 'dart:convert';

import 'package:http/http.dart' as http;

import '../api/api_helpers.dart';
import '../auth/auth_service.dart';
import '../auth/authorized_client.dart';
import '../auth/token_storage.dart';
import '../env.dart';
import 'models.dart';

class AvailabilityApi {
  final TokenStorage _storage;
  final AuthService _auth;

  AvailabilityApi({TokenStorage? storage, AuthService? auth})
      : _storage = storage ?? TokenStorage(),
        _auth = auth ?? AuthService();

  String get _baseUrl => normalizeBaseUrl(apiBaseUrl);

  Uri _uri(String path, [Map<String, String>? query]) {
    final uri = Uri.parse('$_baseUrl$path');
    if (query == null || query.isEmpty) return uri;
    return uri.replace(queryParameters: {
      ...uri.queryParameters,
      ...query,
    });
  }

  Future<List<AvailabilitySlot>> fetchSlots(int professionalId,
      {DateTime? date}) async {
    final client = AuthorizedHttpClient(_storage);
    final params = <String, String>{};
    if (date != null) {
      params['date'] = date.toIso8601String().split('T').first;
    }
    final uri = _uri('/availabilities/$professionalId', params);
    http.Response res = await client.get(uri);
    if (res.statusCode == 401) {
      await _auth.refresh();
      final retry = AuthorizedHttpClient(_storage);
      res = await retry.get(uri);
    }
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final json = jsonDecode(res.body) as List<dynamic>;
      return json
          .map((e) => AvailabilitySlot.fromJson(e as Map<String, dynamic>))
          .toList(growable: false);
    }
    throw Exception('Failed to load availability (${res.statusCode})');
  }

  Future<AvailabilitySlot> createSlot({
    required int professionalId,
    required DateTime date,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    final body = jsonEncode({
      'date': date.toIso8601String().split('T').first,
      'startTime': _formatTime(startTime),
      'endTime': _formatTime(endTime),
    });
    final client = AuthorizedHttpClient(_storage);
    final uri = _uri('/availabilities/$professionalId');
    http.Response res =
        await client.post(uri, headers: {'Content-Type': 'application/json'}, body: body);
    if (res.statusCode == 401) {
      await _auth.refresh();
      final retry = AuthorizedHttpClient(_storage);
      res = await retry.post(uri,
          headers: {'Content-Type': 'application/json'}, body: body);
    }
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      return AvailabilitySlot.fromJson(json);
    }
    throw Exception('Failed to save availability (${res.statusCode})');
  }

  String _formatTime(DateTime time) {
    final hours = time.hour.toString().padLeft(2, '0');
    final minutes = time.minute.toString().padLeft(2, '0');
    final seconds = time.second.toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }
}
