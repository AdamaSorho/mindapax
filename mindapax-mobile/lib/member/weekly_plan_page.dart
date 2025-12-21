import 'package:flutter/material.dart';

import 'self_guided_store.dart';

class WeeklyPlanPage extends StatefulWidget {
  final SelfGuidedGoal goal;
  const WeeklyPlanPage({super.key, required this.goal});

  @override
  State<WeeklyPlanPage> createState() => _WeeklyPlanPageState();
}

class _WeeklyPlanPageState extends State<WeeklyPlanPage> {
  SelfGuidedGoal? _goal;
  bool _loading = true;
  bool _saving = false;
  String? _error;

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
      final goals = await SelfGuidedStore.loadGoals();
      final found = goals.firstWhere((g) => g.id == widget.goal.id,
          orElse: () => widget.goal);
      if (!mounted) return;
      setState(() {
        _goal = found;
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

  Future<void> _rescheduleMissed() async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final updated = await SelfGuidedStore.rescheduleMissed(widget.goal.id);
      if (!mounted) return;
      if (updated == null) {
        setState(() => _error = 'Goal not found.');
        return;
      }
      setState(() => _goal = updated);
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Missed tasks rescheduled.')));
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _swapVariant(GoalTask task, _Variant variant) async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final updatedTask = _variantTask(task, variant);
      final updatedGoal = await SelfGuidedStore.updateTask(updatedTask);
      if (!mounted) return;
      if (updatedGoal == null) {
        setState(() => _error = 'Goal not found.');
        return;
      }
      setState(() => _goal = updatedGoal);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(variant == _Variant.lighter
              ? 'Lighter option applied'
              : 'Stretch option applied')));
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  GoalTask _variantTask(GoalTask task, _Variant variant) {
    int clamp(int v) => v.clamp(5, 120);
    switch (variant) {
      case _Variant.lighter:
        return task.copyWith(
          minutes: clamp((task.minutes * 0.5).round()),
          title: 'Lighter: ${task.title}',
        );
      case _Variant.stretch:
        return task.copyWith(
          minutes: clamp((task.minutes * 1.5).round()),
          title: 'Stretch: ${task.title}',
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final goal = _goal ?? widget.goal;
    final tasks = goal.tasks.toList()..sort((a, b) => a.date.compareTo(b.date));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Weekly plan'),
        actions: [
          IconButton(
              onPressed: _saving ? null : _rescheduleMissed,
              icon: const Icon(Icons.schedule_outlined))
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  Text(goal.title,
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(goal.action,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: Colors.black87)),
                  if (goal.outcome != null && goal.outcome!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Chip(
                        label: Text(goal.outcome!),
                        visualDensity: VisualDensity.compact,
                        side: BorderSide(color: Colors.teal.withOpacity(0.3)),
                        backgroundColor: Colors.teal.withOpacity(0.08),
                      ),
                    ),
                  const SizedBox(height: 8),
                  Text(
                      '${goal.targetPerWeek}x/week • ${goal.minutesPerTask} min • ${goal.difficulty}',
                      style: const TextStyle(color: Colors.black54)),
                  const SizedBox(height: 8),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(_error!,
                          style: const TextStyle(color: Colors.red)),
                    ),
                  ...tasks.map((t) => _taskTile(t)),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _taskTile(GoalTask task) {
    final dateLabel = '${task.date.month}/${task.date.day}';
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(dateLabel,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 15)),
                const SizedBox(width: 8),
                Chip(
                  label: Text(task.status.label),
                  visualDensity: VisualDensity.compact,
                  side: BorderSide(color: task.status.color.withOpacity(0.3)),
                  backgroundColor: task.status.color.withOpacity(0.08),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(task.title,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Colors.black87)),
            const SizedBox(height: 4),
            Text('${task.minutes} min',
                style: const TextStyle(color: Colors.black54, fontSize: 12)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                OutlinedButton.icon(
                    onPressed: _saving
                        ? null
                        : () => _swapVariant(task, _Variant.lighter),
                    icon: const Icon(Icons.trending_down),
                    label: const Text('Lighter')),
                OutlinedButton.icon(
                    onPressed: _saving
                        ? null
                        : () => _swapVariant(task, _Variant.stretch),
                    icon: const Icon(Icons.trending_up),
                    label: const Text('Stretch')),
              ],
            )
          ],
        ),
      ),
    );
  }
}

enum _Variant { lighter, stretch }
