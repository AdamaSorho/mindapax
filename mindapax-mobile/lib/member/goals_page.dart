import 'dart:convert';

import 'package:flutter/material.dart';
import '../auth/authorized_client.dart';
import '../auth/token_storage.dart';
import '../env.dart';
import 'member_scaffold.dart';
import 'dart:io' show Platform;

class GoalsPage extends StatefulWidget {
  const GoalsPage({super.key});

  @override
  State<GoalsPage> createState() => _GoalsPageState();
}

class _GoalsPageState extends State<GoalsPage> {
  final _storage = TokenStorage();
  bool _loading = false;
  String? _error;
  List<AssistantGoal> _goals = const [];
  String _filter = 'ALL'; // ALL, SUGGESTED, ACTIVE, COMPLETED, SKIPPED

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final client = AuthorizedHttpClient(_storage);
      final uri = Uri.parse('${_normalizeBaseUrl(apiBaseUrl)}/assistant/goals');
      final res = await client.get(uri);
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final list = (jsonDecode(res.body) as List<dynamic>)
            .map((e) => AssistantGoal.fromJson(e as Map<String, dynamic>))
            .toList(growable: false);
        setState(() => _goals = list);
      } else {
        setState(() => _error = 'Failed to load (${res.statusCode})');
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _updateStatus(AssistantGoal g, String status) async {
    try {
      final client = AuthorizedHttpClient(_storage);
      final base = _normalizeBaseUrl(apiBaseUrl);
      final uri =
          Uri.parse('$base/assistant/goals/${g.id}/status?status=$status');
      final res = await client.post(uri);
      if (res.statusCode >= 200 && res.statusCode < 300) {
        await _fetch();
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Updated')));
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Update failed (${res.statusCode})')));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  String _normalizeBaseUrl(String value) {
    final cleaned = value.replaceAll(RegExp(r'/+$'), '');
    try {
      final u = Uri.parse(cleaned);
      if (u.host == 'localhost' && Platform.isAndroid) {
        return cleaned.replaceFirst('localhost', '10.0.2.2');
      }
    } catch (_) {}
    return cleaned;
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _goals
        .where((g) => _filter == 'ALL' ? true : g.status == _filter)
        .toList(growable: false);
    return MemberScaffold(
      title: 'My Goals',
      currentRoute: '/member/goals',
      child: Column(
        children: [
          if (_loading) const LinearProgressIndicator(minHeight: 2),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(_error!, style: const TextStyle(color: Colors.red)),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: Wrap(
              spacing: 8,
              children: [
                for (final f in const [
                  'ALL',
                  'SUGGESTED',
                  'ACTIVE',
                  'COMPLETED',
                  'SKIPPED'
                ])
                  ChoiceChip(
                    label: Text(f.toLowerCase().substring(0, 1).toUpperCase() +
                        f.toLowerCase().substring(1)),
                    selected: _filter == f,
                    onSelected: (_) => setState(() => _filter = f),
                  ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _fetch,
              child: filtered.isEmpty
                  ? ListView(children: const [
                      Padding(
                        padding: EdgeInsets.only(top: 80),
                        child: Center(child: Text('No goals to show')),
                      )
                    ])
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: filtered.length,
                      itemBuilder: (context, i) => _goalTile(filtered[i]),
                    ),
            ),
          )
        ],
      ),
    );
  }

  Widget _goalTile(AssistantGoal g) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.flag_outlined),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(g.title,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Row(children: [
                    _chip(g.frequency, Colors.indigo),
                    const SizedBox(width: 8),
                    _chip(g.status, _statusColor(g.status)),
                  ]),
                ],
              ),
            ),
            const SizedBox(width: 12),
            _actionsFor(g),
          ],
        ),
      ),
    );
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'ACTIVE':
        return Colors.green;
      case 'COMPLETED':
        return Colors.blueGrey;
      case 'SKIPPED':
        return Colors.orange;
      case 'SUGGESTED':
      default:
        return Colors.grey;
    }
  }

  Widget _chip(String label, Color color) {
    return Chip(
      label: Text(label),
      side: BorderSide(color: color.withOpacity(0.4)),
      backgroundColor: color.withOpacity(0.08),
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _actionsFor(AssistantGoal g) {
    switch (g.status) {
      case 'SUGGESTED':
        return OutlinedButton(
            onPressed: () => _updateStatus(g, 'ACTIVE'),
            child: const Text('Activate'));
      case 'ACTIVE':
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            OutlinedButton(
                onPressed: () => _updateStatus(g, 'COMPLETED'),
                child: const Text('Complete')),
            const SizedBox(width: 8),
            TextButton(
                onPressed: () => _updateStatus(g, 'SKIPPED'),
                child: const Text('Skip')),
          ],
        );
      case 'COMPLETED':
      case 'SKIPPED':
      default:
        return const SizedBox.shrink();
    }
  }
}

class AssistantGoal {
  final int id;
  final String title;
  final String frequency; // DAILY|WEEKLY|MONTHLY
  final String status; // SUGGESTED|ACTIVE|COMPLETED|SKIPPED
  final DateTime? createdAt;

  AssistantGoal(
      {required this.id,
      required this.title,
      required this.frequency,
      required this.status,
      this.createdAt});

  factory AssistantGoal.fromJson(Map<String, dynamic> j) {
    return AssistantGoal(
      id: (j['id'] as num?)?.toInt() ?? 0,
      title: j['title']?.toString() ?? '',
      frequency: j['frequency']?.toString().toUpperCase() ?? 'DAILY',
      status: j['status']?.toString().toUpperCase() ?? 'SUGGESTED',
      createdAt: j['createdAt'] != null
          ? DateTime.tryParse(j['createdAt'].toString())
          : null,
    );
  }
}
