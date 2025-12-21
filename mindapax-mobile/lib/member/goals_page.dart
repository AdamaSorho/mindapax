import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import '../auth/authorized_client.dart';
import '../auth/token_storage.dart';
import '../env.dart';
import 'goal_wizard.dart';
import 'member_scaffold.dart';
import 'self_guided_store.dart';
import 'weekly_plan_page.dart';

class GoalsPage extends StatefulWidget {
  const GoalsPage({super.key});

  @override
  State<GoalsPage> createState() => _GoalsPageState();
}

class _GoalsPageState extends State<GoalsPage> {
  final _storage = TokenStorage();
  bool _loadingRemote = false;
  bool _loadingLocal = false;
  String? _errorRemote;
  String? _errorLocal;
  List<AssistantGoal> _assistantGoals = const [];
  List<SelfGuidedGoal> _localGoals = const [];
  String? _localOutcome;
  String _filter = 'ALL'; // ALL, SUGGESTED, ACTIVE, COMPLETED, SKIPPED

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    await Future.wait([_loadLocal(), _fetchRemote()]);
  }

  Future<void> _loadLocal() async {
    setState(() {
      _loadingLocal = true;
      _errorLocal = null;
    });
    try {
      final goals = await SelfGuidedStore.loadGoals();
      if (mounted) setState(() => _localGoals = goals);
    } catch (e) {
      if (mounted) setState(() => _errorLocal = e.toString());
    } finally {
      if (mounted) setState(() => _loadingLocal = false);
    }
  }

  Future<void> _fetchRemote() async {
    setState(() {
      _loadingRemote = true;
      _errorRemote = null;
    });
    try {
      final client = AuthorizedHttpClient(_storage);
      final uri = Uri.parse('${_normalizeBaseUrl(apiBaseUrl)}/assistant/goals');
      final res = await client.get(uri);
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final list = (jsonDecode(res.body) as List<dynamic>)
            .map((e) => AssistantGoal.fromJson(e as Map<String, dynamic>))
            .toList(growable: false);
        if (mounted) setState(() => _assistantGoals = list);
      } else {
        if (mounted) {
          setState(() => _errorRemote = 'Failed to load (${res.statusCode})');
        }
      }
    } catch (e) {
      if (mounted) setState(() => _errorRemote = e.toString());
    } finally {
      if (mounted) setState(() => _loadingRemote = false);
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
        await _fetchRemote();
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
    final filtered = _assistantGoals
        .where((g) => _filter == 'ALL' ? true : g.status == _filter)
        .toList(growable: false);
    final localFiltered = _localGoals.where((g) {
      if (_localOutcome == null) return true;
      return (g.outcome ?? '') == _localOutcome;
    }).toList(growable: false);
    return MemberScaffold(
      title: 'My Goals',
      currentRoute: '/member/goals',
      child: RefreshIndicator(
        onRefresh: _loadAll,
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            if (_loadingLocal || _loadingRemote)
              const LinearProgressIndicator(minHeight: 2),
            _buildLocalHeader(),
            const SizedBox(height: 8),
            if (_errorLocal != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(_errorLocal!,
                    style: const TextStyle(color: Colors.red)),
              ),
            _outcomeFilterChips(),
            const SizedBox(height: 6),
            if (localFiltered.isEmpty)
              _emptyLocal()
            else
              ...localFiltered.map(_localGoalCard),
            const SizedBox(height: 12),
            const Divider(),
            _assistantHeader(),
            const SizedBox(height: 8),
            if (_errorRemote != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(_errorRemote!,
                    style: const TextStyle(color: Colors.red)),
              ),
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
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
            if (filtered.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 32),
                child: Center(child: Text('No assistant goals to show')),
              )
            else
              ...filtered.map(_goalTile),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildLocalHeader() {
    return Row(
      children: [
        Expanded(
            child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Self-guided plans',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            const Text(
              'Create goals, auto-spread tasks through the week, and keep streaks even with soft skips.',
              style: TextStyle(color: Colors.black54),
            ),
          ],
        )),
        const SizedBox(width: 8),
        FilledButton.icon(
          onPressed: _startWizard,
          icon: const Icon(Icons.flag_outlined),
          label: const Text('New'),
        ),
      ],
    );
  }

  Widget _outcomeFilterChips() {
    final outcomes = _localGoals
        .map((g) => g.outcome)
        .where((o) => o != null && o!.trim().isNotEmpty)
        .cast<String>()
        .toSet()
        .toList()
      ..sort();
    if (outcomes.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ChoiceChip(
          label: const Text('All outcomes'),
          selected: _localOutcome == null,
          onSelected: (_) => setState(() => _localOutcome = null),
        ),
        for (final o in outcomes)
          ChoiceChip(
            label: Text(o),
            selected: _localOutcome == o,
            onSelected: (_) => setState(() => _localOutcome = o),
          ),
      ],
    );
  }

  Future<void> _startWizard() async {
    final created = await showGoalWizard(context);
    if (created != null) {
      await _loadLocal();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Added goal "${created.title}"')));
    }
  }

  Widget _emptyLocal() {
    if (_localOutcome != null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('No goals match this outcome',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text('Try a different outcome filter or create a new goal.'),
            ],
          ),
        ),
      );
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('No self-guided goals yet',
                style: TextStyle(fontWeight: FontWeight.w600)),
            SizedBox(height: 8),
            Text(
                'Start with a small weekly cadence. You can soft skip without losing your streak.'),
          ],
        ),
      ),
    );
  }

  Widget _localGoalCard(SelfGuidedGoal g) {
    final summary = _weeklySummary(g);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _domainChip(g.domain),
                Text(g.title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 16)),
                Chip(
                  label: Text('${g.streak} day streak'),
                  visualDensity: VisualDensity.compact,
                  side: BorderSide(color: Colors.indigo.withOpacity(0.3)),
                  backgroundColor: Colors.indigo.withOpacity(0.05),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(g.action,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Colors.black87)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                _chip('${g.targetPerWeek}x/week', Colors.indigo),
                _chip('${g.minutesPerTask} min', Colors.blueGrey),
                _chip('XP ${g.xp}', Colors.deepPurple),
                if (g.outcome != null && g.outcome!.isNotEmpty)
                  _chip(g.outcome!, Colors.teal),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              runSpacing: 4,
              children: [
                Text('This week: ${summary.total} planned'),
                Text(
                  '${summary.done} done • ${summary.soft} soft skips • ${summary.pending} remaining',
                  style: const TextStyle(color: Colors.black54),
                ),
              ],
            ),
            const SizedBox(height: 6),
            LinearProgressIndicator(
              value: summary.total == 0
                  ? 0
                  : (summary.done / summary.total).clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: Colors.indigo.shade50,
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                TextButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/member/today'),
                  icon: const Icon(Icons.today_outlined),
                  label: const Text('View today'),
                ),
                OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => WeeklyPlanPage(goal: g))),
                  icon: const Icon(Icons.edit_calendar_outlined),
                  label: const Text('Edit plan'),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  _WeekSummary _weeklySummary(SelfGuidedGoal g) {
    final start = _monday(DateTime.now());
    final end = start.add(const Duration(days: 6));
    final tasks = g.tasks
        .where((t) =>
            !t.date.isBefore(start) && !t.date.isAfter(end))
        .toList();
    var done = 0;
    var soft = 0;
    var skipped = 0;
    for (final t in tasks) {
      switch (t.status) {
        case TaskStatus.done:
          done++;
          break;
        case TaskStatus.softSkipped:
          soft++;
          break;
        case TaskStatus.skipped:
          skipped++;
          break;
        case TaskStatus.pending:
          break;
      }
    }
    final pending = tasks.length - done - soft - skipped;
    return _WeekSummary(
        total: tasks.length, done: done, soft: soft, pending: pending);
  }

  DateTime _monday(DateTime dt) {
    final date = DateUtils.dateOnly(dt);
    final delta = date.weekday - DateTime.monday;
    return date.subtract(Duration(days: delta));
  }

  Widget _assistantHeader() {
    return Row(
      children: [
        Expanded(
          child: Text('Assistant goals',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600)),
        ),
        IconButton(
            onPressed: _fetchRemote, icon: const Icon(Icons.refresh_outlined))
      ],
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

  Widget _domainChip(String domain) {
    Color color;
    switch (domain.toUpperCase()) {
      case 'MIND':
        color = Colors.indigo;
        break;
      case 'RELATIONSHIPS':
        color = Colors.teal;
        break;
      case 'GROWTH':
        color = Colors.orange;
        break;
      case 'BODY':
        color = Colors.green;
        break;
      case 'MONEY':
        color = Colors.blue;
        break;
      case 'INTEGRATED':
        color = Colors.brown;
        break;
      default:
        color = Colors.grey;
    }
    final label = _domainLabel(domain);
    return Chip(
      label: Text(label),
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

  Widget _chip(String label, Color color) {
    return Chip(
      label: Text(label),
      side: BorderSide(color: color.withValues(alpha: 0.4)),
      backgroundColor: color.withValues(alpha: 0.08),
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

class _WeekSummary {
  final int total;
  final int done;
  final int soft;
  final int pending;
  const _WeekSummary(
      {required this.total,
      required this.done,
      required this.soft,
      required this.pending});
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
