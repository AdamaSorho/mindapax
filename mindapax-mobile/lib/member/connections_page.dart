import 'package:flutter/material.dart';
import '../auth/token_storage.dart';
import '../auth/jwt.dart';
import '../dev/role_override.dart';
import '../professional/professional_api.dart';
import '../professional/models.dart' show specializationLabels;
import '../connections/models.dart';
import '../connections/connections_api.dart';
import 'member_scaffold.dart';

class ConnectionsPage extends StatefulWidget {
  final ConnectionsApi? api;
  const ConnectionsPage({super.key, this.api});

  @override
  State<ConnectionsPage> createState() => _ConnectionsPageState();
}

class _ConnectionsPageState extends State<ConnectionsPage> {
  late final ConnectionsApi _api = widget.api ?? ConnectionsApi();
  final _proApi = ProfessionalApi();
  final _storage = TokenStorage();

  bool _loading = false;
  String? _error;
  bool _isProfessional = false;
  int? _ownerId; // professionalId or userId based on role

  List<ConnectionItem> _all = const [];
  String _activeTab = 'pending';

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
      // Determine roles
      List<String> roles = [];
      final token = await _storage.getAccessToken();
      final payload = token != null ? decodeJwtPayload(token) : null;
      final raw = payload?['roles'];
      if (raw is List) {
        roles = raw.map((e) => e.toString()).toList();
      } else if (raw is String) {
        roles = raw.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      }
      // Debug role override support
      if (RoleOverride.roles != null) roles = RoleOverride.roles!;
      roles = roles.map((r) => r.startsWith('ROLE_') ? r : 'ROLE_${r.toUpperCase()}').toList();
      _isProfessional = roles.contains('ROLE_PROFESSIONAL');

      if (_isProfessional) {
        final me = await _proApi.getMe();
        _ownerId = me.id;
        _all = await _api.getConnectionsForProfessional(_ownerId!);
      } else {
        final userId = (payload?['id'] as num?)?.toInt();
        _ownerId = userId;
        if (_ownerId != null) {
          _all = await _api.getConnectionsForUser(_ownerId!);
        }
      }
    } catch (e) {
      _error = 'Failed to load connections: $e';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<ConnectionItem> get _filtered {
    switch (_activeTab) {
      case 'accepted':
        return _all.where((c) => c.status == ConnectionStatus.ACCEPTED).toList();
      case 'transferred':
        return _all.where((c) => c.status == ConnectionStatus.TRANSFERRED).toList();
      case 'escalated':
        return _all.where((c) => c.status == ConnectionStatus.ESCALATED).toList();
      case 'all':
        return _all;
      default:
        return _all.where((c) => c.status == ConnectionStatus.PENDING).toList();
    }
  }

  Future<void> _refresh() async {
    await _init();
  }

  Future<void> _updateStatus(ConnectionItem c, ConnectionStatus s) async {
    try {
      setState(() => _loading = true);
      final updated = await _api.updateStatus(c.id, s);
      final idx = _all.indexWhere((x) => x.id == c.id);
      if (idx >= 0) {
        _all = List.of(_all)..[idx] = updated;
      }
      setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MemberScaffold(
      currentRoute: '/member/connections',
      title: 'Connections',
      child: Column(
        children: [
          if (_loading) const LinearProgressIndicator(minHeight: 2),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(_error!, style: const TextStyle(color: Colors.red)),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final tab in const ['pending', 'accepted', 'transferred', 'escalated', 'all']) ...[
                    ChoiceChip(
                      label: Text(tab[0].toUpperCase() + tab.substring(1)),
                      selected: _activeTab == tab,
                      onSelected: (v) => setState(() => _activeTab = tab),
                    ),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: _filtered.isEmpty
                  ? ListView(
                      children: const [
                        Padding(
                          padding: EdgeInsets.only(top: 80),
                          child: Center(child: Text('No connections')),
                        )
                      ],
                    )
                  : ListView.builder(
                      itemCount: _filtered.length,
                      padding: const EdgeInsets.all(12),
                      itemBuilder: (_, i) => _ConnectionCard(
                        item: _filtered[i],
                        isProfessional: _isProfessional,
                        onAccept: () => _updateStatus(_filtered[i], ConnectionStatus.ACCEPTED),
                        onTransfer: () => _updateStatus(_filtered[i], ConnectionStatus.TRANSFERRED),
                        onEscalate: () => _updateStatus(_filtered[i], ConnectionStatus.ESCALATED),
                      ),
                    ),
            ),
          )
        ],
      ),
    );
  }
}

