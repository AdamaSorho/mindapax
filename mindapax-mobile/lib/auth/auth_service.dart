import 'dart:async';

class AuthService {
  Future<void> login({required String email, required String password}) async {
    await Future.delayed(const Duration(milliseconds: 600));
    if (email.isEmpty || password.isEmpty) {
      throw Exception('Email and password are required');
    }
  }

  Future<void> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String confirmPassword,
    required bool agreeTerms,
  }) async {
    await Future.delayed(const Duration(milliseconds: 800));
    if (!agreeTerms) throw Exception('You must agree to the terms');
    if (password != confirmPassword) {
      throw Exception('Passwords do not match');
    }
  }

  Future<void> forgotPassword({required String email}) async {
    await Future.delayed(const Duration(milliseconds: 600));
    if (email.isEmpty) throw Exception('Email is required');
  }
}

