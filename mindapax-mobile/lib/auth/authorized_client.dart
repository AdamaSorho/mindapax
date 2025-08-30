import 'package:http/http.dart' as http;
import 'token_storage.dart';

class AuthorizedHttpClient extends http.BaseClient {
  final http.Client _inner;
  final TokenStorage _storage;

  AuthorizedHttpClient(this._storage, [http.Client? inner])
      : _inner = inner ?? http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final token = await _storage.getAccessToken();
    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    return _inner.send(request);
  }
}

