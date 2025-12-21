// ignore_for_file: constant_identifier_names

import 'dart:convert';

import '../auth/authorized_client.dart';
import '../auth/token_storage.dart';
import '../env.dart';
import 'dart:io' show Platform;

enum PaymentMethodMobile { CARD, MOBILE_MONEY }

class PaymentsApi {
  final AuthorizedHttpClient _client;
  PaymentsApi([AuthorizedHttpClient? client])
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

  Future<(int paymentId, String checkoutUrl)> createCheckout({
    required double amount,
    String currency = 'XOF',
    PaymentMethodMobile method = PaymentMethodMobile.MOBILE_MONEY,
    String? description,
    String? returnUrl,
  }) async {
    final uri = Uri.parse('${_base()}/payments/checkout');
    final body = jsonEncode({
      'amount': amount,
      'currency': currency,
      'paymentMethod': method.name,
      if (description != null) 'description': description,
      if (returnUrl != null) 'returnUrl': returnUrl,
    });
    final res = await _client.post(uri,
        headers: {'Content-Type': 'application/json'}, body: body);
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Checkout failed (${res.statusCode})');
    }
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    final id = (json['paymentId'] as num).toInt();
    final url = (json['checkoutUrl']?.toString() ?? '').trim();
    return (id, url);
  }

  Future<Map<String, dynamic>> getPayment(int id) async {
    final uri = Uri.parse('${_base()}/payments/$id');
    final res = await _client.get(uri);
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Fetch payment failed (${res.statusCode})');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> listUserPayments(int userId) async {
    final uri = Uri.parse('${_base()}/payments/user/$userId');
    final res = await _client.get(uri);
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Fetch payments failed (${res.statusCode})');
    }
    final list = jsonDecode(res.body) as List<dynamic>;
    return list
        .map((e) => (e as Map).map((k, v) => MapEntry(k.toString(), v)))
        .toList()
        .cast<Map<String, dynamic>>();
  }
}
