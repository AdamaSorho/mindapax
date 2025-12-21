import 'dart:async';
import 'package:intl/intl.dart';

import 'package:flutter/material.dart';
import '../auth/token_storage.dart';
import '../auth/jwt.dart';
import '../payments/payments_api.dart';
import 'member_scaffold.dart';

class PaymentHistoryPage extends StatefulWidget {
  const PaymentHistoryPage({super.key});

  @override
  State<PaymentHistoryPage> createState() => _PaymentHistoryPageState();
}

class _PaymentHistoryPageState extends State<PaymentHistoryPage> {
  final _storage = TokenStorage();
  final _api = PaymentsApi();
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _payments = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final token = await _storage.getAccessToken();
      final payload = token != null ? decodeJwtPayload(token) : null;
      final id = (payload?['id'] as num?)?.toInt();
      if (id == null) throw Exception('Missing user id');
      final list = await _api.listUserPayments(id);
      list.sort((a, b) {
        final ad = a['paymentDate']?.toString() ?? '';
        final bd = b['paymentDate']?.toString() ?? '';
        return bd.compareTo(ad); // newest first
      });
      setState(() => _payments = list);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Color _statusColor(String s) {
    switch (s.toUpperCase()) {
      case 'COMPLETED':
        return Colors.green;
      case 'PENDING':
        return Colors.orange;
      case 'FAILED':
      default:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Capture device locale once per build for formatting
    final deviceLocale = Localizations.localeOf(context).toString();
    return MemberScaffold(
      title: 'Payment History',
      currentRoute: '/member/payments',
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _error != null
                  ? ListView(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(_error!,
                              style: const TextStyle(color: Colors.red)),
                        )
                      ],
                    )
                  : _payments.isEmpty
                      ? ListView(
                          children: const [
                            Padding(
                              padding: EdgeInsets.all(16),
                              child: Text('No payments yet.'),
                            )
                          ],
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(8),
                          itemCount: _payments.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 6),
                          itemBuilder: (context, i) {
                            final p = _payments[i];
                            final amountNum = (p['amount'] is num)
                                ? (p['amount'] as num).toDouble()
                                : double.tryParse(
                                        p['amount']?.toString() ?? '0') ??
                                    0;
                            final currency =
                                (p['currency']?.toString() ?? 'XOF');
                            final amount = _formatAmount(amountNum, currency,
                                locale: deviceLocale);
                            final status =
                                (p['status']?.toString() ?? 'PENDING');
                            final provider = (p['provider']?.toString() ?? '');
                            final method =
                                (p['paymentMethod']?.toString() ?? '');
                            final desc = (p['description']?.toString() ?? '');
                            final when =
                                _formatLocal(p['paymentDate']?.toString());
                            return Card(
                              child: ListTile(
                                title: Text(amount,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600)),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (desc.isNotEmpty) Text(desc),
                                    Text(when),
                                    Text(
                                      [provider, method]
                                          .where((e) => e.isNotEmpty)
                                          .join(' • '),
                                      style: const TextStyle(
                                          color: Colors.black54),
                                    ),
                                  ],
                                ),
                                trailing: Chip(
                                  label: Text(status),
                                  backgroundColor: _statusColor(status)
                                      .withValues(alpha: 0.15),
                                  labelStyle: TextStyle(
                                      color: _statusColor(status),
                                      fontWeight: FontWeight.w600),
                                ),
                              ),
                            );
                          },
                        ),
            ),
    );
  }

  String _formatLocal(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    try {
      final dt = DateTime.parse(iso).toLocal();
      final y = dt.year.toString();
      final m = dt.month.toString().padLeft(2, '0');
      final d = dt.day.toString().padLeft(2, '0');
      final hh = dt.hour.toString().padLeft(2, '0');
      final mm = dt.minute.toString().padLeft(2, '0');
      return '$y-$m-$d $hh:$mm';
    } catch (_) {
      return iso;
    }
  }

  String _formatAmount(double amount, String currency, {String? locale}) {
    final code = currency.toUpperCase();
    // Choose locale preference: XOF uses fr_FR by default; otherwise prefer device locale if provided
    final chosenLocale = (code == 'XOF')
        ? 'fr_FR'
        : (locale != null && locale.isNotEmpty ? locale : 'en_US');
    switch (code) {
      case 'XOF':
        // West African CFA franc: 0 decimals, symbol as F CFA (NBSP)
        return NumberFormat.currency(
          locale: chosenLocale,
          name: 'XOF',
          symbol: 'F\u00A0CFA',
          decimalDigits: 0,
        ).format(amount);
      case 'USD':
        return NumberFormat.currency(
          locale: chosenLocale,
          name: 'USD',
          symbol: '\$',
        ).format(amount);
      case 'EUR':
        return NumberFormat.currency(
          locale: chosenLocale,
          name: 'EUR',
          symbol: '\u20AC',
        ).format(amount);
      case 'GBP':
        return NumberFormat.currency(
          locale: chosenLocale,
          name: 'GBP',
          symbol: '\u00A3',
        ).format(amount);
      default:
        return NumberFormat.currency(
          locale: chosenLocale,
          name: code,
          symbol: code,
          decimalDigits: 2,
        ).format(amount);
    }
  }
}
