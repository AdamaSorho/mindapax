import 'package:flutter/material.dart';
import '../auth/token_storage.dart';
import '../auth/jwt.dart';
import '../auth/auth_service.dart';
import '../professional/models.dart' show PagedResponse, Professional;
import '../professional/professional_api.dart';
import '../member/member_scaffold.dart';
import '../sessions/models.dart';
import '../sessions/sessions_api.dart';
import 'package:url_launcher/url_launcher.dart';
import 'zoom_webview_page.dart';
import 'settings_prefs.dart';
import 'package:permission_handler/permission_handler.dart';

class SessionsPage extends StatefulWidget {
  final SessionsApi? api;
  const SessionsPage({super.key, this.api});

  @override
  State<SessionsPage> createState() => _SessionsPageState();
}

class _SessionsPageState extends State<SessionsPage> {
  late final SessionsApi _api = widget.api ?? SessionsApi();
  final _storage = TokenStorage();
  final _auth = AuthService();
  final _proApi = ProfessionalApi();

  bool _loading = false;
  String? _error;
  String _activeTab = 'upcoming';
  List<Session> _upcoming = const [];
  List<Session> _past = const [];
  int _page = 0;
  final int _pageSize = 10;

  int? _ownerId; // userId for clients, professionalId for professionals
  bool _isProfessional = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final token = await _storage.getAccessToken();
    final payload = token != null ? decodeJwtPayload(token) : null;
    final userId = (payload?['id'] as num?)?.toInt();
    // Determine roles
    List<String> roles = [];
    final raw = payload?['roles'];
    if (raw is List) {
      roles = raw.map((e) => e.toString()).toList();
    } else if (raw is String) {
      roles = raw
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    roles = roles
        .map((r) => r.startsWith('ROLE_') ? r : 'ROLE_${r.toUpperCase()}')
        .toList();
    // If professional, resolve professionalId from backend, else use userId
    if (roles.contains('ROLE_PROFESSIONAL')) {
      _isProfessional = true;
      try {
        final me = await _proApi.getMe();
        _ownerId = me.id;
      } catch (e) {
        // Fallback to userId if professional profile lookup fails
        _ownerId = userId;
      }
    } else {
      _ownerId = userId;
    }
    await Future.wait([
      _fetchUpcoming(resetPage: true),
      _fetchPast(resetPage: true),
    ]);
  }

