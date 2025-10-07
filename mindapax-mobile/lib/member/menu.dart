import 'package:flutter/material.dart';
import '../auth/token_storage.dart';
import '../auth/jwt.dart';
import 'nav_prefs.dart';
import '../auth/auth_service.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'dart:io' show Platform;
import '../auth/authorized_client.dart';
import '../env.dart';
import '../dev/role_override.dart';

class MemberDrawer extends StatefulWidget {
  final String currentRoute;
  const MemberDrawer({super.key, required this.currentRoute});

  @override
  State<MemberDrawer> createState() => _MemberDrawerState();
}

class _MemberDrawerState extends State<MemberDrawer> {
  final _storage = TokenStorage();
  final _auth = AuthService();
  late Future<List<String>> _rolesFuture;
  int _activeGoals = 0;

  @override
  void initState() {
    super.initState();
    _rolesFuture = _loadRoles();
    _loadActiveGoalsCount();
  }

  Future<List<String>> _loadRoles() async {
    // Use override in debug mode when set
    if (kDebugMode && RoleOverride.roles != null) {
      return RoleOverride.roles!;
    }
    final token = await _storage.getAccessToken();
    final payload = token != null ? decodeJwtPayload(token) : null;
    final raw = payload?['roles'];
    List<String> result = const <String>[];
    if (raw is List) {
      result = raw.map((e) => e.toString()).toList();
    } else if (raw is String) {
      // Backend sets a single authority string like "ROLE_USER"
      // Also handle comma-separated just in case
      result = raw
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    // Normalize to ROLE_* format for matching
    result = result
        .map((r) => r.startsWith('ROLE_') ? r : 'ROLE_${r.toUpperCase()}')
        .toList(growable: false);
    return result;
  }

  Future<void> _loadActiveGoalsCount() async {
    try {
      final client = AuthorizedHttpClient(_storage);
      String base = apiBaseUrl.replaceAll(RegExp(r'/+$'), '');
      try {
        final u = Uri.parse(base);
        if (u.host == 'localhost' && Platform.isAndroid) {
          base = base.replaceFirst('localhost', '10.0.2.2');
        }
      } catch (_) {}
      final uri = Uri.parse('$base/assistant/goals');
      final res = await client.get(uri);
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final list = (jsonDecode(res.body) as List<dynamic>);
        int count = 0;
        for (final e in list) {
          final m = e as Map<String, dynamic>;
          final status = (m['status']?.toString() ?? '').toUpperCase();
          if (status == 'ACTIVE') count++;
        }
        if (mounted) setState(() => _activeGoals = count);
      }
    } catch (_) {
      // ignore
    }
  }

  void _go(String route) {
    if (route == widget.currentRoute) {
      Navigator.pop(context);
    } else {
      Navigator.pop(context);
      NavPrefs.saveLastRoute(route);
      Navigator.pushReplacementNamed(context, route);
    }
  }

  Future<void> _logout() async {
    await _auth.logout();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/auth/login', (r) => false);
  }

