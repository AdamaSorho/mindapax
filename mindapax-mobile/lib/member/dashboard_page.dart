import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/material.dart';

import '../auth/auth_service.dart';
import '../auth/authorized_client.dart';
import '../auth/jwt.dart';
import '../auth/token_storage.dart';
import '../connections/connections_api.dart';
import '../connections/models.dart';
import '../env.dart';
import '../professional/professional_api.dart';
import '../sessions/models.dart';
import '../sessions/sessions_api.dart';
import '../subscriptions/subscriptions_api.dart';
import '../user/user_api.dart';
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
  final _proApi = ProfessionalApi();
  final _connectionsApi = ConnectionsApi();
  final _sessionsApi = SessionsApi();

  String? _userEmail;
  Map<String, dynamic>? _user;
  bool _loading = true;
  Map<String, dynamic>? _progress;
  bool _hasActiveSubscription = false;
  bool _isProfessional = false;

  int? _professionalId;
  int _pendingConnections = 0;
  int _activeConnections = 0;
  int _escalatedConnections = 0;
  List<Session> _upcomingSessions = const [];
  String? _professionalError;
  final Map<int, String> _clientNames = {};
  final Set<int> _clientNameRequests = <int>{};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final token = await _storage.getAccessToken();
    final payload = token != null ? decodeJwtPayload(token) : null;
    final userId = (payload?['id'] as num?)?.toInt();
    final email = payload?['sub']?.toString();
    final roles = _extractRoles(payload?['roles']);
    final isProfessional = roles.contains('ROLE_PROFESSIONAL');

    Map<String, dynamic>? user;
    if (userId != null) {
      try {
        user = await _userApi.getUserById(userId);
      } catch (_) {}
    }

    if (!mounted) return;
    setState(() {
      _userEmail = email;
      _user = user;
      _isProfessional = isProfessional;
      if (isProfessional) {
        _progress = null;
        _hasActiveSubscription = false;
        _professionalError = null;
        _professionalId = null;
        _pendingConnections = 0;
        _activeConnections = 0;
        _escalatedConnections = 0;
        _upcomingSessions = const [];
        _clientNames.clear();
        _clientNameRequests.clear();
      }
    });

    if (isProfessional) {
      await _loadProfessionalSnapshot();
    } else {
      await _loadProgress();
      await _loadSubscriptionStatus();
    }

    if (!mounted) return;
    setState(() => _loading = false);
  }

  List<String> _extractRoles(dynamic raw) {
    if (raw is List) {
      return raw
          .map((e) => e.toString())
          .where((e) => e.isNotEmpty)
          .map((r) => r.startsWith('ROLE_') ? r : 'ROLE_${r.toUpperCase()}')
          .toList(growable: false);
    }
    if (raw is String) {
      return raw
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .map((r) => r.startsWith('ROLE_') ? r : 'ROLE_${r.toUpperCase()}')
          .toList(growable: false);
    }
    return const [];
  }

  Future<void> _loadProfessionalSnapshot() async {
    try {
      final me = await _proApi.getMe();
      final professionalId = me.id;
      final connections =
          await _connectionsApi.getConnectionsForProfessional(professionalId);
      final pending =
          connections.where((c) => c.status == ConnectionStatus.PENDING).length;
      final active = connections
          .where((c) => c.status == ConnectionStatus.ACCEPTED)
          .length;
      final escalated = connections
          .where((c) => c.status == ConnectionStatus.ESCALATED)
          .length;

      final sessionsPage = await _sessionsApi.getSessions(SessionQueryParams(
        userId: professionalId,
        filter: SessionTimeFilter.UPCOMING,
        date: DateTime.now(),
        status: SessionStatus.SCHEDULED,
        page: 0,
        size: 5,
        sort: 'startTime,asc',
      ));

      if (!mounted) return;
      setState(() {
        _professionalId = professionalId;
        _pendingConnections = pending;
        _activeConnections = active;
        _escalatedConnections = escalated;
        _upcomingSessions = sessionsPage.content;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _professionalError =
            'Unable to load professional overview: ${e.toString()}';
      });
    }
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
        if (st == 'ACTIVE') {
          active = true;
          break;
        }
      }
      if (mounted) setState(() => _hasActiveSubscription = active);
    } catch (_) {}
  }

  void _prefetchClientName(int userId) {
    if (_clientNameRequests.contains(userId)) return;
    _clientNameRequests.add(userId);
    _userApi.getUserById(userId).then((value) {
      final first = (value['firstName']?.toString() ?? '').trim();
      final last = (value['lastName']?.toString() ?? '').trim();
      final name = ('$first $last').trim();
      if (!mounted) return;
      setState(() {
        _clientNames[userId] = name.isEmpty ? 'Client' : name;
      });
    }).catchError((_) {
      if (!mounted) return;
      setState(() {
        _clientNames[userId] = 'Client';
      });
    }).whenComplete(() {
      _clientNameRequests.remove(userId);
    });
  }

  String _clientNameFor(int userId) {
    final cached = _clientNames[userId];
    if (cached != null && cached.isNotEmpty) return cached;
    _prefetchClientName(userId);
    return cached == null || cached.isEmpty ? 'Client' : cached;
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
          : (_isProfessional ? _professionalBody() : _memberBody()),
    );
  }

  Widget _memberBody() {
    final children = <Widget>[
      _welcomeCard(professional: false),
      const SizedBox(height: 12),
      if (!_hasActiveSubscription) ...[
        _subscriptionReminderCard(),
        const SizedBox(height: 12),
      ],
      _progressCard(),
      const SizedBox(height: 24),
      FilledButton.icon(
        onPressed: _logout,
        icon: const Icon(Icons.logout),
        label: const Text('Logout'),
      ),
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: children,
    );
  }

  Widget _professionalBody() {
    final children = <Widget>[
      _welcomeCard(professional: true),
      const SizedBox(height: 12),
      if (_professionalError != null) ...[
        _errorBanner(_professionalError!),
        const SizedBox(height: 12),
      ],
      _professionalStatsCard(),
      const SizedBox(height: 12),
      _upcomingSessionsCard(),
      const SizedBox(height: 12),
      _professionalActionsCard(),
      const SizedBox(height: 24),
      FilledButton.icon(
        onPressed: _logout,
        icon: const Icon(Icons.logout),
        label: const Text('Logout'),
      ),
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: children,
    );
  }

  Widget _welcomeCard({required bool professional}) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final first = (_user?['firstName']?.toString() ?? '').trim();
    final last = (_user?['lastName']?.toString() ?? '').trim();
    final name = ('$first $last').trim();
    final greeting = name.isNotEmpty ? 'Hello, $name' : 'Welcome to Mindapax!';
    final subtitle = _userEmail != null ? 'Signed in as $_userEmail' : null;
    final message = professional
        ? 'Stay on top of your practice with quick access to sessions, connections, and client messages.'
        : 'Track your goals, sessions, and payments at a glance.';

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              greeting,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
            const SizedBox(height: 12),
            Text(
              message,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  Widget _subscriptionReminderCard() {
    return Card(
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
              onPressed: () =>
                  Navigator.of(context).pushNamed('/member/packages'),
              child: const Text('View packages'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _professionalStatsCard() {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final stats = <({String label, int value, IconData icon})>[
      (
        label: 'Pending requests',
        value: _pendingConnections,
        icon: Icons.inbox_outlined
      ),
      (
        label: 'Active clients',
        value: _activeConnections,
        icon: Icons.groups_outlined
      ),
      (
        label: 'Upcoming sessions',
        value: _upcomingSessions.length,
        icon: Icons.calendar_month_outlined
      ),
      (
        label: 'Escalated',
        value: _escalatedConnections,
        icon: Icons.priority_high_outlined
      ),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Practice overview',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final stat in stats)
                  Container(
                    constraints: const BoxConstraints(minWidth: 150),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(stat.icon, color: scheme.primary),
                        const SizedBox(height: 12),
                        Text(
                          stat.value.toString(),
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: scheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          stat.label,
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _upcomingSessionsCard() {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    if (_upcomingSessions.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Upcoming sessions',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text(
                'You have no upcoming sessions scheduled.',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: () =>
                    Navigator.of(context).pushNamed('/member/schedule-session'),
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('Schedule a session'),
              ),
            ],
          ),
        ),
      );
    }

    final preview = _upcomingSessions.take(3).toList(growable: false);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Upcoming sessions',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            for (var i = 0; i < preview.length; i++) ...[
              _sessionPreviewTile(preview[i]),
              if (i != preview.length - 1)
                Divider(color: scheme.outlineVariant, height: 16),
            ],
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () =>
                  Navigator.of(context).pushNamed('/member/sessions'),
              icon: const Icon(Icons.calendar_today_outlined),
              label: const Text('View all sessions'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sessionPreviewTile(Session session) {
    final name = _clientNameFor(session.userId);
    final initials =
        name.isNotEmpty ? name.characters.first.toUpperCase() : 'C';
    final subtitle =
        '${_formatSessionDateTime(session.startTime)} · ${_formatSessionMode(session.mode)}';

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(child: Text(initials)),
      title: Text(name),
      subtitle: Text(subtitle),
      onTap: () => Navigator.of(context).pushNamed('/member/sessions'),
    );
  }

  Widget _professionalActionsCard() {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Quick actions',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: () =>
                      Navigator.of(context).pushNamed('/member/sessions'),
                  icon: const Icon(Icons.calendar_month_outlined),
                  label: const Text('Manage sessions'),
                ),
                FilledButton.icon(
                  onPressed: () => Navigator.of(context)
                      .pushNamed('/member/schedule-session'),
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text('Schedule session'),
                  style: FilledButton.styleFrom(
                    backgroundColor: scheme.primaryContainer,
                    foregroundColor: scheme.onPrimaryContainer,
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () =>
                      Navigator.of(context).pushNamed('/member/connections'),
                  icon: const Icon(Icons.people_outline),
                  label: const Text('Connections'),
                ),
                OutlinedButton.icon(
                  onPressed: () =>
                      Navigator.of(context).pushNamed('/member/messages'),
                  icon: const Icon(Icons.chat_bubble_outline),
                  label: const Text('Messages'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: scheme.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _errorBanner(String message) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: scheme.onErrorContainer),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: scheme.onErrorContainer, height: 1.3),
              ),
            ),
          ],
        ),
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

    final list = (p['topActiveGoals'] as List<dynamic>? ?? const []);
    final topGoals = list
        .map((entry) => entry as Map<String, dynamic>)
        .map((m) => Text('- [${m['frequency']}] ${m['title']}'))
        .toList(growable: false);

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
                  onPressed: () =>
                      Navigator.of(context).pushNamed('/member/pay'),
                  icon: const Icon(Icons.payment_outlined),
                  label: const Text('Make a payment'),
                ),
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
      const months = [
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

  String _formatSessionDateTime(DateTime dateTime) {
    final local = dateTime.toLocal();
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
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
    final dow = weekdays[local.weekday - 1];
    final month = months[local.month - 1];
    final day = local.day.toString();
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final minute = local.minute.toString().padLeft(2, '0');
    final suffix = local.hour >= 12 ? 'PM' : 'AM';
    return '$dow, $month $day · $hour:$minute $suffix';
  }

  String _formatSessionMode(SessionMode mode) {
    switch (mode) {
      case SessionMode.VIDEO:
        return 'Video';
      case SessionMode.CHAT:
        return 'Chat';
      case SessionMode.MESSAGE:
        return 'Message';
    }
  }
}
