import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:stomp_dart_client/stomp.dart';
import 'package:stomp_dart_client/stomp_config.dart';
import 'package:stomp_dart_client/stomp_frame.dart';

import '../auth/jwt.dart';
import '../auth/token_storage.dart';
import '../env.dart';

class NotificationEvent {
  final String type;
  final String title;
  final String message;
  final Map<String, dynamic> data;

  NotificationEvent({
    required this.type,
    required this.title,
    required this.message,
    required this.data,
  });

  factory NotificationEvent.fromJson(Map<String, dynamic> json) {
    return NotificationEvent(
      type: json['type']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      data: (json['data'] as Map<String, dynamic>? ?? const {}),
    );
  }
}

class NotificationHub {
  NotificationHub._();

  static final NotificationHub instance = NotificationHub._();

  final _storage = TokenStorage();
  final _controller = StreamController<NotificationEvent>.broadcast();
  StompClient? _client;
  bool _connecting = false;
  int? _userId;

  Stream<NotificationEvent> get stream => _controller.stream;

  Future<void> ensureConnected() async {
    if (_client?.connected == true || _connecting) return;
    _connecting = true;
    final token = await _storage.getAccessToken();
    if (token == null) {
      _connecting = false;
      return;
    }
    final payload = decodeJwtPayload(token);
    final id = (payload?['id'] as num?)?.toInt();
    if (id == null) {
      _connecting = false;
      return;
    }
    _userId = id;
    final url = _wsUrl();
    _client = StompClient(
      config: StompConfig(
        url: url,
        stompConnectHeaders: {'Authorization': 'Bearer $token'},
        webSocketConnectHeaders: {'Authorization': 'Bearer $token'},
        onConnect: (_) {
          _subscribeToUserTopic(id);
        },
        onDisconnect: (_) {
          _connecting = false;
        },
        onWebSocketError: (_) {
          _connecting = false;
        },
        reconnectDelay: const Duration(milliseconds: 4000),
      ),
    );
    _client?.activate();
  }

  void disconnect() {
    _client?.deactivate();
    _client = null;
    _connecting = false;
  }

  void _subscribeToUserTopic(int userId) {
    _client?.subscribe(
      destination: '/topic/users/$userId',
      callback: (StompFrame frame) {
        final body = frame.body;
        if (body == null) return;
        try {
          final decoded = jsonDecode(body);
          if (decoded is Map<String, dynamic>) {
            _controller.add(NotificationEvent.fromJson(decoded));
          }
        } catch (_) {}
      },
    );
  }

  String _wsUrl() {
    final cleaned = apiBaseUrl.replaceAll(RegExp(r'/+$'), '');
    final uri = Uri.parse(cleaned);
    final host =
        (uri.host == 'localhost' && Platform.isAndroid) ? '10.0.2.2' : uri.host;
    final scheme = uri.scheme == 'https' ? 'wss' : 'ws';
    final port = uri.hasPort ? ':${uri.port}' : '';
    return '$scheme://$host$port/ws/websocket';
  }
}
