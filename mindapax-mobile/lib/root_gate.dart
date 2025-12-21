import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/material.dart';

import 'auth/auth_service.dart';
import 'auth/authorized_client.dart';
import 'auth/biometric_auth.dart';
import 'auth/biometric_prefs.dart';
import 'auth/token_storage.dart';
import 'env.dart';
import 'main.dart' show HomePage; // reuse existing HomePage
import 'member/onboarding_prefs.dart';
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
    final authed = await _auth.ensureAuthenticated();
    if (!mounted) return;
    if (authed) {
      final biometricsEnabled = await BiometricPrefs.isEnabled();
      if (biometricsEnabled) {
        final supported = await BiometricAuth.isSupported();
        final available = supported && await BiometricAuth.canCheckBiometrics();
        bool verified = false;
        if (supported && available) {
          verified = await BiometricAuth.authenticate(
            reason: 'Authenticate to unlock Mindapax',
          );
        }
        if (!verified) {
          await _auth.logout();
          if (!mounted) return;
          setState(() => _deciding = false);
          return;
        }
      }

      final target = await _resolveLandingRoute();
      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, target);
      });
    } else {
      setState(() => _deciding = false);
    }
  }

  Future<String> _resolveLandingRoute() async {
    final needsOnboarding = await _shouldRunOnboarding();
    if (needsOnboarding) {
      return '/member/onboarding';
    }
    return '/member/dashboard';
  }

  Future<bool> _shouldRunOnboarding() async {
    if (await OnboardingPrefs.isCompleted()) return false;
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
        return !completed;
      }
    } catch (_) {}
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
    if (_deciding) return const BrandedSplash();
    return const HomePage();
  }
}
