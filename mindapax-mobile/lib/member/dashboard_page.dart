import 'dart:convert';
import 'dart:io' show Platform;
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../auth/auth_service.dart';
import '../auth/authorized_client.dart';
import '../auth/jwt.dart';
import '../auth/token_storage.dart';
import '../connections/connections_api.dart';
import '../connections/models.dart';
import '../env.dart';
import '../professional/professional_api.dart';
import '../professional/models.dart'
    show specializationFromString, specializationLabels;
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
  int? _currentUserId;
  bool _loading = true;
  Map<String, dynamic>? _progress;
  bool _hasActiveSubscription = false;
  Map<String, dynamic>? _activeSubscription;
  bool _subscriptionOnTrial = false;
  int? _subscriptionDaysLeft;
  DateTime? _subscriptionRenewal;
  int? _subscriptionSessionsRemaining;
  bool _subscriptionExpired = false;
  bool _isProfessional = false;

  int _pendingConnections = 0;
  int _activeConnections = 0;
  int _escalatedConnections = 0;
  List<ConnectionItem> _clientPendingConnections =
      const <ConnectionItem>[];
  List<ConnectionItem> _clientAcceptedConnections =
      const <ConnectionItem>[];
  String? _clientConnectionsError;
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
      _currentUserId = userId;
      _isProfessional = isProfessional;
      if (!isProfessional) {
        _professionalError = null;
        _pendingConnections = 0;
        _activeConnections = 0;
        _escalatedConnections = 0;
        _clientConnectionsError = null;
        _clientPendingConnections = const <ConnectionItem>[];
        _clientAcceptedConnections = const <ConnectionItem>[];
        _upcomingSessions = const [];
      }
      if (isProfessional) {
        _progress = null;
        _hasActiveSubscription = false;
        _activeSubscription = null;
        _subscriptionOnTrial = false;
        _subscriptionDaysLeft = null;
        _subscriptionRenewal = null;
        _subscriptionSessionsRemaining = null;
        _subscriptionExpired = false;
        _professionalError = null;
        _pendingConnections = 0;
        _activeConnections = 0;
        _escalatedConnections = 0;
        _upcomingSessions = const [];
        _clientNames.clear();
        _clientNameRequests.clear();
        _clientConnectionsError = null;
        _clientPendingConnections = const <ConnectionItem>[];
        _clientAcceptedConnections = const <ConnectionItem>[];
      } else {
        _professionalError = null;
      }
    });

    if (isProfessional) {
      await _loadProfessionalSnapshot();
    } else {
      await _loadProgress();
      await _loadSubscriptionStatus();
      if (userId != null) {
        await _loadClientConnections(userId);
      }
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
      Map<String, dynamic>? activeSub;
      DateTime? bestEnd;
      bool expired = false;
      for (final entry in list) {
        final map = Map<String, dynamic>.from(entry);
        final status = (map['status']?.toString() ?? '').toUpperCase();
        if (status == 'ACTIVE') {
          final endRaw = map['currentPeriodEnd']?.toString();
          final end = (endRaw == null || endRaw.isEmpty)
              ? null
              : DateTime.tryParse(endRaw);
          final currentBest = bestEnd;
          if (activeSub == null ||
              (end != null &&
                  (currentBest == null || end.isAfter(currentBest)))) {
            activeSub = map;
            bestEnd = end;
          }
        } else if (status == 'EXPIRED') {
          expired = true;
        }
      }
      if (!mounted) return;
      setState(() {
        _hasActiveSubscription = activeSub != null;
        _activeSubscription = activeSub;
        _subscriptionExpired = expired;
        if (activeSub != null) {
          final planName = (activeSub['planName']?.toString() ?? '').trim();
          _subscriptionOnTrial = planName.toLowerCase().contains('trial');
          final endRaw = activeSub['currentPeriodEnd']?.toString();
          final end = (endRaw == null || endRaw.isEmpty)
              ? null
              : DateTime.tryParse(endRaw)?.toLocal();
          _subscriptionRenewal = end;
          if (end != null) {
            final diff = end.difference(DateTime.now());
            if (diff.inDays < 0) {
              _subscriptionExpired = true;
              _hasActiveSubscription = false;
              _subscriptionDaysLeft = null;
            } else {
              _subscriptionDaysLeft = diff.inDays;
            }
          } else {
            _subscriptionDaysLeft = null;
          }
          final remaining = activeSub['remainingSessions'];
          if (remaining is num) {
            _subscriptionSessionsRemaining = remaining.toInt();
          } else if (remaining != null) {
            _subscriptionSessionsRemaining = int.tryParse(remaining.toString());
          } else {
            _subscriptionSessionsRemaining = null;
          }
        } else {
          _subscriptionOnTrial = false;
          _subscriptionDaysLeft = null;
          _subscriptionRenewal = null;
          _subscriptionSessionsRemaining = null;
          _subscriptionExpired = expired;
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _hasActiveSubscription = false;
        _activeSubscription = null;
        _subscriptionOnTrial = false;
        _subscriptionDaysLeft = null;
        _subscriptionRenewal = null;
        _subscriptionSessionsRemaining = null;
        _subscriptionExpired = false;
      });
    }
  }

  Future<void> _loadClientConnections(int userId) async {
    try {
      final connections = await _connectionsApi.getConnectionsForUser(userId);
      if (!mounted) return;
      setState(() {
        _clientConnectionsError = null;
        _clientPendingConnections = connections
            .where((c) => c.status == ConnectionStatus.PENDING)
            .toList(growable: false);
        _clientAcceptedConnections = connections
            .where((c) => c.status == ConnectionStatus.ACCEPTED)
            .toList(growable: false);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _clientConnectionsError =
            'Unable to load your connections: ${e.toString()}';
        _clientPendingConnections = const <ConnectionItem>[];
        _clientAcceptedConnections = const <ConnectionItem>[];
      });
    }
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
      _subscriptionCard(),
      const SizedBox(height: 12),
      _progressCard(),
      const SizedBox(height: 12),
      if (_clientConnectionsError != null) ...[
        _errorBanner(_clientConnectionsError!),
        const SizedBox(height: 12),
      ],
      _clientConnectionsCard(
        title: 'Pending connections',
        icon: Icons.hourglass_bottom_outlined,
        items: _clientPendingConnections,
        emptyTitle: 'No pending requests',
        emptyDescription:
            'When you request to connect with a professional they will appear here.',
      ),
      const SizedBox(height: 12),
      _clientConnectionsCard(
        title: 'Accepted connections',
        icon: Icons.check_circle_outline,
        items: _clientAcceptedConnections,
        emptyTitle: 'No accepted connections yet',
        emptyDescription:
            'Accepted professionals will show up here once your requests are approved.',
      ),
      const SizedBox(height: 12),
      _quickActionsCard(),
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
        : _memberWelcomeMessage();

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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final sub = _activeSubscription;
    if (_hasActiveSubscription && sub != null) {
      final planName = (sub['planName']?.toString() ?? 'Active plan').trim();
      final renewalText = _subscriptionRenewal != null
          ? 'Renews ${_formatDateShort(_subscriptionRenewal!)}'
          : 'Billing details unavailable';
      final sessionsLeft = _subscriptionSessionsRemaining;
      final trialBadge = _subscriptionOnTrial
          ? Chip(
              label: Text(
                'Free trial${_subscriptionDaysLeft != null ? ' · ${_subscriptionDaysLeft}d left' : ''}',
              ),
              backgroundColor: Colors.indigo.shade50,
              labelStyle:
                  theme.textTheme.labelMedium?.copyWith(color: scheme.primary),
            )
          : null;
      return Card(
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.workspace_premium_outlined),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(planName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        )),
                  ),
                  if (trialBadge != null) trialBadge,
                ],
              ),
              const SizedBox(height: 12),
              Text(
                renewalText,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
              if (sessionsLeft != null) ...[
                const SizedBox(height: 8),
                Text('Sessions remaining: $sessionsLeft',
                    style: theme.textTheme.bodyMedium),
              ],
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  TextButton.icon(
                    onPressed: () =>
                        Navigator.of(context).pushNamed('/member/packages'),
                    icon: const Icon(Icons.manage_accounts_outlined),
                    label: const Text('Manage package'),
                  ),
                  if (_subscriptionOnTrial)
                    TextButton.icon(
                      onPressed: () =>
                          Navigator.of(context).pushNamed('/member/packages'),
                      icon: const Icon(Icons.upgrade_outlined),
                      label: const Text('Upgrade now'),
                    ),
                ],
              )
            ],
          ),
        ),
      );
    }

    if (_subscriptionExpired) {
      return Card(
        elevation: 0,
        color: Colors.red.shade50,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.red),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Your subscription has expired. Renew to continue booking and joining sessions.',
                ),
              ),
              FilledButton(
                onPressed: () =>
                    Navigator.of(context).pushNamed('/member/packages'),
                child: const Text('Renew'),
              ),
            ],
          ),
        ),
      );
    }

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
                'You do not have an active package. Subscribe to unlock session bundles, progress tracking, and premium support.',
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

  Widget _subscriptionCard() => _subscriptionReminderCard();

  Widget _clientConnectionsCard({
    required String title,
    required IconData icon,
    required List<ConnectionItem> items,
    required String emptyTitle,
    required String emptyDescription,
  }) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final preview = items.take(3).toList(growable: false);
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: scheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                TextButton(
                  onPressed: () =>
                      Navigator.of(context).pushNamed('/member/connections'),
                  child: const Text('View all'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (items.isEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(emptyTitle,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(
                    emptyDescription,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.of(context)
                        .pushNamed('/member/find-professional'),
                    icon: const Icon(Icons.search),
                    label: const Text('Find a professional'),
                  ),
                ],
              )
            else ...[
              for (var i = 0; i < preview.length; i++) ...[
                _clientConnectionTile(preview[i]),
                if (i != preview.length - 1)
                  Divider(color: scheme.outlineVariant, height: 16),
              ],
            ],
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

  Widget _clientConnectionTile(ConnectionItem item) {
    final name =
        item.professionalName.isNotEmpty ? item.professionalName : 'Professional';
    final avatarUrl = item.professionalAvatar ?? '';
    final initials = name.isNotEmpty ? name.characters.first.toUpperCase() : 'P';
    final subtitleParts = <String>[];
    final specLabel = _formatSpecializationLabel(
        item.professionalSpecialization ?? item.requestType);
    if (specLabel != null) subtitleParts.add(specLabel);
    subtitleParts.add(_formatDateShort(item.createdAt.toLocal()));
    final subtitle = subtitleParts.join(' • ');

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundImage:
            avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
        child: avatarUrl.isEmpty ? Text(initials) : null,
      ),
      title: Text(name),
      subtitle: Text(subtitle),
      trailing: _connectionStatusPill(item.status),
      onTap: () =>
          Navigator.of(context).pushNamed('/member/connections'),
    );
  }

  Widget _connectionStatusPill(ConnectionStatus status) {
    Color bg;
    Color fg;
    switch (status) {
      case ConnectionStatus.PENDING:
        bg = Colors.amber.shade100;
        fg = Colors.amber.shade900;
        break;
      case ConnectionStatus.ACCEPTED:
        bg = Colors.green.shade100;
        fg = Colors.green.shade800;
        break;
      case ConnectionStatus.TRANSFERRED:
        bg = Colors.purple.shade100;
        fg = Colors.purple.shade800;
        break;
      case ConnectionStatus.ESCALATED:
        bg = Colors.orange.shade100;
        fg = Colors.orange.shade800;
        break;
      case ConnectionStatus.BLOCKED:
        bg = Colors.grey.shade300;
        fg = Colors.grey.shade800;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16)),
      child: Text(
        connectionStatusLabel(status),
        style: TextStyle(color: fg, fontWeight: FontWeight.w600),
      ),
    );
  }

  String? _formatSpecializationLabel(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final match = specializationFromString(raw);
    if (match != null) {
      return specializationLabels[match];
    }
    return raw
        .split('_')
        .map((part) =>
            part.isEmpty ? '' : '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}')
        .join(' ');
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

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final metrics = [
      (
        label: 'Active goals',
        value: active.toString(),
        icon: Icons.flag_outlined,
      ),
      (
        label: 'Completed (7d)',
        value: completed7.toString(),
        icon: Icons.check_circle_outline,
      ),
      (
        label: 'Suggested goals',
        value: suggested.toString(),
        icon: Icons.lightbulb_outline,
      ),
      (
        label: 'Sessions (7d)',
        value: sessions7.toString(),
        icon: Icons.video_call_outlined,
      ),
    ];

    final hasGoals = active > 0 || suggested > 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.insights_outlined),
                const SizedBox(width: 12),
                Text('Your Progress',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                const spacing = 12.0;
                final availableWidth = constraints.maxWidth;
                final tileWidth =
                    math.max(140.0, (availableWidth - spacing) / 2);
                return Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: [
                    for (final metric in metrics)
                      SizedBox(
                        width: tileWidth,
                        child: _metricTile(
                          metric.label,
                          metric.value,
                          metric.icon,
                          theme,
                          scheme,
                        ),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            Text('Last session: $lastAgo ago'),
            Text('Next session: $nextAt'),
            if (topGoals.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text('Top active goals:'),
              const SizedBox(height: 4),
              ...topGoals,
            ] else if (!hasGoals) ...[
              const SizedBox(height: 16),
              Text(
                'No active goals yet. Start one to get personalized guidance.',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _metricTile(String label, String value, IconData icon, ThemeData theme,
      ColorScheme scheme) {
    return Container(
      padding: const EdgeInsets.all(12),
      constraints: const BoxConstraints(minWidth: 140),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: scheme.primary),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(label,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: scheme.onSurfaceVariant)),
        ],
      ),
    );
  }

  Widget _quickActionsCard() {
    final isTrial = _subscriptionOnTrial;
    final nextSessionScheduled =
        (_progress?['nextSessionAt']?.toString() ?? '').isNotEmpty;
    final suggestedGoals = (_progress?['suggestedGoals'] ?? 0) as num? ?? 0;
    final actions = <Widget>[];

    actions.add(ActionChip(
      avatar: const Icon(Icons.refresh_outlined, size: 18),
      label: const Text('Refresh dashboard'),
      onPressed: _load,
    ));

    if (!nextSessionScheduled) {
      actions.add(ActionChip(
        avatar: const Icon(Icons.calendar_month_outlined, size: 18),
        label: const Text('Schedule a session'),
        onPressed: () =>
            Navigator.of(context).pushNamed('/member/schedule-session'),
      ));
    } else {
      actions.add(ActionChip(
        avatar: const Icon(Icons.calendar_today_outlined, size: 18),
        label: const Text('View sessions'),
        onPressed: () => Navigator.of(context).pushNamed('/member/sessions'),
      ));
    }

    if (!_hasActiveSubscription || isTrial) {
      actions.add(ActionChip(
        avatar: const Icon(Icons.upgrade_outlined, size: 18),
        label: Text(isTrial ? 'Upgrade plan' : 'Browse packages'),
        onPressed: () => Navigator.of(context).pushNamed('/member/packages'),
      ));
    }

    if (suggestedGoals > 0) {
      actions.add(ActionChip(
        avatar: const Icon(Icons.lightbulb_outline, size: 18),
        label: const Text('Review suggested goals'),
        onPressed: () => Navigator.of(context).pushNamed('/member/goals'),
      ));
    }

    if (actions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 0,
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
              children: actions,
            ),
          ],
        ),
      ),
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

  String _formatDateShort(DateTime date) {
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
    final dow = weekdays[date.weekday - 1];
    final month = months[date.month - 1];
    return '$dow, $month ${date.day}';
  }

  String _memberWelcomeMessage() {
    if (_progress != null) {
      final completed = (_progress?['completedGoals7d'] ?? 0) as num? ?? 0;
      final active = (_progress?['activeGoals'] ?? 0) as num? ?? 0;
      if (completed > 0) {
        return 'Great job completing $completed goal${completed == 1 ? '' : 's'} this week. Keep the momentum going!';
      }
      if (active > 0) {
        return 'You have $active active goal${active == 1 ? '' : 's'} waiting. Check in to stay on track.';
      }
    }
    if (_subscriptionOnTrial) {
      if (_subscriptionDaysLeft != null) {
        return 'Enjoy your Mindapax trial. $_subscriptionDaysLeft day${_subscriptionDaysLeft == 1 ? '' : 's'} left to explore everything.';
      }
      return 'Enjoy your Mindapax trial. Explore goals and sessions today.';
    }
    if (!_hasActiveSubscription) {
      return 'Activate a package to unlock guided goals, sessions, and personalized support.';
    }
    return 'Track your goals, sessions, and progress at a glance.';
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
