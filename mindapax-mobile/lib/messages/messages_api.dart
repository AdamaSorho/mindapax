import 'dart:convert';
import 'dart:io' show Platform;
import 'package:http/http.dart' as http;
import '../auth/authorized_client.dart';
import '../auth/token_storage.dart';
import '../auth/auth_service.dart';
import '../env.dart';
import '../professional/models.dart' show PagedResponse; // reuse generic
import 'models.dart';

class MessagesApi {
  final TokenStorage _storage;
  final AuthService _auth;
  String get _baseUrl => _normalizeBaseUrl(apiBaseUrl);

  MessagesApi({TokenStorage? storage, AuthService? auth})
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

  Future<PagedResponse<ConversationSummary>> getConversations(int userId, {int page = 0, int size = 20}) async {
    final client = AuthorizedHttpClient(_storage);
    final uri = _uri('/conversations/$userId', {'page': '$page', 'size': '$size'});
    http.Response res = await client.get(uri);
    if (res.statusCode == 401) {
      await _auth.refresh();
      final retry = AuthorizedHttpClient(_storage);
      res = await retry.get(uri);
    }
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      return PagedResponse.fromJson(json, (j) => ConversationSummary.fromJson(j as Map<String, dynamic>, currentUserId: userId));
    }
    throw Exception('Failed to fetch conversations: ${res.statusCode}');
  }

  Future<PagedResponse<ChatMessage>> getMessages(int conversationId, {int page = 0, int size = 50, String? sort}) async {
    final client = AuthorizedHttpClient(_storage);
    final query = <String, String>{
      'conversationId': '$conversationId',
      'page': '$page',
      'size': '$size',
      if (sort != null && sort.isNotEmpty) 'sort': sort,
    };
    final uri = _uri('/messages', query);
    http.Response res = await client.get(uri);
    if (res.statusCode == 401) {
      await _auth.refresh();
      final retry = AuthorizedHttpClient(_storage);
      res = await retry.get(uri);
    }
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      return PagedResponse.fromJson(json, (j) => ChatMessage.fromJson(j as Map<String, dynamic>));
    }
    throw Exception('Failed to fetch messages: ${res.statusCode}');
  }

  Future<ChatMessage> sendMessage({required int conversationId, required int senderId, required String content}) async {
    final client = AuthorizedHttpClient(_storage);
    final uri = _uri('/messages');
    final body = jsonEncode({'conversationId': conversationId, 'senderId': senderId, 'content': content});
    http.Response res = await client.post(uri, headers: {'Content-Type': 'application/json'}, body: body);
    if (res.statusCode == 401) {
      await _auth.refresh();
      final retry = AuthorizedHttpClient(_storage);
      res = await retry.post(uri, headers: {'Content-Type': 'application/json'}, body: body);
    }
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      return ChatMessage.fromJson(json);
    }
    throw Exception('Failed to send message: ${res.statusCode}');
  }

  Future<void> markRead({required int conversationId, required int readerId}) async {
    final client = AuthorizedHttpClient(_storage);
    final uri = _uri('/messages/read', {'conversationId': '$conversationId', 'readerId': '$readerId'});
    http.Response res = await client.post(uri);
    if (res.statusCode == 401) {
      await _auth.refresh();
      final retry = AuthorizedHttpClient(_storage);
      res = await retry.post(uri);
    }
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Failed to mark read: ${res.statusCode}');
    }
  }
}
