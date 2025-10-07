import 'package:flutter/material.dart';
import 'dart:convert';
import 'auth_service.dart';
import 'authorized_client.dart';
import 'token_storage.dart';
import '../env.dart';
import 'dart:io' show Platform;
import '../member/onboarding_prefs.dart';
import '../member/nav_prefs.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = false;
  bool _obscure = true;
  bool _loading = false;
  String? _error;

  final _auth = AuthService();
  final _storage = TokenStorage();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await _auth.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (!mounted) return;
      final target = await NavPrefs.getLastRoute();
      if (!mounted) return;
      final needsOnboarding = await _shouldRunOnboarding();
      if (!mounted) return;
      if (needsOnboarding) {
        Navigator.of(context).pushNamedAndRemoveUntil('/member/onboarding', (r) => false);
      } else {
        Navigator.of(context).pushNamedAndRemoveUntil(target, (r) => false);
      }
    } catch (e) {
      final friendly = _friendlyLoginError(e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(friendly)),
        );
        setState(() => _error = friendly);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _friendlyLoginError(Object e) {
    final t = e.toString().toLowerCase().replaceFirst('exception: ', '');
    // Common auth failures
    if (t.contains('unauthorized') ||
        t.contains('invalid') ||
        t.contains('bad credentials') ||
        t.contains('wrong') ||
        t.contains('not found')) {
      return 'Incorrect email or password. Please try again.';
    }
    // Network/connectivity/timeouts
    if (t.contains('socket') ||
        t.contains('failed host lookup') ||
        t.contains('timed out') ||
        t.contains('timeout') ||
        t.contains('network') ||
        t.contains('connection refused')) {
      return 'Unable to reach the server. Check your internet connection and try again.';
    }
    // Generic
    return 'We couldn\'t sign you in. Please try again in a moment.';
  }

  Future<bool> _shouldRunOnboarding() async {
    // If already completed locally, skip
    if (await OnboardingPrefs.isCompleted()) return false;
    // Ask server if assistant context is completed
    try {
      final client = AuthorizedHttpClient(_storage);
      final uri = Uri.parse('${_normalizeBaseUrl(apiBaseUrl)}/assistant/context/completed');
      final res = await client.get(uri);
      if (res.statusCode >= 200 && res.statusCode < 300 && res.body.isNotEmpty) {
        final m = jsonDecode(res.body) as Map<String, dynamic>;
        final completed = (m['completed'] == true);
        return !completed; // run onboarding if not completed
      }
    } catch (_) {}
    // Default to true (show onboarding) if unsure
    return true;
  }

  String _normalizeBaseUrl(String value) {
    final cleaned = value.replaceAll(RegExp(r'/+$'), '');
    try {
      final u = Uri.parse(cleaned);
      if (u.host == 'localhost' && Platform.isAndroid) {
        return cleaned.replaceFirst('localhost', '10.0.2.2');
      }
    } catch (_) {}
    return cleaned;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Log In')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Email is required';
                    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                    if (!emailRegex.hasMatch(v.trim())) return 'Enter a valid email';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscure,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    suffixIcon: IconButton(
                      icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  validator: (v) => (v == null || v.isEmpty) ? 'Password is required' : null,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Checkbox(
                      value: _rememberMe,
                      onChanged: (v) => setState(() => _rememberMe = v ?? false),
                    ),
                    const Text('Remember me'),
                    const Spacer(),
                    TextButton(
                      onPressed: () => Navigator.pushNamed(context, '/auth/forgot-password'),
                      child: const Text('Forgot password?'),
                    )
                  ],
                ),
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                ],
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Log In'),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: _loading ? null : () => Navigator.pushNamed(context, '/auth/register'),
                  child: const Text('Create an account'),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
