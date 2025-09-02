import 'dart:convert';
import 'dart:io' show Platform;
import 'package:http/http.dart' as http;
import '../env.dart';

class AuthTokens {
  final String accessToken;
  final String refreshToken;
  final int expiresIn; // seconds

  AuthTokens({required this.accessToken, required this.refreshToken, required this.expiresIn});

  factory AuthTokens.fromJson(Map<String, dynamic> json) => AuthTokens(
        accessToken: json['accessToken'] as String,
        refreshToken: json['refreshToken'] as String,
        expiresIn: (json['expiresIn'] as num).toInt(),
      );
}

class AuthApi {
  final http.Client _client;
  final String _baseUrl;

  AuthApi({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        _baseUrl = _normalizeBaseUrl(baseUrl ?? apiBaseUrl);

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

  Future<AuthTokens> login({required String email, required String password}) async {
    final res = await _client.post(
      _uri('/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return AuthTokens.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
    }
    throw Exception(_extractError(res.body));
  }

  Future<void> registerUser({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required bool agreeTerms,
  }) async {
    // Backend expects multipart with these field names
    final req = http.MultipartRequest('POST', _uri('/auth/register'))
      ..fields['firstName'] = firstName
      ..fields['lastName'] = lastName
      ..fields['email'] = email
      ..fields['password'] = password
      ..fields['role'] = 'USER'
      ..fields['agreeTerms'] = agreeTerms.toString();

    final streamed = await _client.send(req);
    final res = await http.Response.fromStream(streamed);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return; // Created user
    }
    throw Exception(_extractError(res.body));
  }

  Future<void> logout({required String refreshToken}) async {
    final res = await _client.post(
      _uri('/auth/logout'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'refreshToken': refreshToken}),
    );
    if (res.statusCode >= 200 && res.statusCode < 300) return;
    // Even if logout fails, client will clear local tokens
  }

  Future<AuthTokens> refreshTokens({required String refreshToken}) async {
    final res = await _client.post(
      _uri('/auth/refresh-token'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'refreshToken': refreshToken}),
    );
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return AuthTokens.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
    }
    throw Exception(_extractError(res.body));
  }

  String _extractError(String body) {
    try {
      final map = jsonDecode(body) as Map<String, dynamic>;
      return (map['message'] ?? map['error'] ?? 'Request failed').toString();
    } catch (_) {
      return body.isEmpty ? 'Request failed' : body;
    }
  }
}
