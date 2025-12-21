import 'dart:async';

import 'package:flutter/material.dart';

import 'member_scaffold.dart';
import 'micro_sessions_api.dart';
import 'micro_sessions_data.dart';
import 'self_guided_store.dart';

class MicroSessionsPage extends StatefulWidget {
  const MicroSessionsPage({super.key});

  @override
  State<MicroSessionsPage> createState() => _MicroSessionsPageState();
}

class _MicroSessionsPageState extends State<MicroSessionsPage> {
  String? _outcomeFilter;
  bool _loading = true;
  String? _error;
  List<MicroSession> _sessions = microSessions;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final sessions = await MicroSessionsApi.list();
      if (!mounted) return;
      setState(() {
        _sessions = sessions.isEmpty ? microSessions : sessions;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _sessions = microSessions;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _outcomeFilter == null
        ? _sessions
        : _sessions
            .where((s) => s.outcomes.contains(_outcomeFilter))
            .toList(growable: false);
    final outcomes = _sessions
        .expand((s) => s.outcomes)
        .toSet()
        .toList()
      ..sort();
    return MemberScaffold(
      title: 'Micro sessions',
      currentRoute: '/member/micro-sessions',
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          if (_loading) const LinearProgressIndicator(minHeight: 2),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(_error!,
                  style: const TextStyle(color: Colors.red)),
            ),
          Text('Quick wins for today',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          const Text(
              'Pick a short session tied to your outcomes. These are built to be doable in low-energy moments.'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: const Text('All outcomes'),
                selected: _outcomeFilter == null,
                onSelected: (_) => setState(() => _outcomeFilter = null),
              ),
              for (final o in outcomes.isEmpty ? outcomeCategories : outcomes)
                ChoiceChip(
                  label: Text(o),
                  selected: _outcomeFilter == o,
                  onSelected: (_) => setState(() => _outcomeFilter = o),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (filtered.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 24),
              child: Center(child: Text('No sessions for this outcome yet.')),
            )
          else
            for (final session in filtered) _sessionCard(session),
        ],
      ),
    );
  }

  Widget _sessionCard(MicroSession session) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(session.title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 16)),
                ),
                _domainChip(session.domain),
              ],
            ),
            const SizedBox(height: 4),
            Text(session.description,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.black87)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                for (final o in session.outcomes) _miniChip(o),
                _miniChip('${session.minutes} min'),
              ],
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) =>
                        MicroSessionDetailPage(
                          session: session,
                          onCompleted: _load,
                        ))),
                icon: const Icon(Icons.play_arrow),
                label: const Text('Start'),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _miniChip(String label) {
    return Chip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      visualDensity: VisualDensity.compact,
      side: BorderSide(color: Colors.indigo.withOpacity(0.2)),
      backgroundColor: Colors.indigo.withOpacity(0.06),
    );
  }

  Widget _domainChip(String domain) {
    Color color;
    switch (domain.toUpperCase()) {
      case 'MIND':
        color = Colors.indigo;
        break;
      case 'MONEY':
        color = Colors.blue;
        break;
      case 'BODY':
        color = Colors.green;
        break;
      case 'RELATIONSHIPS':
        color = Colors.teal;
        break;
      case 'GROWTH':
        color = Colors.orange;
        break;
      case 'INTEGRATED':
        color = Colors.brown;
        break;
      default:
        color = Colors.grey;
    }
    return Chip(
      label: Text(_domainLabel(domain)),
      backgroundColor: color.withOpacity(0.1),
      side: BorderSide(color: color.withOpacity(0.4)),
      visualDensity: VisualDensity.compact,
    );
  }

  String _domainLabel(String domain) {
    switch (domain.toUpperCase()) {
      case 'MIND':
        return 'Mental';
      case 'MONEY':
        return 'Financial';
      case 'BODY':
        return 'Physical';
      case 'RELATIONSHIPS':
        return 'Relational';
      case 'GROWTH':
        return 'Growth';
      case 'INTEGRATED':
        return 'Integrated';
      case 'CUSTOM':
      default:
        return 'Custom';
    }
  }
}

class MicroSessionDetailPage extends StatefulWidget {
  final MicroSession session;
  final VoidCallback? onCompleted;
  const MicroSessionDetailPage(
      {super.key, required this.session, this.onCompleted});

  @override
  State<MicroSessionDetailPage> createState() => _MicroSessionDetailPageState();
}

class _MicroSessionDetailPageState extends State<MicroSessionDetailPage> {
  Timer? _timer;
  late int _remaining;
  bool _running = false;
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    _remaining = widget.session.minutes * 60;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _toggleTimer() {
    if (_running) {
      _timer?.cancel();
      setState(() => _running = false);
      return;
    }
    setState(() => _running = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_remaining <= 1) {
        timer.cancel();
        setState(() {
          _remaining = 0;
          _running = false;
          _completed = true;
        });
        return;
      }
      setState(() => _remaining -= 1);
    });
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _remaining = widget.session.minutes * 60;
      _running = false;
      _completed = false;
    });
  }

  void _markDone() {
    if (_completed) return;
    _completeAndReward();
  }

  Future<void> _completeAndReward() async {
    setState(() => _completed = true);
    try {
      final result = await MicroSessionsApi.complete(widget.session.id);
      if (result.xpAwarded != null) {
        await SelfGuidedStore.loadGoals();
      }
      if (!mounted) return;
      final xpText = result.xpAwarded != null
          ? ' +${result.xpAwarded} XP'
          : '';
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Session completed.$xpText')));
      widget.onCompleted?.call();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Saved locally. Sync failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = 1 - (_remaining / (widget.session.minutes * 60));
    return Scaffold(
      appBar: AppBar(title: Text(widget.session.title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(widget.session.description,
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            minHeight: 6,
            backgroundColor: Colors.indigo.shade50,
          ),
          const SizedBox(height: 8),
          Text(_formatTime(_remaining),
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              FilledButton.icon(
                onPressed: _toggleTimer,
                icon: Icon(_running ? Icons.pause : Icons.play_arrow),
                label: Text(_running ? 'Pause' : 'Start'),
              ),
              OutlinedButton.icon(
                onPressed: _resetTimer,
                icon: const Icon(Icons.refresh),
                label: const Text('Reset'),
              ),
              TextButton.icon(
                onPressed: _completed ? null : _markDone,
                icon: const Icon(Icons.check),
                label: const Text('Mark done'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text('Steps',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          for (var i = 0; i < widget.session.steps.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${i + 1}. ',
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  Expanded(child: Text(widget.session.steps[i])),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _formatTime(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$secs';
  }
}
