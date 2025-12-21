import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'auth_service.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _agreeTerms = false;
  bool _obscure1 = true;
  bool _obscure2 = true;
  bool _loading = false;
  String? _error;
  bool _termsError = false;
  double _passwordStrength = 0;

  final _auth = AuthService();

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
      _termsError = false;
    });
    if (!_agreeTerms) {
      setState(() {
        _termsError = true;
        _loading = false;
      });
      return;
    }
    try {
      await _auth.register(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        confirmPassword: _confirmPasswordController.text,
        agreeTerms: _agreeTerms,
      );
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/auth/login',
        (route) => false,
        arguments: const {'registered': true},
      );
    } catch (e) {
      final friendly = _friendlyRegisterError(e);
      setState(() => _error = friendly);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _friendlyRegisterError(Object error) {
    final raw = error.toString().replaceFirst('Exception: ', '');
    final lower = raw.toLowerCase();
    if (lower.contains('email') &&
        (lower.contains('exists') || lower.contains('used'))) {
      return 'An account with that email already exists. Try logging in instead.';
    }
    if (lower.contains('network') ||
        lower.contains('timeout') ||
        lower.contains('socket') ||
        lower.contains('failed host lookup') ||
        lower.contains('connection refused')) {
      return 'We couldn\'t reach the server. Check your internet connection and try again.';
    }
    if (lower.contains('password')) {
      return 'That password didn\'t meet our requirements. Please try a stronger password.';
    }
    return 'We couldn\'t create your account right now. Please try again in a moment.';
  }

  void _updatePasswordStrength(String value) {
    final score = _calculatePasswordStrength(value);
    setState(() => _passwordStrength = score);
  }

  double _calculatePasswordStrength(String value) {
    if (value.isEmpty) return 0;
    double strength = 0;
    if (value.length >= 8) strength += 0.25;
    if (RegExp(r'[A-Z]').hasMatch(value)) strength += 0.25;
    if (RegExp(r'[0-9]').hasMatch(value)) strength += 0.25;
    if (RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(value)) strength += 0.25;
    return strength.clamp(0, 1);
  }

  String _passwordStrengthLabel(double value) {
    if (value <= 0.25) return 'Too weak';
    if (value <= 0.5) return 'Weak';
    if (value <= 0.75) return 'Good';
    return 'Strong';
  }

  Color _passwordStrengthColor(double value) {
    if (value <= 0.25) return Colors.redAccent;
    if (value <= 0.5) return Colors.orangeAccent;
    if (value <= 0.75) return Colors.amber;
    return Colors.green;
  }

  Future<void> _openLegalUrl(String path) async {
    final uri = Uri.parse('https://mindapax.com/$path');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _firstNameController,
                        decoration: const InputDecoration(labelText: 'First name'),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'First name is required'
                            : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _lastNameController,
                        decoration: const InputDecoration(labelText: 'Last name'),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Last name is required'
                            : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
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
                  obscureText: _obscure1,
                  onChanged: _updatePasswordStrength,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    helperText:
                        'Use at least 8 characters with a mix of uppercase, numbers, and symbols.',
                    suffixIcon: IconButton(
                      icon: Icon(_obscure1 ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setState(() => _obscure1 = !_obscure1),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Password is required';
                    if (v.length < 8) return 'Minimum 8 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                if (_passwordController.text.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.all(Radius.circular(4)),
                        child: LinearProgressIndicator(
                          value: _passwordStrength,
                          minHeight: 6,
                          backgroundColor: Colors.grey.shade200,
                          color: _passwordStrengthColor(_passwordStrength),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _passwordStrengthLabel(_passwordStrength),
                        style: TextStyle(
                          color: _passwordStrengthColor(_passwordStrength),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscure2,
                  decoration: InputDecoration(
                    labelText: 'Confirm password',
                    suffixIcon: IconButton(
                      icon: Icon(_obscure2 ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setState(() => _obscure2 = !_obscure2),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Confirm your password';
                    if (v != _passwordController.text) return 'Passwords do not match';
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Checkbox(
                      value: _agreeTerms,
                      onChanged: (v) => setState(() {
                        _agreeTerms = v ?? false;
                        if (_agreeTerms) _termsError = false;
                      }),
                    ),
                    Expanded(
                      child: Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          const Text('I agree to the '),
                          TextButton(
                            onPressed: () => _openLegalUrl('terms'),
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text('Terms of Service'),
                          ),
                          const Text(' and '),
                          TextButton(
                            onPressed: () => _openLegalUrl('privacy'),
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text('Privacy Policy'),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
                if (_termsError)
                  const Padding(
                    padding: EdgeInsets.only(left: 48),
                    child: Text(
                      'You must agree to continue.',
                      style: TextStyle(color: Colors.red),
                    ),
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
                      : const Text('Create account'),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: _loading ? null : () => Navigator.pop(context),
                  child: const Text('Back'),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
