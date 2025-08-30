import 'package:flutter/material.dart';
import '../auth/token_storage.dart';
import '../auth/jwt.dart';
import '../auth/auth_service.dart';
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
  String? _userEmail;
  Map<String, dynamic>? _user;
  bool _loading = true;

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
    if (mounted) setState(() => _loading = false);
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
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Welcome to Mindapax!'),
                  const SizedBox(height: 8),
                  if (_userEmail != null) Text('Signed in as $_userEmail'),
                  const SizedBox(height: 16),
                  if (_user != null)
                    Text('Hello, ${_user!['firstName'] ?? ''} ${_user!['lastName'] ?? ''}'),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: _logout,
                    icon: const Icon(Icons.logout),
                    label: const Text('Logout'),
                  )
                ],
              ),
            ),
    );
  }
}
