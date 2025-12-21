import 'dart:convert';
import 'dart:io' show Platform;

import '../auth/authorized_client.dart';
import '../auth/token_storage.dart';
import '../env.dart';
import 'micro_sessions_data.dart';

class MicroSessionsApi {
  static final TokenStorage _storage = TokenStorage();

  static Future<List<MicroSession>> list(
      {String? outcome, String? domain}) async {
    final client = AuthorizedHttpClient(_storage);
    final params = <String, String>{};
    if (outcome != null && outcome.trim().isNotEmpty) {
      params['outcome'] = outcome.trim();
    }
    if (domain != null && domain.trim().isNotEmpty) {
      params['domain'] = domain.trim().toUpperCase();
    }
    final res = await client.get(_uri('/micro-sessions', params));
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Failed to load micro sessions (${res.statusCode})');
    }
    final list = (jsonDecode(res.body) as List<dynamic>)
        .map((e) => MicroSession.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
    return list;
  }

  static Future<MicroSessionCompletionResult> complete(String sessionId) async {
    if (sessionId.trim().isEmpty) {
      return const MicroSessionCompletionResult();
    }
    final client = AuthorizedHttpClient(_storage);
    final res =
        await client.post(_uri('/micro-sessions/$sessionId/complete'));
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Failed to mark complete (${res.statusCode})');
    }
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    return MicroSessionCompletionResult(
      xpAwarded: (json['xpAwarded'] as num?)?.toInt(),
      goalId: json['goalId']?.toString(),
    );
  }

  static Uri _uri(String path, [Map<String, String>? query]) {
    final base = _normalizeBaseUrl(apiBaseUrl);
    final uri = Uri.parse('$base$path');
    return query == null || query.isEmpty
        ? uri
        : uri.replace(queryParameters: query);
  }

  static String _normalizeBaseUrl(String value) {
    final cleaned = value.replaceAll(RegExp(r'/+$'), '');
    try {
      final u = Uri.parse(cleaned);
      if (u.host == 'localhost' && Platform.isAndroid) {
        return cleaned.replaceFirst('localhost', '10.0.2.2');
      }
    } catch (_) {}
    return cleaned;
  }
}

class MicroSessionCompletionResult {
  final int? xpAwarded;
  final String? goalId;

  const MicroSessionCompletionResult({this.xpAwarded, this.goalId});
}
