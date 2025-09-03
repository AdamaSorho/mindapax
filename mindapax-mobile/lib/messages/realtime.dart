import 'dart:io' show Platform;
import 'dart:convert';
import 'package:stomp_dart_client/stomp.dart';
import 'package:stomp_dart_client/stomp_config.dart';
import 'package:stomp_dart_client/stomp_frame.dart';
import '../env.dart';

typedef OnMessage = void Function(Map<String, dynamic> json);
typedef OnStatus = void Function(bool connected);

class MessageRealtime {
  StompClient? _client;
  String? _subscriptionId;

  static String _wsUrl() {
    // Derive ws URL from apiBaseUrl host
    // apiBaseUrl example: http://localhost:8080/api/v1
    final cleaned = apiBaseUrl.replaceAll(RegExp(r'/+$'), '');
    final uri = Uri.parse(cleaned);
    final host = (uri.host == 'localhost' && Platform.isAndroid) ? '10.0.2.2' : uri.host;
    final scheme = uri.scheme == 'https' ? 'wss' : 'ws';
    final port = (uri.hasPort) ? ':${uri.port}' : '';
    // Connect directly to SockJS websocket transport
    return '$scheme://$host$port/ws/websocket';
  }

  void connect({
    required int conversationId,
    String? token,
    required OnMessage onMessage,
    OnStatus? onStatus,
  }) {
    final url = _wsUrl();
    _client = StompClient(
      config: StompConfig(
        url: url,
        onConnect: (frame) {
          onStatus?.call(true);
          _subscriptionId = _client?.subscribe(
            destination: '/topic/messages/$conversationId',
            headers: token != null ? {'Authorization': 'Bearer $token'} : {},
            callback: (StompFrame f) {
              try {
                final body = f.body;
                if (body != null) {
                  onMessage.call(Map<String, dynamic>.from(
                      // ignore: avoid_dynamic_calls
                      (jsonDecode(body) as dynamic)));
                }
              } catch (_) {}
            },
          );
        },
        onDisconnect: (f) => onStatus?.call(false),
        onWebSocketError: (e) => onStatus?.call(false),
        stompConnectHeaders: token != null ? {'Authorization': 'Bearer $token'} : {},
        webSocketConnectHeaders: token != null ? {'Authorization': 'Bearer $token'} : {},
        reconnectDelay: const Duration(milliseconds: 5000),
      ),
    );
    _client?.activate();
  }

  bool get connected => _client?.connected ?? false;

  void send({required Map<String, dynamic> body, String? token}) {
    if (!connected) return;
    _client?.send(
      destination: '/app/chat',
      body: jsonEncode(body),
      headers: token != null ? {'Authorization': 'Bearer $token'} : {},
    );
  }

  void disconnect() {
    _client?.deactivate();
    _client = null;
    _subscriptionId = null;
  }
}
