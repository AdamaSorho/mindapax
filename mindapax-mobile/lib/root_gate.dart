import 'package:flutter/material.dart';
import 'auth/auth_service.dart';
import 'auth/token_storage.dart';
import 'auth/jwt.dart';
import 'member/nav_prefs.dart';
import 'main.dart' show HomePage; // reuse existing HomePage
import 'splash.dart';

class RootGate extends StatefulWidget {
  const RootGate({super.key});

  @override
  State<RootGate> createState() => _RootGateState();
}

class _RootGateState extends State<RootGate> {
  final _auth = AuthService();
  final _storage = TokenStorage();
  bool _deciding = true;

  @override
  void initState() {
    super.initState();
    _decide();
  }

  Future<void> _decide() async {
    final authed = await _auth.isAuthenticated();
    if (!mounted) return;
    if (authed) {
      final savedRoute = await NavPrefs.getLastRoute();
      final target = await _resolveLandingRoute(savedRoute);
      if (target != savedRoute) {
        await NavPrefs.saveLastRoute(target);
      }
      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, target);
      });
    } else {
      setState(() => _deciding = false);
    }
  }

  Future<String> _resolveLandingRoute(String? route) async {
    final requested =
        (route == null || route.isEmpty) ? NavPrefs.defaultRoute : route;
    final token = await _storage.getAccessToken();
    if (token == null || token.isEmpty) {
      return requested;
    }
    final payload = decodeJwtPayload(token);
    final roles = _normalizeRoles(payload?['roles']);
    if (roles.contains('ROLE_PROFESSIONAL')) {
      const allowed = {
        '/member/dashboard',
        '/member/sessions',
        '/member/messages',
        '/member/connections',
        '/member/settings',
      };
      if (!allowed.contains(requested)) {
        return '/member/sessions';
      }
    }
    return requested;
  }

  List<String> _normalizeRoles(dynamic raw) {
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

  @override
  Widget build(BuildContext context) {
    if (_deciding) return const BrandedSplash();
    return const HomePage();
  }
}
