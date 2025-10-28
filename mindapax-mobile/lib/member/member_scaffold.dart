import 'package:flutter/material.dart';
import '../auth/token_storage.dart';
import '../auth/jwt.dart';
import 'nav_prefs.dart';
import 'menu.dart';
import 'package:flutter/foundation.dart';
import '../dev/role_override.dart';

class _NavItem {
  final String label;
  final String route;
  final IconData icon;
  final List<String> roles; // empty means everyone
  const _NavItem(this.label, this.route, this.icon, this.roles);
}

class MemberScaffold extends StatefulWidget {
  final String title;
  final String currentRoute;
  final Widget child;
  const MemberScaffold({super.key, required this.title, required this.currentRoute, required this.child});

  @override
  State<MemberScaffold> createState() => _MemberScaffoldState();
}

class _MemberScaffoldState extends State<MemberScaffold> {
  final _storage = TokenStorage();
  List<String> _roles = const [];
  bool _loaded = false;

  static const _allItems = <_NavItem>[
    _NavItem('Home', '/member/dashboard', Icons.home_outlined, ['ROLE_USER', 'ROLE_PROFESSIONAL', 'ROLE_ADMIN']),
    _NavItem('Find', '/member/find-professional', Icons.search, ['ROLE_USER']),
    _NavItem('Sessions', '/member/sessions', Icons.calendar_today_outlined, ['ROLE_USER', 'ROLE_PROFESSIONAL']),
    _NavItem('Messages', '/member/messages', Icons.chat_bubble_outline, ['ROLE_USER', 'ROLE_PROFESSIONAL']),
    _NavItem('Connections', '/member/connections', Icons.person_add_alt_1_outlined, ['ROLE_PROFESSIONAL']),
    _NavItem('Settings', '/member/settings', Icons.settings_outlined, ['ROLE_USER', 'ROLE_PROFESSIONAL', 'ROLE_ADMIN']),
  ];

  List<_NavItem> get _visibleItems {
    return _allItems.where((i) => i.roles.isEmpty || i.roles.any(_roles.contains)).toList(growable: false);
  }

  int get _currentIndex {
    final idx = _visibleItems.indexWhere((i) => i.route == widget.currentRoute);
    return idx == -1 ? 0 : idx;
  }

  @override
  void initState() {
    super.initState();
    _loadRoles();
  }

  Future<void> _loadRoles() async {
    List<String> rolesList = const [];
    // Use override in debug when present
    if (kDebugMode && RoleOverride.roles != null) {
      rolesList = RoleOverride.roles!;
    } else {
      final token = await _storage.getAccessToken();
      final payload = token != null ? decodeJwtPayload(token) : null;
      final raw = payload?['roles'];
      if (raw is List) {
        rolesList = raw.map((e) => e.toString()).toList();
      } else if (raw is String) {
        rolesList = raw.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      }
      // Normalize to ROLE_* format
      rolesList = rolesList
          .map((r) => r.startsWith('ROLE_') ? r : 'ROLE_${r.toUpperCase()}')
          .toList(growable: false);
    }
    if (rolesList.isNotEmpty) {
      setState(() => _roles = rolesList);
    }
    setState(() => _loaded = true);
    // Do not auto-redirect here. RootGate performs the initial
    // navigation to the last saved route after authentication.
    // Auto-redirecting from every MemberScaffold causes pages like
    // Packages to bounce back to the previously saved route.
  }

  void _onTap(int index) {
    final target = _visibleItems[index].route;
    if (target == widget.currentRoute) return;
    NavPrefs.saveLastRoute(target);
    Navigator.pushReplacementNamed(context, target);
  }

  @override
  Widget build(BuildContext context) {
    var items = _visibleItems;
    // Ensure at least two items to satisfy BottomNavigationBar assertion
    if (!_loaded || items.length < 2) {
      items = const [
        _NavItem('Home', '/member/dashboard', Icons.home_outlined, []),
        _NavItem('Settings', '/member/settings', Icons.settings_outlined, []),
      ];
    }
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      drawer: MemberDrawer(currentRoute: widget.currentRoute),
      body: widget.child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTap,
        type: BottomNavigationBarType.fixed,
        items: [
          for (final i in items) BottomNavigationBarItem(icon: Icon(i.icon), label: i.label),
        ],
      ),
    );
  }
}
