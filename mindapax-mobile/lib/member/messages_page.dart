import 'package:flutter/material.dart';
import '../auth/token_storage.dart';
import '../auth/jwt.dart';
import '../messages/messages_api.dart';
import '../messages/models.dart';
import 'member_scaffold.dart';
import 'chat_thread_page.dart';

class MessagesPage extends StatefulWidget {
  final MessagesApi? api;
  const MessagesPage({super.key, this.api});

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  late final MessagesApi _api = widget.api ?? MessagesApi();
  final _storage = TokenStorage();

  bool _loading = false;
  String? _error;
  int? _ownerId; // userId for clients, professional.user.id for professionals
  List<ConversationSummary> _items = const [];

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final token = await _storage.getAccessToken();
      final payload = token != null ? decodeJwtPayload(token) : null;
      final userId = (payload?['id'] as num?)?.toInt();
      List<String> roles = [];
      final raw = payload?['roles'];
      if (raw is List) {
        roles = raw.map((e) => e.toString()).toList();
      } else if (raw is String) {
        roles = raw
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
      }
      roles = roles
          .map((r) => r.startsWith('ROLE_') ? r : 'ROLE_${r.toUpperCase()}')
          .toList();

      if (roles.contains('ROLE_PROFESSIONAL')) {
        // Conversations API expects the user id; for professionals, we still pass their user.id
        // ProfessionalApi.getMe returns Professional; its user has id as well. For simplicity, use JWT user id.
        _ownerId = userId;
      } else {
        _ownerId = userId;
      }

      if (_ownerId != null) {
        final page = await _api.getConversations(_ownerId!, page: 0, size: 50);
        setState(() => _items = page.content);
      }
    } catch (e) {
      setState(() => _error = 'Failed to load conversations: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MemberScaffold(
      currentRoute: '/member/messages',
      title: 'Messages',
      child: Column(
        children: [
          if (_loading) const LinearProgressIndicator(minHeight: 2),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(_error!, style: const TextStyle(color: Colors.red)),
            ),
          Expanded(
            child: _items.isEmpty
                ? const Center(child: Text('No conversations'))
                : ListView.builder(
                    itemCount: _items.length,
                    itemBuilder: (_, i) => _ConversationTile(item: _items[i]),
                  ),
          )
        ],
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final ConversationSummary item;
  const _ConversationTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage:
            (item.otherAvatar != null && item.otherAvatar!.isNotEmpty)
                ? NetworkImage(item.otherAvatar!)
                : null,
        child: (item.otherAvatar == null || item.otherAvatar!.isEmpty)
            ? Text(item.otherName.isNotEmpty
                ? item.otherName[0].toUpperCase()
                : 'C')
            : null,
      ),
      title: Text(item.otherName),
      subtitle: Text(item.lastMessage?.content ?? ''),
      trailing: Text(
          item.lastMessage?.timestamp.toLocal().toString().split('.')[0] ?? ''),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                ChatThreadPage(conversationId: item.id, title: item.otherName),
          ),
        );
      },
    );
  }
}
