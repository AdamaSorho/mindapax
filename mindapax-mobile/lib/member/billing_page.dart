import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../auth/jwt.dart';
import '../auth/token_storage.dart';
import '../payments/payments_api.dart';
import '../subscriptions/subscriptions_api.dart';
import 'member_scaffold.dart';

class BillingPage extends StatefulWidget {
  const BillingPage({super.key});

  @override
  State<BillingPage> createState() => _BillingPageState();
}

class _BillingPageState extends State<BillingPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;
  final _storage = TokenStorage();
  final _paymentsApi = PaymentsApi();
  final _subsApi = SubscriptionsApi();

  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _payments = const [];
  List<Map<String, dynamic>> _subs = const [];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      // Load payments
      final token = await _storage.getAccessToken();
      final payload = token != null ? decodeJwtPayload(token) : null;
      final id = (payload?['id'] as num?)?.toInt();
      if (id != null) {
        final list = await _paymentsApi.listUserPayments(id);
        list.sort((a, b) {
          final ad = a['paymentDate']?.toString() ?? '';
          final bd = b['paymentDate']?.toString() ?? '';
          return bd.compareTo(ad); // newest first
        });
        _payments = list;
      }
      // Load subscriptions
      _subs = await _subsApi.listMySubscriptions();
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Map<String, dynamic>? get _currentSub {
    if (_subs.isEmpty) return null;
    final active = _subs.firstWhere(
        (s) => (s['status']?.toString() ?? '').toUpperCase() == 'ACTIVE',
        orElse: () => <String, dynamic>{});
    if (active.isNotEmpty) return active;
    return _subs.first;
  }

  @override
  Widget build(BuildContext context) {
    final deviceLocale = Localizations.localeOf(context).toString();
    return MemberScaffold(
      title: 'Billing & Subscription',
      currentRoute: '/member/billing',
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(_error!,
                          style: const TextStyle(color: Colors.red)),
                    )
                  ]),
                )
              : Column(
                  children: [
                    Material(
                      color: Theme.of(context).colorScheme.surface,
                      child: TabBar(
                        controller: _tab,
                        tabs: const [
                          Tab(text: 'Overview'),
                          Tab(text: 'Invoices'),
                          Tab(text: 'Subscription'),
                        ],
                      ),
                    ),
                    Expanded(
                      child: TabBarView(
                        controller: _tab,
                        children: [
                          _overviewTab(deviceLocale: deviceLocale),
                          _invoicesTab(deviceLocale: deviceLocale),
                          _subscriptionTab(),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _overviewTab({required String deviceLocale}) {
    final sub = _currentSub;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Current Plan',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  if (sub == null) ...[
                    const Text('No active subscription'),
                    const SizedBox(height: 8),
                    Wrap(spacing: 8, runSpacing: 8, children: [
                      FilledButton(
                        onPressed: () =>
                            Navigator.pushNamed(context, '/member/packages'),
                        child: const Text('View packages'),
                      ),
                    ])
                  ] else ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          (sub['planName']?.toString() ?? '—'),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        _statusChip(sub['status']?.toString() ?? 'PENDING'),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Period: ${_fmtDate(sub['currentPeriodStart']?.toString())} → ${_fmtDate(sub['currentPeriodEnd']?.toString())}',
                      style: const TextStyle(color: Colors.black54),
                    ),
                    if (sub['remainingSessions'] != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Remaining sessions: ${(sub['remainingSessions'] as num).toInt()}',
                        style: const TextStyle(color: Colors.black54),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Wrap(spacing: 8, runSpacing: 8, children: [
                      FilledButton(
                        onPressed: () => Navigator.pushNamed(
                            context, '/member/subscriptions'),
                        child: const Text('Manage subscription'),
                      ),
                      OutlinedButton(
                        onPressed: () =>
                            Navigator.pushNamed(context, '/member/packages'),
                        child: const Text('View packages'),
                      ),
                      OutlinedButton(
                        onPressed: () => _confirmCancel(),
                        child: const Text('Cancel subscription'),
                      ),
                    ])
                  ]
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Recent Invoices',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600)),
                      TextButton(
                        onPressed: () =>
                            Navigator.pushNamed(context, '/member/payments'),
                        child: const Text('View all'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (_payments.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text('No invoices yet.'),
                    )
                  else ...[
                    for (final p in _payments.take(3))
                      _invoiceTile(p, deviceLocale: deviceLocale),
                  ]
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _invoicesTab({required String deviceLocale}) {
    return RefreshIndicator(
      onRefresh: _load,
      child: _payments.isEmpty
          ? ListView(children: const [
              Padding(
                padding: EdgeInsets.all(16),
                child: Text('No invoices yet.'),
              )
            ])
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: _payments.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) =>
                  _invoiceTile(_payments[i], deviceLocale: deviceLocale),
            ),
    );
  }

  Widget _subscriptionTab() {
    return RefreshIndicator(
      onRefresh: _load,
      child: _subs.isEmpty
          ? ListView(children: const [
              Padding(
                padding: EdgeInsets.all(16),
                child: Text('No subscriptions yet.'),
              )
            ])
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: _subs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final s = _subs[i];
                final name = s['planName']?.toString() ?? '';
                final status = s['status']?.toString() ?? 'PENDING';
                final start = _fmtDate(s['currentPeriodStart']?.toString());
                final end = _fmtDate(s['currentPeriodEnd']?.toString());
                final remain = (s['remainingSessions'] as num?)?.toInt();
                return Card(
                  child: ListTile(
                    title: Text(name,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Period: $start → $end'),
                        if (remain != null) Text('Remaining sessions: $remain'),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _statusChip(status),
                        const SizedBox(width: 8),
                        PopupMenuButton<String>(
                          onSelected: (v) {
                            switch (v) {
                              case 'change':
                                Navigator.pushNamed(
                                    context, '/member/packages');
                                break;
                              case 'cancel':
                                _confirmCancel();
                                break;
                            }
                          },
                          itemBuilder: (context) => const [
                            PopupMenuItem(
                                value: 'change', child: Text('Change plan')),
                            PopupMenuItem(
                                value: 'cancel',
                                child: Text('Cancel subscription')),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  void _confirmCancel() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel subscription?'),
        content: const Text(
            'Cancellation is not available in the app yet. You can subscribe to another package to change plans, or contact support to cancel.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/member/packages');
            },
            child: const Text('View packages'),
          ),
        ],
      ),
    );
  }

  Widget _invoiceTile(Map<String, dynamic> p, {required String deviceLocale}) {
    final amountNum = (p['amount'] is num)
        ? (p['amount'] as num).toDouble()
        : double.tryParse(p['amount']?.toString() ?? '0') ?? 0;
    final currency = (p['currency']?.toString() ?? 'XOF');
    final amount = _formatAmount(amountNum, currency, locale: deviceLocale);
    final status = (p['status']?.toString() ?? 'PENDING');
    final provider = (p['provider']?.toString() ?? '');
    final method = (p['paymentMethod']?.toString() ?? '');
    final desc = (p['description']?.toString() ?? '');
    final when = _formatLocal(p['paymentDate']?.toString());
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      title: Text(amount, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (desc.isNotEmpty) Text(desc),
          Text(when),
          Text(
            [provider, method].where((e) => e.isNotEmpty).join(' • '),
            style: const TextStyle(color: Colors.black54),
          ),
        ],
      ),
      trailing: _statusChip(status),
    );
  }

  Chip _statusChip(String status) {
    final c = _statusColor(status);
    return Chip(
      label: Text(status),
      backgroundColor: c.withValues(alpha: 0.15),
      labelStyle: TextStyle(color: c, fontWeight: FontWeight.w600),
    );
  }

  Color _statusColor(String s) {
    switch (s.toUpperCase()) {
      case 'ACTIVE':
      case 'COMPLETED':
        return Colors.green;
      case 'PENDING':
        return Colors.orange;
      case 'FAILED':
      case 'CANCELED':
      case 'EXPIRED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _fmtDate(String? iso) {
    if (iso == null || iso.isEmpty) return '—';
    try {
      final dt = DateTime.parse(iso).toLocal();
      return DateFormat.yMMMd().add_Hm().format(dt);
    } catch (_) {
      return iso;
    }
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
    final chosenLocale = (code == 'XOF')
        ? 'fr_FR'
        : (locale != null && locale.isNotEmpty ? locale : 'en_US');
    switch (code) {
      case 'XOF':
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
