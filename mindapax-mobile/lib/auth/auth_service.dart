import 'dart:async';
import 'auth_api.dart';

class AuthService {
  final AuthApi _api;
  AuthService({AuthApi? api}) : _api = api ?? AuthApi();

  Future<void> login({required String email, required String password}) async {
    if (email.isEmpty || password.isEmpty) {
      throw Exception('Email and password are required');
    }
    await _api.login(email: email, password: password);
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
}