  @override
  Widget build(BuildContext context) {
    final items = <_MenuItem>[
      _MenuItem('Home', '/member/dashboard', Icons.home_outlined,
          const ['ROLE_USER', 'ROLE_PROFESSIONAL', 'ROLE_ADMIN']),
      _MenuItem('Find a Professional', '/member/find-professional',
          Icons.search, const ['ROLE_USER']),
      _MenuItem(
          'My Sessions',
          '/member/sessions',
          Icons.calendar_today_outlined,
          const ['ROLE_USER', 'ROLE_PROFESSIONAL']),
      _MenuItem('Messages', '/member/messages', Icons.chat_bubble_outline,
          const ['ROLE_USER', 'ROLE_PROFESSIONAL']),
      _MenuItem('AI Assistant', '/member/assistant', Icons.smart_toy_outlined,
          const ['ROLE_USER', 'ROLE_PROFESSIONAL', 'ROLE_ADMIN']),
      _MenuItem(
          'My Goals${_activeGoals > 0 ? ' ($_activeGoals)' : ''}',
          '/member/goals',
          Icons.flag_outlined,
          const ['ROLE_USER', 'ROLE_PROFESSIONAL', 'ROLE_ADMIN']),
      _MenuItem('Connections', '/member/connections',
          Icons.person_add_alt_1_outlined, const ['ROLE_PROFESSIONAL']),
      _MenuItem('Professionals', '/member/professionals',
          Icons.people_alt_outlined, const ['ROLE_ADMIN']),
      _MenuItem('Billing', '/member/billing', Icons.credit_card,
          const ['ROLE_USER', 'ROLE_PROFESSIONAL', 'ROLE_ADMIN']),
      _MenuItem('Packages', '/member/packages', Icons.subscriptions_outlined,
          const ['ROLE_USER', 'ROLE_PROFESSIONAL', 'ROLE_ADMIN']),
      _MenuItem('My Subscriptions', '/member/subscriptions', Icons.receipt_long,
          const ['ROLE_USER', 'ROLE_PROFESSIONAL', 'ROLE_ADMIN']),
      _MenuItem('Make a Payment', '/member/pay', Icons.payment_outlined,
          const ['ROLE_USER', 'ROLE_PROFESSIONAL', 'ROLE_ADMIN']),
      _MenuItem('Payment History', '/member/payments', Icons.receipt_long_outlined,
          const ['ROLE_USER', 'ROLE_PROFESSIONAL', 'ROLE_ADMIN']),
      _MenuItem('Settings', '/member/settings', Icons.settings_outlined,
          const ['ROLE_USER', 'ROLE_PROFESSIONAL', 'ROLE_ADMIN']),
    ];

    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            const ListTile(
              title: Text('Mindapax',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ),
            const Divider(height: 1),
            Expanded(
              child: FutureBuilder<List<String>>(
                future: _rolesFuture,
                builder: (context, snapshot) {
                  final roles = snapshot.data ?? const <String>[];
                  return ListView(
                    children: [
                      for (final i in items)
                        if (i.allowedRoles.isEmpty ||
                            i.allowedRoles.any(roles.contains))
                          ListTile(
                            leading: Icon(i.icon),
                            title: Text(i.label),
                            selected: widget.currentRoute == i.route,
                            onTap: () => _go(i.route),
                          ),
                      if (kDebugMode) const Divider(),
                      if (kDebugMode)
                        const ListTile(
                          title: Text('Debug: Roles Override',
                              style: TextStyle(fontWeight: FontWeight.w600)),
                        ),
                      if (kDebugMode)
                        ListTile(
                          leading: const Icon(Icons.person_outline),
                          title: const Text('As USER'),
                          onTap: () async {
                            RoleOverride.setRoles(const ['ROLE_USER']);
                            setState(() => _rolesFuture = _loadRoles());
                          },
                        ),
                      if (kDebugMode)
                        ListTile(
                          leading: const Icon(Icons.badge_outlined),
                          title: const Text('As PROFESSIONAL'),
                          onTap: () async {
                            RoleOverride.setRoles(const ['ROLE_PROFESSIONAL']);
                            setState(() => _rolesFuture = _loadRoles());
                          },
                        ),
                      if (kDebugMode)
                        ListTile(
                          leading:
                              const Icon(Icons.admin_panel_settings_outlined),
                          title: const Text('As ADMIN'),
                          onTap: () async {
                            RoleOverride.setRoles(const ['ROLE_ADMIN']);
                            setState(() => _rolesFuture = _loadRoles());
                          },
                        ),
                      if (kDebugMode)
                        ListTile(
                          leading: const Icon(Icons.clear),
                          title: const Text('Clear Override'),
                          onTap: () async {
                            RoleOverride.setRoles(null);
                            setState(() => _rolesFuture = _loadRoles());
                          },
                        ),
                    ],
                  );
                },
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: _logout,
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuItem {
  final String label;
  final String route;
  final IconData icon;
  final List<String> allowedRoles;
  _MenuItem(this.label, this.route, this.icon, this.allowedRoles);
}
