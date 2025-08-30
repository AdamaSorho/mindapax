import 'package:flutter/material.dart';
import 'auth/auth_service.dart';
import 'member/nav_prefs.dart';
import 'main.dart' show HomePage; // reuse existing HomePage

class RootGate extends StatefulWidget {
  const RootGate({super.key});

  @override
  State<RootGate> createState() => _RootGateState();
}

class _RootGateState extends State<RootGate> {
  final _auth = AuthService();
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
      final route = await NavPrefs.getLastRoute();
      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, route);
      });
    } else {
      setState(() => _deciding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_deciding) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return const HomePage();
  }
}

