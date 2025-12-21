import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../subscriptions/subscriptions_api.dart';
import 'member_scaffold.dart';

class MySubscriptionsPage extends StatefulWidget {
  const MySubscriptionsPage({super.key});

  @override
  State<MySubscriptionsPage> createState() => _MySubscriptionsPageState();
}

class _MySubscriptionsPageState extends State<MySubscriptionsPage> {
  final _api = SubscriptionsApi();
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _subs = const [];

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
      final list = await _api.listMySubscriptions();
      setState(() => _subs = list);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
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

  Color _statusColor(String s) {
    switch (s.toUpperCase()) {
      case 'ACTIVE':
        return Colors.green;
      case 'PENDING':
        return Colors.orange;
      case 'CANCELED':
      case 'EXPIRED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MemberScaffold(
      title: 'My Subscriptions',
      currentRoute: '/member/subscriptions',
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
                  : _subs.isEmpty
                      ? ListView(children: const [
                          Padding(
                            padding: EdgeInsets.all(16),
                            child: Text('No subscriptions yet.'),
                          )
                        ])
                      : ListView.separated(
                          padding: const EdgeInsets.all(12),
                          itemCount: _subs.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, i) {
                            final s = _subs[i];
                            final name = s['planName']?.toString() ?? '';
                            final status = s['status']?.toString() ?? 'PENDING';
                            final start =
                                _fmtDate(s['currentPeriodStart']?.toString());
                            final end =
                                _fmtDate(s['currentPeriodEnd']?.toString());
                            final remain =
                                (s['remainingSessions'] as num?)?.toInt();
                            return Card(
                              child: ListTile(
                                title: Text(name,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600)),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Period: $start → $end'),
                                    if (remain != null)
                                      Text('Remaining sessions: $remain'),
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
}