  Future<void> _fetchUpcoming({bool resetPage = false}) async {
    setState(() {
      _loading = true;
      _error = null;
      if (resetPage) _page = 0;
    });
    try {
      final res = await _api.getSessions(SessionQueryParams(
        userId: _ownerId ?? 0,
        filter: SessionTimeFilter.UPCOMING,
        date: DateTime.now(),
        status: SessionStatus.SCHEDULED,
        page: _page,
        size: _pageSize,
        sort: 'startTime,asc',
      ));
      setState(() => _upcoming = res.content);
    } catch (e) {
      final msg = e.toString();
      String hint = '';
      if (msg.contains('403')) {
        hint =
            ' (forbidden). Ensure you are signed in with the correct role. If you are a professional, sessions may require your professional profile to be set up.';
      }
      setState(() => _error = 'Failed to load upcoming sessions: $msg$hint');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _fetchPast({bool resetPage = false}) async {
    setState(() {
      _loading = true;
      _error = null;
      if (resetPage) _page = 0;
    });
    try {
      final res = await _api.getSessions(SessionQueryParams(
        userId: _ownerId ?? 0,
        filter: SessionTimeFilter.PAST,
        date: DateTime.now(),
        status: SessionStatus.SCHEDULED,
        page: _page,
        size: _pageSize,
        sort: 'startTime,asc',
      ));
      setState(() => _past = res.content);
    } catch (e) {
      final msg = e.toString();
      String hint = '';
      if (msg.contains('403')) {
        hint = ' (forbidden). Ensure you are signed in with the correct role.';
      }
      setState(() => _error = 'Failed to load past sessions: $msg$hint');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  DateTime? _calculatedEndTime(Session s) {
    if (s.durationMinutes <= 0) return null;
    return s.startTime.add(Duration(minutes: s.durationMinutes));
  }

  bool _isToday(Session s) {
    final d = s.startTime.toLocal();
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }

  bool _isJoinable(Session s) {
    if (s.mode != SessionMode.VIDEO || s.status != SessionStatus.SCHEDULED)
      return false;
    final now = DateTime.now().millisecondsSinceEpoch;
    final start = s.startTime.millisecondsSinceEpoch;
    final joinWindowStart = start - 15 * 60 * 1000;
    final joinWindowEnd =
        start + (s.durationMinutes.clamp(1, 24 * 60)) * 60 * 1000;
    return now >= joinWindowStart && now <= joinWindowEnd;
  }

  String _relativeDate(DateTime d) {
    final now = DateTime.now();
    final a = DateTime(d.year, d.month, d.day);
    final b = DateTime(now.year, now.month, now.day);
    final diffDays = a.difference(b).inDays;
    if (diffDays == 0) return 'Today';
    if (diffDays == 1) return 'Tomorrow';
    if (diffDays == -1) return 'Yesterday';
    if (diffDays.abs() < 7) {
      // Weekday label
      const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return names[d.weekday - 1];
    }
    return '${d.month}/${d.day}/${d.year}';
  }

  Future<void> _joinVideo(Session s) async {
    if (s.id == null) return;
    try {
      setState(() => _loading = true);
      final zoom = await _api.getZoomMeetingSignature(s.id!);
      if (!mounted) return;
      // Determine join method based on Settings (default: Zoom app)
      final method = await SettingsPrefs.getJoinMethod();
      // Ask runtime permissions if needed
      final ok = await _ensurePermissions(method);
      if (!ok) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Camera and microphone permissions are required to join the session.')),
        );
        return;
      }
      final token = await _storage.getAccessToken();
      final payload = token != null ? decodeJwtPayload(token) : null;
      final email = payload?['sub']?.toString();
      final name = _extractNameFromEmail(email) ?? 'Mindapax User';

      if (method == SessionJoinMethod.zoomApp) {
        // Try Zoom deep link first, then fall back to web link
        final zoomUri = Uri.parse(
            'zoomus://zoom.us/join?confno=${Uri.encodeComponent(zoom.meetingNumber)}'
            '${zoom.password != null && zoom.password!.isNotEmpty ? '&pwd=${Uri.encodeComponent(zoom.password!)}' : ''}'
            '&uname=${Uri.encodeComponent(name)}');
        final webUri = Uri.parse(
            'https://zoom.us/j/${Uri.encodeComponent(zoom.meetingNumber)}'
            '${zoom.password != null && zoom.password!.isNotEmpty ? '?pwd=${Uri.encodeComponent(zoom.password!)}' : ''}');
        bool launched = false;
        try {
          launched =
              await launchUrl(zoomUri, mode: LaunchMode.externalApplication);
        } catch (_) {}
        if (!launched) {
          await launchUrl(webUri, mode: LaunchMode.externalApplication);
        }
      } else {
        // In-app WebView using Zoom Web SDK in frontend
        await Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => ZoomWebViewPage(
            meetingNumber: zoom.meetingNumber,
            signature: zoom.signature,
            password: zoom.password,
            userName: name,
            userEmail: email,
            sdkKey: zoom.apiKey,
          ),
        ));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to start video: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String? _extractNameFromEmail(String? email) {
    if (email == null || email.isEmpty) return null;
    final local = email.split('@').first;
    if (local.isEmpty) return null;
    return local.replaceAll('.', ' ').replaceAll('_', ' ');
  }

  Future<bool> _ensurePermissions(SessionJoinMethod method) async {
    // For Zoom app, permissions are typically handled by Zoom, but requesting here ensures smooth flow.
    // For WebView (Zoom Web SDK), camera/mic must be granted at OS level.
    try {
      // Use permission_handler only when compiled; avoid failures in tests.
      // Dynamically import isn't available, so keep call straightforward.
      // ignore: avoid_dynamic_calls
    } catch (_) {}
    // Defer to helper
    return _askCameraMicPermissions();
  }

  Future<bool> _askCameraMicPermissions() async {
    try {
      // Import is at top via dependency; perform requests here.
      // We import lazily by referencing symbols directly.
      // The analyzer will resolve these from permission_handler.
      final statuses = await [
        Permission.camera,
        Permission.microphone,
      ].request();
      final cam = statuses[Permission.camera];
      final mic = statuses[Permission.microphone];
      final granted = (cam?.isGranted ?? false) && (mic?.isGranted ?? false);
      if (!granted &&
          ((cam?.isPermanentlyDenied ?? false) ||
              (mic?.isPermanentlyDenied ?? false))) {
        // Prompt to open settings
        if (!mounted) return false;
        final open = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Permissions needed'),
            content: const Text(
                'Please enable Camera and Microphone permissions in Settings to join video sessions.'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel')),
              FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Open Settings')),
            ],
          ),
        );
        if (open == true) {
          await openAppSettings();
        }
      }
      return granted;
    } catch (_) {
      // If permission flow fails unexpectedly, allow join attempt rather than blocking
      return true;
    }
  }

  void _bookNew() {
    if (_isProfessional) {
      Navigator.pushNamed(context, '/member/schedule-session').then((value) async {
        if (value == true) {
          await _fetchUpcoming(resetPage: true);
        }
      });
    } else {
      Navigator.pushNamed(context, '/member/find-professional');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MemberScaffold(
      title: 'My Sessions',
      currentRoute: '/member/sessions',
      child: Column(
        children: [
          if (_loading) const LinearProgressIndicator(minHeight: 2),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(_error!, style: const TextStyle(color: Colors.red)),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                ChoiceChip(
                  label: const Text('Upcoming'),
                  selected: _activeTab == 'upcoming',
                  onSelected: (v) => setState(() => _activeTab = 'upcoming'),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Past'),
                  selected: _activeTab == 'past',
                  onSelected: (v) => setState(() => _activeTab = 'past'),
                ),
                const Spacer(),
                FilledButton.icon(
                  onPressed: _bookNew,
                  icon: const Icon(Icons.add),
                  label: const Text('Book New'),
                )
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                if (_activeTab == 'upcoming') {
                  await _fetchUpcoming();
                } else {
                  await _fetchPast();
                }
              },
              child: _activeTab == 'upcoming'
                  ? _upcoming.isEmpty
                      ? _emptyState('No upcoming sessions', _bookNew)
                      : ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: _upcoming.length,
                          itemBuilder: (context, i) => _SessionCard(
                            session: _upcoming[i],
                            joinable: _isJoinable(_upcoming[i]),
                            onJoin: () => _joinVideo(_upcoming[i]),
                          ),
                        )
                  : _past.isEmpty
                      ? _emptyState('No past sessions', _bookNew)
                      : ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: _past.length,
                          itemBuilder: (context, i) => _SessionCard(
                            session: _past[i],
                            joinable: false,
                            onJoin: null,
                          ),
                        ),
            ),
          )
        ],
      ),
    );
  }

  Widget _emptyState(String title, VoidCallback onAction) {
    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 72),
          child: Column(
            children: [
              const Icon(Icons.event_busy, size: 64, color: Colors.black26),
              const SizedBox(height: 12),
              Text(title, style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 12),
              OutlinedButton(
                  onPressed: onAction,
                  child: const Text('Find a Professional')),
            ],
          ),
        )
      ],
    );
  }
}

