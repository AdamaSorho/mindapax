import 'dart:convert';

import '../auth/authorized_client.dart';
import '../auth/token_storage.dart';
import '../env.dart';
import 'dart:io' show Platform;

class SubscriptionsApi {
  final AuthorizedHttpClient _client;
  SubscriptionsApi([AuthorizedHttpClient? client])
      : _client = client ?? AuthorizedHttpClient(TokenStorage());

  String _base() {
    String base = apiBaseUrl.replaceAll(RegExp(r'/+$'), '');
    if (!base.endsWith('/api/v1')) base = '$base/api/v1';
    try {
      final u = Uri.parse(base);
      if (u.host == 'localhost' && Platform.isAndroid) {
        base = base.replaceFirst('localhost', '10.0.2.2');
      }
    } catch (_) {}
    return base;
  }

  Future<List<Map<String, dynamic>>> listPlans() async {
    final uri = Uri.parse('${_base()}/packages');
    final res = await _client.get(uri);
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Fetch plans failed (${res.statusCode})');
    }
    final list = jsonDecode(res.body) as List<dynamic>;
    return list.map((e) => (e as Map).map((k, v) => MapEntry(k.toString(), v))).toList().cast<Map<String, dynamic>>();
  }

  Future<(int paymentId, String checkoutUrl)> subscribeToPlan(int planId) async {
    final uri = Uri.parse('${_base()}/packages/$planId/subscribe');
    final res = await _client.post(uri);
    if (res.statusCode < 200 || res.statusCode >= 300) {
      // Try to extract a useful message from error body
      String msg = 'Subscribe failed (${res.statusCode})';
      try {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        final m = (body['message']?.toString() ?? '').trim();
        if (m.isNotEmpty) msg = m;
      } catch (_) {}
      throw Exception(msg);
    }
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    final id = (json['paymentId'] as num).toInt();
    final url = (json['checkoutUrl']?.toString() ?? '').trim();
    if (url.isEmpty || Uri.tryParse(url)?.hasScheme != true) {
      // Surface a clear error to the UI; backend returned an invalid link
      throw Exception('Checkout link unavailable');
    }
    return (id, url);
  }

  Future<List<Map<String, dynamic>>> listMySubscriptions() async {
    final uri = Uri.parse('${_base()}/packages/me');
    final res = await _client.get(uri);
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Fetch subscriptions failed (${res.statusCode})');
    }
    final list = jsonDecode(res.body) as List<dynamic>;
    return list.map((e) => (e as Map).map((k, v) => MapEntry(k.toString(), v))).toList().cast<Map<String, dynamic>>();
  }
}
