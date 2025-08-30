import 'dart:async';
import 'auth_api.dart';
import 'token_storage.dart';

class AuthService {
  final AuthApi _api;
  final TokenStorage _storage;
  AuthService({AuthApi? api, TokenStorage? storage})
      : _api = api ?? AuthApi(),
        _storage = storage ?? TokenStorage();

  Future<void> login({required String email, required String password}) async {
    if (email.isEmpty || password.isEmpty) {
      throw Exception('Email and password are required');
    }
    final tokens = await _api.login(email: email, password: password);
    await _storage.saveTokens(
      accessToken: tokens.accessToken,
      refreshToken: tokens.refreshToken,
      expiresInSeconds: tokens.expiresIn,
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
    // Not implemented in backend yet; simulate latency and success
    await Future.delayed(const Duration(milliseconds: 600));
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
  }

  Future<bool> isAuthenticated() => _storage.hasValidAccessToken();

  Future<void> refresh() async {
    final refresh = await _storage.getRefreshToken();
    if (refresh == null || refresh.isEmpty) throw Exception('No refresh token');
    final tokens = await _api.refreshTokens(refreshToken: refresh);
    await _storage.saveTokens(
      accessToken: tokens.accessToken,
      refreshToken: tokens.refreshToken,
      expiresInSeconds: tokens.expiresIn,
    );
  }
}
