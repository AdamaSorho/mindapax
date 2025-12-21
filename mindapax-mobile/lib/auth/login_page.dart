import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'auth_service.dart';
import 'authorized_client.dart';
import 'token_storage.dart';
import '../env.dart';
import 'dart:io' show Platform;
import '../member/onboarding_prefs.dart';
import 'auth_exceptions.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  static const _rememberKey = 'login_remember_me';
  static const _rememberEmailKey = 'login_remember_email';

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _twoFactorController = TextEditingController();
  final FocusNode _twoFactorFocusNode = FocusNode();
  bool _rememberMe = false;
  bool _obscure = true;
  bool _loading = false;
  String? _error;
  bool _didShowRegistrationMessage = false;
  int _failedAttempts = 0;
  bool _twoFactorRequired = false;

  final _auth = AuthService();
  final _storage = TokenStorage();

  @override
  void initState() {
    super.initState();
    _loadRememberedCredentials();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _twoFactorController.dispose();
    _twoFactorFocusNode.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (!_didShowRegistrationMessage &&
        args is Map &&
        args['registered'] == true) {
      _didShowRegistrationMessage = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Registration successful. Please log in.')),
        );
      });
    }
  }

  Future<void> _loadRememberedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final remember = prefs.getBool(_rememberKey) ?? false;
    final email = prefs.getString(_rememberEmailKey);
    if (!mounted) return;
    setState(() {
      _rememberMe = remember;
      if (remember && email != null && email.isNotEmpty) {
        _emailController.text = email;
      }
    });
  }

  Future<void> _toggleRememberMe(bool value) async {
    setState(() => _rememberMe = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_rememberKey, value);
    if (!value) {
      await prefs.remove(_rememberEmailKey);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_twoFactorRequired) {
      final code = _twoFactorController.text.trim();
      if (code.length != 6) {
        setState(
            () => _error = 'Enter the 6-digit code from your authenticator.');
        return;
      }
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await _auth.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        twoFactorCode:
            _twoFactorRequired ? _twoFactorController.text.trim() : null,
        rememberMe: _rememberMe,
      );
      if (!mounted) return;
      await _handleRememberPreference();
      setState(() => _failedAttempts = 0);
      final needsOnboarding = await _shouldRunOnboarding();
      if (!mounted) return;
      if (needsOnboarding) {
        Navigator.of(context)
            .pushNamedAndRemoveUntil('/member/onboarding', (r) => false);
      } else {
        Navigator.of(context)
            .pushNamedAndRemoveUntil('/member/dashboard', (r) => false);
      }
      setState(() {
        _twoFactorRequired = false;
        _twoFactorController.clear();
      });
    } on TwoFactorCodeRequiredException {
      if (!mounted) return;
      setState(() {
        _twoFactorRequired = true;
        _error =
            'Two-factor authentication required. Enter the 6-digit code to continue.';
      });
      FocusScope.of(context).requestFocus(_twoFactorFocusNode);
    } on InvalidTwoFactorCodeException {
      if (!mounted) return;
      setState(() {
        _twoFactorRequired = true;
        _error = 'That code didn\'t match. Please try again.';
        _failedAttempts += 1;
      });
      _twoFactorController.clear();
      FocusScope.of(context).requestFocus(_twoFactorFocusNode);
    } catch (e) {
      final friendly = _friendlyLoginError(e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(friendly)),
        );
        setState(() {
          _error = friendly;
          _failedAttempts += 1;
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _handleRememberPreference() async {
    final prefs = await SharedPreferences.getInstance();
    if (_rememberMe) {
      await prefs.setBool(_rememberKey, true);
      await prefs.setString(_rememberEmailKey, _emailController.text.trim());
    } else {
      await prefs.setBool(_rememberKey, false);
      await prefs.remove(_rememberEmailKey);
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
    if (t.contains('two-factor')) {
      return 'Enter the six-digit authentication code to continue.';
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
      final uri = Uri.parse(
          '${_normalizeBaseUrl(apiBaseUrl)}/assistant/context/completed');
      final res = await client.get(uri);
      if (res.statusCode >= 200 &&
          res.statusCode < 300 &&
          res.body.isNotEmpty) {
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

  Future<void> _contactSupport() async {
    final uri = Uri(
      scheme: 'mailto',
      path: 'support@mindapax.com',
      queryParameters: const {'subject': 'Login support'},
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
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
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: AutofillGroup(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.email],
                    decoration: const InputDecoration(labelText: 'Email'),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Email is required';
                      }
                      final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                      if (!emailRegex.hasMatch(v.trim())) {
                        return 'Enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscure,
                    textInputAction: _twoFactorRequired
                        ? TextInputAction.next
                        : TextInputAction.done,
                    autofillHints: const [AutofillHints.password],
                    decoration: InputDecoration(
                      labelText: 'Password',
                      suffixIcon: IconButton(
                        icon: Icon(
                            _obscure ? Icons.visibility : Icons.visibility_off),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                    validator: (v) => (v == null || v.isEmpty)
                        ? 'Password is required'
                        : null,
                    onFieldSubmitted: (_) {
                      if (_twoFactorRequired) {
                        FocusScope.of(context)
                            .requestFocus(_twoFactorFocusNode);
                      } else if (!_loading) {
                        _submit();
                      }
                    },
                  ),
                  if (_twoFactorRequired) ...[
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _twoFactorController,
                      focusNode: _twoFactorFocusNode,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.oneTimeCode],
                      decoration: const InputDecoration(
                        labelText: 'Two-factor code',
                        helperText:
                            'Enter the 6-digit code from your authenticator app.',
                        counterText: '',
                      ),
                      maxLength: 6,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (v) {
                        if (!_twoFactorRequired) return null;
                        if (v == null || v.trim().length != 6) {
                          return 'Enter the 6-digit code';
                        }
                        return null;
                      },
                      onFieldSubmitted: (_) {
                        if (!_loading) _submit();
                      },
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Checkbox(
                        value: _rememberMe,
                        onChanged: (v) => _toggleRememberMe(v ?? false),
                      ),
                      const Text('Remember me'),
                      const Spacer(),
                      TextButton(
                        onPressed: _loading
                            ? null
                            : () => Navigator.pushNamed(
                                context, '/auth/forgot-password'),
                        child: const Text('Forgot password?'),
                      )
                    ],
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 8),
                    Text(_error!, style: const TextStyle(color: Colors.red)),
                  ],
                  if (_failedAttempts >= 3) ...[
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: _loading ? null : _contactSupport,
                      icon: const Icon(Icons.support_agent),
                      label: const Text('Need help? Contact support'),
                    ),
                  ],
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _loading ? null : _submit,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: _loading
                          ? const SizedBox(
                              key: ValueKey('spinner'),
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text(
                              'Log In',
                              key: ValueKey('text'),
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: _loading
                        ? null
                        : () => Navigator.pushNamed(context, '/auth/register'),
                    child: const Text('New to Mindapax? Create an account'),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
