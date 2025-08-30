import 'package:flutter/material.dart';
import '../auth/token_storage.dart';
import '../auth/jwt.dart';
import 'nav_prefs.dart';
import 'menu.dart';

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
    final token = await _storage.getAccessToken();
    final payload = token != null ? decodeJwtPayload(token) : null;
    final roles = payload?['roles'];
    if (roles is List) {
      setState(() => _roles = roles.map((e) => e.toString()).toList());
    }
    setState(() => _loaded = true);
    // After roles are known, optionally redirect to last saved route if different and permitted
    final saved = await NavPrefs.getLastRoute();
    final allowedRoutes = _visibleItems.map((i) => i.route).toSet();
    if (saved != widget.currentRoute && allowedRoutes.contains(saved)) {
      // Schedule redirect after first frame to avoid build issues
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.pushReplacementNamed(context, saved);
        });
      }
    }
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