class _ConnectionCard extends StatelessWidget {
  final ConnectionItem item;
  final bool isProfessional;
  final VoidCallback? onAccept;
  final VoidCallback? onTransfer;
  final VoidCallback? onEscalate;

  const _ConnectionCard({
    required this.item,
    required this.isProfessional,
    this.onAccept,
    this.onTransfer,
    this.onEscalate,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: item.userAvatar != null && item.userAvatar!.isNotEmpty
                      ? NetworkImage(item.userAvatar!)
                      : null,
                  child: (item.userAvatar == null || item.userAvatar!.isEmpty)
                      ? Text(item.userName.isNotEmpty ? item.userName[0].toUpperCase() : 'U')
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.userName, style: const TextStyle(fontWeight: FontWeight.w600)),
                      if (item.requestType != null)
                        Text(item.requestType!, style: const TextStyle(color: Colors.black54)),
                      if (item.professionalSpecialization != null)
                        Text(
                          specializationLabels.entries
                                  .firstWhere(
                                      (e) => e.key.toString().split('.').last == item.professionalSpecialization,
                                      orElse: () => MapEntry(specializationLabels.keys.first, ''))
                                  .value ??
                              (item.professionalSpecialization ?? ''),
                          style: const TextStyle(color: Colors.black45),
                        ),
                    ],
                  ),
                ),
                _statusChip(item.status),
              ],
            ),
            const SizedBox(height: 8),
            if ((item.message ?? '').isNotEmpty)
              Text(item.message!, style: const TextStyle(color: Colors.black87)),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.event, size: 16, color: Colors.black45),
                const SizedBox(width: 6),
                Text('${item.createdAt.toLocal()}'.split('.').first,
                    style: const TextStyle(color: Colors.black54)),
                const Spacer(),
                if (item.urgency != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _urgencyColor(item.urgency!),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text('${item.urgency}',
                        style: const TextStyle(color: Colors.white, fontSize: 12)),
                  ),
              ],
            ),
            if (isProfessional && item.status == ConnectionStatus.PENDING) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  FilledButton(onPressed: onAccept, child: const Text('Accept')),
                  const SizedBox(width: 8),
                  OutlinedButton(onPressed: onTransfer, child: const Text('Transfer')),
                  const SizedBox(width: 8),
                  OutlinedButton(onPressed: onEscalate, child: const Text('Escalate')),
                ],
              )
            ]
          ],
        ),
      ),
    );
  }

  static Widget _statusChip(ConnectionStatus s) {
    Color bg;
    Color fg;
    String label = connectionStatusLabel(s);
    switch (s) {
      case ConnectionStatus.PENDING:
        bg = Colors.blue.shade100;
        fg = Colors.blue.shade800;
        break;
      case ConnectionStatus.ACCEPTED:
        bg = Colors.green.shade100;
        fg = Colors.green.shade800;
        break;
      case ConnectionStatus.TRANSFERRED:
        bg = Colors.purple.shade100;
        fg = Colors.purple.shade800;
        break;
      case ConnectionStatus.ESCALATED:
        bg = Colors.orange.shade100;
        fg = Colors.orange.shade800;
        break;
      case ConnectionStatus.BLOCKED:
        bg = Colors.grey.shade300;
        fg = Colors.grey.shade700;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16)),
      child: Text(label, style: TextStyle(color: fg, fontWeight: FontWeight.w600)),
    );
  }

  static Color _urgencyColor(String u) {
    switch (u.toUpperCase()) {
      case 'HIGH':
        return Colors.red.shade400;
      case 'MEDIUM':
        return Colors.amber.shade600;
      case 'LOW':
        return Colors.green.shade600;
      default:
        return Colors.grey.shade500;
    }
  }
}

