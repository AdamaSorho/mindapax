import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../subscriptions/subscriptions_api.dart';
import 'member_scaffold.dart';
import 'subscription_checkout_page.dart';

class PackagesPage extends StatefulWidget {
  const PackagesPage({super.key});

  @override
  State<PackagesPage> createState() => _PackagesPageState();
}

class _PackagesPageState extends State<PackagesPage> {
  final _api = SubscriptionsApi();
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _plans = const [];

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
      final list = await _api.listPlans();
      setState(() => _plans = list);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _formatAmount(double amount, String currency, String locale) {
    final code = currency.toUpperCase();
    final chosenLocale =
        (code == 'XOF') ? 'fr_FR' : (locale.isNotEmpty ? locale : 'en_US');
    switch (code) {
      case 'XOF':
        return NumberFormat.currency(
                locale: chosenLocale,
                name: 'XOF',
                symbol: 'F\u00A0CFA',
                decimalDigits: 0)
            .format(amount);
      case 'USD':
        return NumberFormat.currency(
                locale: chosenLocale, name: 'USD', symbol: '\$')
            .format(amount);
      case 'EUR':
        return NumberFormat.currency(
                locale: chosenLocale, name: 'EUR', symbol: '\u20AC')
            .format(amount);
      default:
        return NumberFormat.currency(
                locale: chosenLocale,
                name: code,
                symbol: code,
                decimalDigits: 2)
            .format(amount);
    }
  }

  Future<void> _subscribe(Map<String, dynamic> plan) async {
    final planId = (plan['id'] as num).toInt();
    setState(() => _loading = true);
    try {
      final result = await _api.subscribeToPlan(planId);
      if (!mounted) return;
      if (!result.requiresPayment) {
        if (plan['trial'] == true) {
          final days = (plan['trialDurationDays'] as num?)?.toInt() ?? 7;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Trial activated! Enjoy Mindapax for $days day${days == 1 ? '' : 's'}.'),
            ),
          );
          setState(() {
            plan['eligibleForTrial'] = false;
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Subscription activated successfully.')));
        }
        return;
      }

      final url = result.checkoutUrl ?? '';
      final hasUrl = url.isNotEmpty && (Uri.tryParse(url)?.hasScheme == true);
      if (!hasUrl || result.paymentId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Checkout is currently unavailable. Please try again shortly.')),
        );
        return;
      }
      final done = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => SubscriptionCheckoutPage(
              paymentId: result.paymentId!, checkoutUrl: url),
          fullscreenDialog: true,
        ),
      );
      if (done == true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Subscription payment completed.')));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Subscribe failed: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final deviceLocale = Localizations.localeOf(context).toString();
    return MemberScaffold(
      title: 'Packages',
      currentRoute: '/member/packages',
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _error != null
                  ? ListView(children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(_error!,
                            style: const TextStyle(color: Colors.red)),
                      )
                    ])
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: _plans.length,
                      itemBuilder: (context, i) {
                        final p = _plans[i];
                        final name = p['name']?.toString() ?? '';
                        final desc = p['description']?.toString() ?? '';
                        final priceNum = (p['price'] is num)
                            ? (p['price'] as num).toDouble()
                            : double.tryParse(p['price']?.toString() ?? '0') ??
                                0;
                        final currency = p['currency']?.toString() ?? 'XOF';
                        final billing =
                            (p['billingCycle']?.toString() ?? 'MONTHLY')
                                .toLowerCase();
                        final sessions =
                            (p['sessionAllowance'] as num?)?.toInt() ?? 0;
                        final trial = p['trial'] == true;
                        final eligibleTrial = p['eligibleForTrial'] != false;
                        final requiresPayment = p['requiresPayment'] != false;
                        final trialDays =
                            (p['trialDurationDays'] as num?)?.toInt() ?? 7;
                        final priceText = requiresPayment
                            ? '${_formatAmount(priceNum, currency, deviceLocale)} / $billing'
                            : 'Free · $trialDays-day trial';
                        final buttonDisabled =
                            _loading || (trial && !eligibleTrial);
                        final buttonLabel = trial
                            ? (eligibleTrial
                                ? 'Start free trial'
                                : 'Trial used')
                            : 'Subscribe';
                        final features =
                            _featuresFromApi(p) ?? _featuresFor(name, sessions);
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(name,
                                        style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600)),
                                    Text(priceText,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600)),
                                  ],
                                ),
                                if (desc.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Text(desc),
                                ],
                                if (sessions > 0) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                      'Includes $sessions session(s) per $billing',
                                      style: const TextStyle(
                                          color: Colors.black54)),
                                ],
                                if (features.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  for (final f in features)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 1),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Icon(Icons.check,
                                              size: 16, color: Colors.green),
                                          const SizedBox(width: 6),
                                          Expanded(child: Text(f)),
                                        ],
                                      ),
                                    ),
                                ],
                                const SizedBox(height: 8),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      FilledButton.icon(
                                        onPressed: buttonDisabled
                                            ? null
                                            : () => _subscribe(p),
                                        icon: const Icon(
                                            Icons.subscriptions_outlined),
                                        label: Text(buttonLabel),
                                      ),
                                      if (trial && !eligibleTrial)
                                        const Padding(
                                          padding: EdgeInsets.only(top: 4),
                                          child: Text('Trial already activated',
                                              style: TextStyle(
                                                  fontSize: 10,
                                                  color: Colors.black54)),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }

  List<String> _featuresFor(String planName, int sessions) {
    final lower = planName.toLowerCase();
    final common = <String>[
      'AI Assistant with personalized context',
      'Goal recommendations and tracking',
      'Session scheduling',
      'Secure billing & subscriptions',
    ];
    if (lower.contains('premium')) {
      return [
        ...common,
        '$sessions sessions per cycle',
        'Priority booking',
        'Advanced progress insights',
      ];
    }
    if (lower.contains('standard')) {
      return [
        ...common,
        '$sessions sessions per cycle',
        'Priority booking',
      ];
    }
    return [
      ...common,
      '$sessions sessions per cycle',
    ];
  }

  List<String>? _featuresFromApi(Map<String, dynamic> p) {
    final raw = p['features'];
    if (raw is List) {
      final list = raw
          .map((e) => e?.toString().trim() ?? '')
          .where((s) => s.isNotEmpty)
          .toList();
      if (list.isNotEmpty) return list;
    }
    return null;
  }
}
