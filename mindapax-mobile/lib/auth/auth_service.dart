import 'dart:async';
import 'auth_api.dart';
import 'token_storage.dart';
import 'biometric_prefs.dart';
import '../notifications/notification_hub.dart';

class AuthService {
  final AuthApi _api;
  final TokenStorage _storage;
  AuthService({AuthApi? api, TokenStorage? storage})
      : _api = api ?? AuthApi(),
        _storage = storage ?? TokenStorage();

  Future<void> login({
    required String email,
    required String password,
    String? twoFactorCode,
    bool rememberMe = false,
  }) async {
    if (email.isEmpty || password.isEmpty) {
      throw Exception('Email and password are required');
    }
    final tokens = await _api.login(
      email: email,
      password: password,
      twoFactorCode: twoFactorCode,
      rememberMe: rememberMe,
    );
    await _storage.saveTokens(
      accessToken: tokens.accessToken,
      refreshToken: tokens.refreshToken,
      expiresInSeconds: tokens.expiresIn,
      rememberMe: rememberMe,
    );
  }

  Future<void> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String confirmPassword,
    required bool agreeTerms,
  }) async {
    if (!agreeTerms) throw Exception('You must agree to the terms');
    if (password != confirmPassword) {
      throw Exception('Passwords do not match');
    }
    await _api.registerUser(
      firstName: firstName,
      lastName: lastName,
      email: email,
      password: password,
      agreeTerms: agreeTerms,
    );
  }

  Future<void> forgotPassword({required String email}) async {
    if (email.isEmpty) throw Exception('Email is required');
    await _api.forgotPassword(email);
  }

  Future<void> logout() async {
    final refresh = await _storage.getRefreshToken();
    if (refresh != null && refresh.isNotEmpty) {
      try {
        await _api.logout(refreshToken: refresh);
      } catch (_) {
        // ignore network errors on logout
      }
    }
    await _storage.clear();
    await BiometricPrefs.setEnabled(false);
    NotificationHub.instance.disconnect();
  }

  Future<bool> isAuthenticated() => _storage.hasValidAccessToken();

  Future<void> refresh() async {
    final refresh = await _storage.getRefreshToken();
    if (refresh == null || refresh.isEmpty) throw Exception('No refresh token');
    final rememberMe = await _storage.isRemembered();
    final tokens = await _api.refreshTokens(refreshToken: refresh);
    await _storage.saveTokens(
      accessToken: tokens.accessToken,
      refreshToken: tokens.refreshToken,
      expiresInSeconds: tokens.expiresIn,
      rememberMe: rememberMe,
    );
  }

  Future<bool> ensureAuthenticated() async {
    if (await _storage.hasValidAccessToken()) {
      return true;
    }
    final rememberMe = await _storage.isRemembered();
    if (!rememberMe) {
      await _storage.clear();
      return false;
    }
    final refresh = await _storage.getRefreshToken();
    if (refresh == null || refresh.isEmpty) {
      await _storage.clear();
      return false;
    }
    try {
      final tokens = await _api.refreshTokens(refreshToken: refresh);
      await _storage.saveTokens(
        accessToken: tokens.accessToken,
        refreshToken: tokens.refreshToken,
        expiresInSeconds: tokens.expiresIn,
        rememberMe: true,
      );
      return true;
    } catch (_) {
      await _storage.clear();
      return false;
    }
  }
}
