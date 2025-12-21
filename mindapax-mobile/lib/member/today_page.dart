import 'package:flutter/material.dart';

import 'member_scaffold.dart';
import 'micro_sessions_api.dart';
import 'micro_sessions_data.dart';
import 'micro_sessions_page.dart';
import 'self_guided_store.dart';

class TodayPage extends StatefulWidget {
  const TodayPage({super.key});

  @override
  State<TodayPage> createState() => _TodayPageState();
}

class _TodayPageState extends State<TodayPage> {
  bool _loading = true;
  String? _error;
  List<SelfGuidedGoal> _goals = const [];
  List<GoalTask> _todayTasks = const [];
  List<MicroSession> _suggestedSessions = const [];
  DailyCheckIn? _checkIn;
  String? _outcomeFilter;
  int _mood = 3;
  int _effort = 3;
  final _noteCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final goals = await SelfGuidedStore.loadGoals();
      final today = DateUtils.dateOnly(DateTime.now());
      final tasks = goals
          .expand((g) => g.tasks.where((t) => DateUtils.isSameDay(t.date, today)))
          .toList()
        ..sort((a, b) => a.status.index.compareTo(b.status.index));
      final outcomes = goals
          .map((g) => g.outcome)
          .where((o) => o != null && o.trim().isNotEmpty)
          .cast<String>()
          .toSet();
      List<MicroSession> sessionPool;
      try {
        final remote = await MicroSessionsApi.list();
        sessionPool = remote.isEmpty ? microSessions : remote;
      } catch (_) {
        sessionPool = microSessions;
      }
      final difficulty = _difficultyHint(goals, tasks);
      final suggested =
          _suggestByDifficultyAndOutcome(sessionPool, outcomes, difficulty);
      final checkIn = await SelfGuidedStore.loadCheckIn(today);
      if (checkIn != null) {
        _mood = checkIn.mood;
        _effort = checkIn.effort;
        _noteCtrl.text = checkIn.note ?? '';
      }
      final validOutcomeFilter =
          _outcomeFilter != null && outcomes.contains(_outcomeFilter)
              ? _outcomeFilter
              : null;
      if (!mounted) return;
      setState(() {
        _goals = goals;
        _todayTasks = tasks;
        _suggestedSessions = suggested;
        _checkIn = checkIn;
        _outcomeFilter = validOutcomeFilter;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  String? _difficultyHint(
      List<SelfGuidedGoal> goals, List<GoalTask> todayTasks) {
    if (goals.isEmpty) return null;
    final counts = <String, int>{};
    final goalsById = {for (final g in goals) g.id: g};
    if (todayTasks.isNotEmpty) {
      for (final task in todayTasks) {
        final goal = goalsById[task.goalId];
        if (goal == null) continue;
        final diff = goal.difficulty.toUpperCase();
        counts[diff] = (counts[diff] ?? 0) + 1;
      }
    }
    if (counts.isEmpty) {
      for (final goal in goals) {
        final diff = goal.difficulty.toUpperCase();
        counts[diff] = (counts[diff] ?? 0) + 1;
      }
    }
    if (counts.isEmpty) return null;
    const priority = ['EASE', 'STEADY', 'STRETCH'];
    String? best;
    var bestCount = -1;
    for (final entry in counts.entries) {
      if (best == null || entry.value > bestCount) {
        best = entry.key;
        bestCount = entry.value;
        continue;
      }
      if (entry.value == bestCount) {
        final bestRank = priority.indexOf(best!);
        final entryRank = priority.indexOf(entry.key);
        if (entryRank != -1 &&
            (bestRank == -1 || entryRank < bestRank)) {
          best = entry.key;
        }
      }
    }
    return best;
  }

  List<MicroSession> _suggestByDifficultyAndOutcome(
    List<MicroSession> pool,
    Set<String> outcomes,
    String? difficulty, {
    int limit = 3,
  }) {
    if (pool.isEmpty) return const [];
    final outcomeFiltered = outcomes.isEmpty
        ? pool
        : pool.where((s) => s.outcomes.any(outcomes.contains)).toList();
    final difficultyFiltered = difficulty == null
        ? outcomeFiltered
        : outcomeFiltered.where((s) {
            switch (difficulty) {
              case 'EASE':
                return s.minutes <= 6;
              case 'STEADY':
                return s.minutes >= 6 && s.minutes <= 10;
              case 'STRETCH':
                return s.minutes >= 8;
              default:
                return true;
            }
          }).toList();
    final selected = <MicroSession>[];
    final selectedIds = <String>{};
    void addFrom(Iterable<MicroSession> source) {
      for (final session in source) {
        if (selected.length >= limit) break;
        if (selectedIds.add(session.id)) {
          selected.add(session);
        }
      }
    }

    addFrom(difficultyFiltered);
    if (selected.length < limit && difficulty != null) {
      addFrom(outcomeFiltered);
    }
    if (selected.length < limit) {
      addFrom(pool);
    }
    return selected;
  }

  Future<void> _setStatus(GoalTask task, TaskStatus status) async {
    try {
      setState(() => _loading = true);
      await SelfGuidedStore.updateTaskStatus(
          goalId: task.goalId, taskId: task.id, status: status);
      await _load();
      if (!mounted) return;
      final label = status == TaskStatus.softSkipped
          ? 'Soft skipped — streak kept, plan adjusted.'
          : status == TaskStatus.done
              ? 'Nice work — +XP!'
              : 'Skipped.';
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(label)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Update failed: $e')));
    }
  }

  Future<void> _saveCheckIn() async {
    final entry = DailyCheckIn(
      date: DateTime.now(),
      mood: _mood,
      effort: _effort,
      note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
    );
    try {
      await SelfGuidedStore.saveCheckIn(entry);
      if (!mounted) return;
      setState(() => _checkIn = entry);
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Check-in saved for today.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Save failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalXp = _goals.fold<int>(0, (sum, g) => sum + g.xp);
    final bestStreak =
        _goals.isEmpty ? 0 : _goals.map((g) => g.streak).reduce((a, b) => a > b ? a : b);
    return MemberScaffold(
      title: 'Today',
      currentRoute: '/member/today',
      child: RefreshIndicator(
        onRefresh: _load,
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
            _buildStats(totalXp, bestStreak),
            const SizedBox(height: 12),
            _buildCheckInCard(),
            const SizedBox(height: 12),
            _buildTasksSection(),
            const SizedBox(height: 12),
            _buildMicroSessions(),
          ],
        ),
      ),
    );
  }

  Widget _buildStats(int xp, int streak) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Streak', style: Theme.of(context).textTheme.labelMedium),
                  const SizedBox(height: 4),
                  Text('$streak days',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  Text(
                      'Soft skips preserve your streak once per day without XP.',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: Colors.black54)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('XP', style: Theme.of(context).textTheme.labelMedium),
                  const SizedBox(height: 4),
                  Text('$xp',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  LinearProgressIndicator(
                    value: ((xp % 100) / 100).clamp(0.0, 1.0),
                    minHeight: 6,
                    backgroundColor: Colors.indigo.shade50,
                  ),
                  const SizedBox(height: 4),
                  Text('Next badge at ${(xp ~/ 100 + 1) * 100} XP',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: Colors.black54)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckInCard() {
    final hasEntry = _checkIn != null;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.favorite_outline, color: Colors.indigo),
                const SizedBox(width: 8),
                Text(
                  hasEntry ? 'Today\'s check-in' : 'Check-in for today',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _sliderRow('Mood', _mood, (v) => setState(() => _mood = v)),
            _sliderRow('Effort', _effort, (v) => setState(() => _effort = v)),
            const SizedBox(height: 8),
            TextField(
              controller: _noteCtrl,
              decoration: const InputDecoration(
                  labelText: 'Notes (optional)', border: OutlineInputBorder()),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: _saveCheckIn,
                icon: const Icon(Icons.save_outlined),
                label: Text(hasEntry ? 'Update' : 'Save'),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _sliderRow(String label, int value, ValueChanged<int> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style:
                Theme.of(context).textTheme.labelMedium?.copyWith(fontSize: 13)),
        Slider(
          value: value.toDouble(),
          onChanged: (v) => onChanged(v.round().clamp(1, 5)),
          min: 1,
          max: 5,
          divisions: 4,
          label: '$value',
        )
      ],
    );
  }

  Widget _buildTasksSection() {
    final filteredTasks = _filteredTodayTasks();
    if (_todayTasks.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Nothing scheduled today',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              const Text(
                  'Add or adjust a goal to populate your week. We’ll keep your streak safe if you set a soft skip.'),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/member/goals'),
                  icon: const Icon(Icons.flag_outlined),
                  label: const Text('Add a goal')),
            ],
          ),
        ),
      );
    }
    if (filteredTasks.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('No tasks for this outcome today',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              const Text('Try a different outcome or clear the filter.'),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                  onPressed: () => _setOutcomeFilter(null),
                  icon: const Icon(Icons.filter_alt_off_outlined),
                  label: const Text('Clear filter')),
            ],
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Today\'s tasks',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w600)),
        if (_outcomeFilter != null) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.filter_alt_outlined,
                  size: 16, color: Colors.black54),
              const SizedBox(width: 6),
              Expanded(
                child: Text('Filtered by $_outcomeFilter',
                    style: const TextStyle(color: Colors.black54)),
              ),
              TextButton(
                  onPressed: () => _setOutcomeFilter(null),
                  child: const Text('Clear')),
            ],
          ),
        ],
        const SizedBox(height: 8),
        for (final task in filteredTasks) _taskCard(task),
      ],
    );
  }

  Widget _buildMicroSessions() {
    if (_suggestedSessions.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Quick micro sessions',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              const Text('Short sessions to keep momentum on busy days.'),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                  onPressed: () =>
                      Navigator.pushNamed(context, '/member/micro-sessions'),
                  icon: const Icon(Icons.bolt_outlined),
                  label: const Text('Browse micro sessions')),
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
          children: [
            Text('Suggested micro sessions',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            for (final session in _suggestedSessions)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(session.title),
                subtitle: Text(session.description),
                trailing: Text('${session.minutes} min',
                    style: const TextStyle(color: Colors.black54)),
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => MicroSessionDetailPage(
                          session: session,
                          onCompleted: _load,
                        ))),
              ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                  onPressed: () =>
                      Navigator.pushNamed(context, '/member/micro-sessions'),
                  child: const Text('See all')),
            )
          ],
        ),
      ),
    );
  }

  Widget _taskCard(GoalTask task) {
    final goal = _goals.firstWhere((g) => g.id == task.goalId);
    final isDone = task.status == TaskStatus.done;
    final isSoft = task.status == TaskStatus.softSkipped;
    final isSkipped = task.status == TaskStatus.skipped;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _domainChip(goal.domain),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(goal.title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 16)),
                ),
                Chip(
                  label: Text(task.status.label),
                  backgroundColor: task.status.color.withOpacity(0.08),
                  side: BorderSide(color: task.status.color.withOpacity(0.4)),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            if (goal.outcome != null && goal.outcome!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [_outcomeChip(goal.outcome!)],
              ),
            ],
            const SizedBox(height: 6),
            Text(task.title,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Colors.black87)),
            const SizedBox(height: 6),
            Text('${task.minutes} min • ${_friendlyDate(task.date)}',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.black54)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: isDone ? null : () => _setStatus(task, TaskStatus.done),
                  icon: const Icon(Icons.check),
                  label: const Text('Did it'),
                ),
                OutlinedButton.icon(
                  onPressed:
                      isDone || isSoft ? null : () => _setStatus(task, TaskStatus.softSkipped),
                  icon: const Icon(Icons.flag_rounded),
                  label: const Text('Too hard (soft skip)'),
                ),
                TextButton.icon(
                  onPressed:
                      isDone || isSoft || isSkipped ? null : () => _setStatus(task, TaskStatus.skipped),
                  icon: const Icon(Icons.cancel_outlined),
                  label: const Text('Skip'),
                ),
              ],
            )
          ],
        ),
      ),
    );
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

  Widget _outcomeChip(String outcome) {
    final color = Colors.teal;
    final selected = _outcomeFilter == outcome;
    return InputChip(
      label: Text(outcome),
      selected: selected,
      onSelected: (_) => _setOutcomeFilter(selected ? null : outcome),
      backgroundColor: color.withOpacity(0.08),
      side: BorderSide(color: color.withOpacity(0.35)),
      visualDensity: VisualDensity.compact,
    );
  }

  List<GoalTask> _filteredTodayTasks() {
    if (_outcomeFilter == null) return _todayTasks;
    final goalsById = {for (final g in _goals) g.id: g};
    return _todayTasks.where((task) {
      final outcome = goalsById[task.goalId]?.outcome;
      return outcome != null && outcome == _outcomeFilter;
    }).toList();
  }

  void _setOutcomeFilter(String? outcome) {
    setState(() => _outcomeFilter = outcome);
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

  String _friendlyDate(DateTime date) {
    final today = DateUtils.dateOnly(DateTime.now());
    if (DateUtils.isSameDay(today, date)) return 'Today';
    final tomorrow = today.add(const Duration(days: 1));
    if (DateUtils.isSameDay(tomorrow, date)) return 'Tomorrow';
    return '${date.month}/${date.day}';
  }
}
