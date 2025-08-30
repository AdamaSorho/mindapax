import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  static const _kAccessToken = 'accessToken';
  static const _kRefreshToken = 'refreshToken';
  static const _kExpiresAt = 'expiresAt'; // millis since epoch

  final FlutterSecureStorage _storage;
  TokenStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    required int expiresInSeconds,
  }) async {
    final expiresAtMillis = DateTime.now()
        .add(Duration(seconds: expiresInSeconds))
        .millisecondsSinceEpoch
        .toString();
    await _storage.write(key: _kAccessToken, value: accessToken);
    await _storage.write(key: _kRefreshToken, value: refreshToken);
    await _storage.write(key: _kExpiresAt, value: expiresAtMillis);
  }

  Future<String?> getAccessToken() => _storage.read(key: _kAccessToken);
  Future<String?> getRefreshToken() => _storage.read(key: _kRefreshToken);

  Future<int?> getExpiresAtMillis() async {
    final v = await _storage.read(key: _kExpiresAt);
    if (v == null) return null;
    return int.tryParse(v);
  }

  Future<bool> hasValidAccessToken() async {
    final token = await getAccessToken();
    final expiresAt = await getExpiresAtMillis();
    if (token == null || expiresAt == null) return false;
    return DateTime.now().millisecondsSinceEpoch < expiresAt;
  }

  Future<void> clear() async {
    await _storage.delete(key: _kAccessToken);
    await _storage.delete(key: _kRefreshToken);
    await _storage.delete(key: _kExpiresAt);
  }
}

