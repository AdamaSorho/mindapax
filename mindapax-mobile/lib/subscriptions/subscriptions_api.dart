import 'dart:convert';

import '../auth/authorized_client.dart';
import '../auth/token_storage.dart';
import '../env.dart';
import 'dart:io' show Platform;

class SubscriptionCheckoutResult {
  final bool requiresPayment;
  final int? paymentId;
  final String? checkoutUrl;
  final int subscriptionId;
  final DateTime? activeUntil;

  const SubscriptionCheckoutResult({
    required this.requiresPayment,
    required this.subscriptionId,
    this.paymentId,
    this.checkoutUrl,
    this.activeUntil,
  });

  bool get isTrialActivation => !requiresPayment;
}

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
    return list
        .map((e) => (e as Map).map((k, v) => MapEntry(k.toString(), v)))
        .toList()
        .cast<Map<String, dynamic>>();
  }

  Future<SubscriptionCheckoutResult> subscribeToPlan(int planId) async {
    final uri = Uri.parse('${_base()}/packages/$planId/subscribe');
    final res = await _client.post(uri);
    if (res.statusCode < 200 || res.statusCode >= 300) {
      String msg = 'Subscribe failed (${res.statusCode})';
      try {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        final m = (body['message']?.toString() ?? '').trim();
        if (m.isNotEmpty) msg = m;
      } catch (_) {}
      throw Exception(msg);
    }
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    final requiresPayment = json['requiresPayment'] != false;
    final subscriptionId = (json['subscriptionId'] as num?)?.toInt();
    if (subscriptionId == null) {
      throw Exception('Subscription reference missing');
    }

    DateTime? activeUntil;
    final rawActiveUntil = json['activeUntil']?.toString();
    if (rawActiveUntil != null && rawActiveUntil.isNotEmpty) {
      activeUntil = DateTime.tryParse(rawActiveUntil)?.toLocal();
    }

    if (!requiresPayment) {
      return SubscriptionCheckoutResult(
        requiresPayment: false,
        subscriptionId: subscriptionId,
        activeUntil: activeUntil,
      );
    }

    final paymentId = (json['paymentId'] as num?)?.toInt();
    final checkoutUrl = (json['checkoutUrl']?.toString() ?? '').trim();
    if (paymentId == null ||
        checkoutUrl.isEmpty ||
        Uri.tryParse(checkoutUrl)?.hasScheme != true) {
      throw Exception('Checkout link unavailable');
    }

    return SubscriptionCheckoutResult(
      requiresPayment: true,
      subscriptionId: subscriptionId,
      paymentId: paymentId,
      checkoutUrl: checkoutUrl,
      activeUntil: activeUntil,
    );
  }

  Future<List<Map<String, dynamic>>> listMySubscriptions() async {
    final uri = Uri.parse('${_base()}/packages/me');
    final res = await _client.get(uri);
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Fetch subscriptions failed (${res.statusCode})');
    }
    final list = jsonDecode(res.body) as List<dynamic>;
    return list
        .map((e) => (e as Map).map((k, v) => MapEntry(k.toString(), v)))
        .toList()
        .cast<Map<String, dynamic>>();
  }
}