class _SessionCard extends StatelessWidget {
  final Session session;
  final bool joinable;
  final VoidCallback? onJoin;

  const _SessionCard(
      {required this.session, required this.joinable, this.onJoin});

  @override
  Widget build(BuildContext context) {
    final end = DateTime.tryParse(session.startTime
        .add(Duration(minutes: session.durationMinutes))
        .toIso8601String());
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 24,
              child: Text((session.professionalName ?? 'P')[0].toUpperCase()),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(session.professionalName ?? 'Professional',
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text(session.professionalSpecialization ?? 'Specialization',
                      style: const TextStyle(color: Colors.black54)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.today, size: 16, color: Colors.black54),
                      const SizedBox(width: 6),
                      Text(_dateLabel(session.startTime)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.schedule,
                          size: 16, color: Colors.black54),
                      const SizedBox(width: 6),
                      Text(
                          '${_timeOf(session.startTime)} - ${end != null ? _timeOf(end) : ''} (${session.durationMinutes} mins)'),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(_modeIcon(session.mode),
                          size: 16, color: Colors.black54),
                      const SizedBox(width: 6),
                      Text('${sessionModeToString(session.mode)} session'),
                    ],
                  ),
                  if ((session.notes ?? '').isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(session.notes!,
                        style: const TextStyle(color: Colors.black87)),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              children: [
                if (joinable)
                  FilledButton(
                    onPressed: onJoin,
                    child: const Text('Join'),
                  )
                else
                  OutlinedButton(
                    onPressed: null,
                    child: const Text('Join'),
                  ),
              ],
            )
          ],
        ),
      ),
    );
  }

  static String _dateLabel(DateTime d) {
    final now = DateTime.now();
    final a = DateTime(d.year, d.month, d.day);
    final b = DateTime(now.year, now.month, now.day);
    final diffDays = a.difference(b).inDays;
    if (diffDays == 0) return 'Today';
    if (diffDays == 1) return 'Tomorrow';
    if (diffDays == -1) return 'Yesterday';
    if (diffDays.abs() < 7) {
      const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return names[d.weekday - 1];
    }
    return '${d.month}/${d.day}/${d.year}';
  }

  static String _timeOf(DateTime d) {
    final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final m = d.minute.toString().padLeft(2, '0');
    final ampm = d.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $ampm';
  }

  static IconData _modeIcon(SessionMode mode) {
    switch (mode) {
      case SessionMode.VIDEO:
        return Icons.videocam_outlined;
      case SessionMode.CHAT:
        return Icons.chat_bubble_outline;
      case SessionMode.MESSAGE:
        return Icons.mail_outline;
    }
  }
}
