import 'dart:async';
import 'package:flutter/material.dart';
import '../auth/token_storage.dart';
import '../auth/jwt.dart';
import '../messages/messages_api.dart';
import '../messages/realtime.dart';
import '../messages/models.dart';

class ChatThreadPage extends StatefulWidget {
  final int conversationId;
  final String title;
  final MessagesApi? api;
  const ChatThreadPage({super.key, required this.conversationId, required this.title, this.api});

  @override
  State<ChatThreadPage> createState() => _ChatThreadPageState();
}

class _ChatThreadPageState extends State<ChatThreadPage> {
  late final MessagesApi _api = widget.api ?? MessagesApi();
  final _storage = TokenStorage();
  final _controller = TextEditingController();
  final _scrollCtrl = ScrollController();

  int? _currentUserId;
  List<ChatMessage> _messages = const [];
  bool _loading = false;
  String? _error;
  Timer? _pollTimer;
  final _rt = MessageRealtime();
  String? _token;
  // Pagination state (server returns pages sorted by timestamp)
  static const int _pageSize = 50;
  int _pageDesc = 0; // using sort=timestamp,desc
  bool _hasMore = true;
  bool _loadingMore = false;

  @override
  void initState() {
    super.initState();
    _init();
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _controller.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    final token = await _storage.getAccessToken();
    _token = token;
    final payload = token != null ? decodeJwtPayload(token) : null;
    _currentUserId = (payload?['id'] as num?)?.toInt();
    await _loadInitial();
    // Start realtime; if disconnected, fall back to polling
    _rt.connect(
      conversationId: widget.conversationId,
      token: _token,
      onMessage: (json) {
        try {
          final m = ChatMessage.fromJson(json);
          if (m.conversationId == widget.conversationId) {
            setState(() => _messages = List.of(_messages)..add(m));
            _scrollToBottom();
          }
        } catch (_) {}
      },
      onStatus: (connected) {
        if (connected) {
          _pollTimer?.cancel();
        } else {
          _pollTimer ??= Timer.periodic(const Duration(seconds: 5), (_) => _refreshLatest());
        }
      },
    );
    _pollTimer ??= Timer.periodic(const Duration(seconds: 5), (_) => _refreshLatest());
  }

  Future<void> _loadInitial() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _pageDesc = 0;
      final page = await _api.getMessages(widget.conversationId, page: _pageDesc, size: _pageSize, sort: 'timestamp,desc');
      final itemsAsc = List<ChatMessage>.from(page.content.reversed);
      setState(() {
        _messages = itemsAsc;
        _hasMore = page.totalPages > 1;
      });
      // Scroll to bottom
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    } catch (e) {
      setState(() => _error = 'Failed to load messages: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadOlder() async {
    if (_loadingMore || !_hasMore) return;
    setState(() => _loadingMore = true);
    try {
      // Preserve scroll position relative to bottom
      final prevMax = _scrollCtrl.hasClients ? _scrollCtrl.position.maxScrollExtent : 0.0;
      final prevFromBottom = _scrollCtrl.hasClients
          ? (prevMax - _scrollCtrl.position.pixels)
          : 0.0;
      final nextPage = _pageDesc + 1;
      final page = await _api.getMessages(widget.conversationId, page: nextPage, size: _pageSize, sort: 'timestamp,desc');
      final olderAsc = List<ChatMessage>.from(page.content.reversed);
      if (olderAsc.isEmpty) {
        _hasMore = false;
      } else {
        setState(() {
          _pageDesc = nextPage;
          _messages = [...olderAsc, ..._messages];
          // hasMore becomes false if we reached last page index
          _hasMore = !page.isLast;
        });
        // After frame, restore scroll offset relative to bottom so content doesn't jump
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollCtrl.hasClients) {
            final newMax = _scrollCtrl.position.maxScrollExtent;
            final target = (newMax - prevFromBottom).clamp(
                _scrollCtrl.position.minScrollExtent, _scrollCtrl.position.maxScrollExtent);
            _scrollCtrl.jumpTo(target);
          }
        });
      }
    } catch (e) {
      // ignore, keep existing items
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  Future<void> _refreshLatest() async {
    try {
      final page = await _api.getMessages(widget.conversationId, page: 0, size: _pageSize, sort: 'timestamp,desc');
      final latestAsc = List<ChatMessage>.from(page.content.reversed);
      // Merge new items at the end by id
      final existingIds = _messages.map((m) => m.id).toSet();
      final additions = latestAsc.where((m) => !existingIds.contains(m.id)).toList(growable: false);
      if (additions.isNotEmpty) {
        setState(() => _messages = [..._messages, ...additions]);
        _scrollToBottom();
      }
    } catch (_) {}
  }

  void _onScroll() {
    if (_scrollCtrl.positions.isEmpty) return;
    final pos = _scrollCtrl.position;
    if (pos.pixels <= 48.0) {
      _loadOlder();
    }
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _currentUserId == null) return;
    if (_rt.connected) {
      _rt.send(body: {
        'conversationId': widget.conversationId,
        'senderId': _currentUserId,
        'content': text,
      }, token: _token);
      _controller.clear();
    } else {
      setState(() => _loading = true);
      try {
        await _api.sendMessage(conversationId: widget.conversationId, senderId: _currentUserId!, content: text);
        _controller.clear();
        await _refreshLatest();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to send: $e')));
        }
      } finally {
        if (mounted) setState(() => _loading = false);
      }
    }
  }

  void _scrollToBottom() {
    if (_scrollCtrl.hasClients) {
      _scrollCtrl.jumpTo(_scrollCtrl.position.maxScrollExtent);
    }
  }

  @override
  Widget build(BuildContext context) {
    final me = _currentUserId;
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Column(
        children: [
          if (_loading) const LinearProgressIndicator(minHeight: 2),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(_error!, style: const TextStyle(color: Colors.red)),
            ),
          Expanded(
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.all(12),
              itemCount: _messages.length + (_loadingMore ? 1 : 0),
              itemBuilder: (_, i) {
                if (_loadingMore && i == 0) {
                  return const Padding(
                    padding: EdgeInsets.only(bottom: 8.0),
                    child: Center(
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  );
                }
                final idx = _loadingMore ? i - 1 : i;
                final m = _messages[idx];
                final isMine = me != null && m.senderId == me;
                return Align(
                  alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isMine ? Colors.indigo.shade100 : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(m.content),
                        const SizedBox(height: 4),
                        Text(
                          m.timestamp.toLocal().toString().split('.')[0],
                          style: const TextStyle(fontSize: 11, color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      minLines: 1,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        hintText: 'Type a message...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(onPressed: _send, child: const Text('Send')),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
