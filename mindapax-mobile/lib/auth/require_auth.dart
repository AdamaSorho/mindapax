import 'package:flutter/material.dart';
import 'auth_service.dart';

class RequireAuth extends StatefulWidget {
  final Widget child;
  const RequireAuth({super.key, required this.child});

  @override
  State<RequireAuth> createState() => _RequireAuthState();
}

class _RequireAuthState extends State<RequireAuth> {
  final _auth = AuthService();
  bool? _allowed;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final ok = await _auth.ensureAuthenticated();
    if (!mounted) return;
    if (!ok) {
      // redirect to login
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushNamedAndRemoveUntil('/auth/login', (r) => false);
      });
      setState(() => _allowed = false);
    } else {
      setState(() => _allowed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_allowed == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_allowed == false) {
      return const Scaffold();
    }
    return widget.child;
  }
}
