import 'package:flutter/material.dart';
import '../auth/token_storage.dart';
import '../auth/jwt.dart';
import '../auth/auth_service.dart';
import '../user/user_api.dart';
import '../auth/authorized_client.dart';
import '../subscriptions/subscriptions_api.dart';
import '../env.dart';
import 'dart:convert';
import 'dart:io' show Platform;
import 'member_scaffold.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final _storage = TokenStorage();
  final _auth = AuthService();
  final _userApi = UserApi();
  String? _userEmail;
  Map<String, dynamic>? _user;
  bool _loading = true;
  Map<String, dynamic>? _progress;
  bool _hasActiveSubscription = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final token = await _storage.getAccessToken();
    final payload = token != null ? decodeJwtPayload(token) : null;
    final id = payload?['id'];
    _userEmail = payload?['sub']?.toString();
    try {
      if (id != null) {
        _user = await _userApi.getUserById((id as num).toInt());
      }
    } catch (_) {}
    await _loadProgress();
    await _loadSubscriptionStatus();
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _loadProgress() async {
    try {
      final client = AuthorizedHttpClient(_storage);
      final url = _buildApiUrl('/assistant/progress');
      final res = await client.get(Uri.parse(url));
      if (res.statusCode >= 200 && res.statusCode < 300) {
        setState(() {
          _progress = jsonDecode(res.body) as Map<String, dynamic>;
        });
      } else {
        // Surface minimal feedback in dev but keep UI graceful
        // ignore
      }
    } catch (_) {}
  }

  String _buildApiUrl(String pathAfterV1) {
    // Ensure base contains exactly one /api/v1 and normalize Android emulator host
    String base = apiBaseUrl.replaceAll(RegExp(r'/+$'), '');
    if (!base.endsWith('/api/v1')) {
      base = '$base/api/v1';
    }
    try {
      final u = Uri.parse(base);
      if (u.host == 'localhost' && Platform.isAndroid) {
        base = base.replaceFirst('localhost', '10.0.2.2');
      }
    } catch (_) {}
    final suffix = pathAfterV1.replaceFirst(RegExp(r'^/'), '');
    return '$base/$suffix';
  }

  Future<void> _loadSubscriptionStatus() async {
    try {
      final api = SubscriptionsApi();
      final list = await api.listMySubscriptions();
      bool active = false;
      for (final s in list) {
        final st = (s['status']?.toString() ?? '').toUpperCase();
        if (st == 'ACTIVE') { active = true; break; }
      }
      if (mounted) setState(() => _hasActiveSubscription = active);
    } catch (_) {}
  }

  Future<void> _logout() async {
    await _auth.logout();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/auth/login', (r) => false);
  }

  @override
  Widget build(BuildContext context) {
    return MemberScaffold(
      title: 'Dashboard',
      currentRoute: '/member/dashboard',
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  elevation: 0,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Welcome to Mindapax!',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        if (_userEmail != null)
                          Text('Signed in as $_userEmail'),
                        if (_user != null)
                          Text(
                              'Hello, ${_user!['firstName'] ?? ''} ${_user!['lastName'] ?? ''}'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (!_hasActiveSubscription)
                  Card(
                    elevation: 0,
                    color: Colors.amber.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Icon(Icons.subscriptions_outlined, color: Colors.amber),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'No active package. Subscribe to a plan to get session bundles and perks.',
                            ),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.of(context).pushNamed('/member/packages'),
                            child: const Text('View packages'),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                _progressCard(),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout),
                  label: const Text('Logout'),
                )
              ],
            ),
    );
  }

  Widget _progressCard() {
    final p = _progress;
    if (p == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Loading your progress…'),
        ),
      );
    }
    final active = p['activeGoals'] ?? 0;
    final completed7 = p['completedGoals7d'] ?? 0;
    final suggested = p['suggestedGoals'] ?? 0;
    final sessions7 = p['sessionsLast7d'] ?? 0;
    final lastAgo = (p['lastSessionAgo']?.toString() ?? '').isEmpty
        ? '—'
        : p['lastSessionAgo'];
    final rawNext = (p['nextSessionAt']?.toString() ?? '');
    final nextAt = rawNext.isEmpty ? '—' : _formatLocal(rawNext);

    List<Widget> topGoals = [];
    final list = (p['topActiveGoals'] as List<dynamic>? ?? const []);
    for (final g in list) {
      final m = g as Map<String, dynamic>;
      topGoals.add(Text('- [${m['frequency']}] ${m['title']}'));
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Your Progress',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _metric('Active goals', active.toString(), Icons.flag_outlined),
                _metric('Completed (7d)', completed7.toString(),
                    Icons.check_circle_outline),
                _metric(
                    'Suggested', suggested.toString(), Icons.lightbulb_outline),
                _metric('Sessions (7d)', sessions7.toString(),
                    Icons.video_call_outlined),
              ],
            ),
            const SizedBox(height: 12),
            Text('Last session: $lastAgo ago'),
            Text('Next session: $nextAt'),
            if (topGoals.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text('Top active goals:'),
              const SizedBox(height: 4),
              ...topGoals,
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                TextButton.icon(
                  onPressed: () =>
                      Navigator.of(context).pushNamed('/member/goals'),
                  icon: const Icon(Icons.flag_outlined),
                  label: const Text('View goals'),
                ),
                TextButton.icon(
                  onPressed: () =>
                      Navigator.of(context).pushNamed('/member/sessions'),
                  icon: const Icon(Icons.calendar_today_outlined),
                  label: const Text('View sessions'),
                ),
                TextButton.icon(
                  onPressed: () => Navigator.of(context).pushNamed('/member/pay'),
                  icon: const Icon(Icons.payment_outlined),
                  label: const Text('Make a payment'),
                ),
                // Payment history moved to side menu
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _metric(String label, String value, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.black54),
        const SizedBox(width: 6),
        Text('$label: ', style: const TextStyle(color: Colors.black54)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }

  String _formatLocal(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec'
      ];
      final m = months[dt.month - 1];
      final day = dt.day.toString();
      final year = dt.year.toString();
      final h12 = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      final mm = dt.minute.toString().padLeft(2, '0');
      final ampm = dt.hour >= 12 ? 'PM' : 'AM';
      return '$m $day, $year · $h12:$mm $ampm';
    } catch (_) {
      return iso;
    }
  }
}
