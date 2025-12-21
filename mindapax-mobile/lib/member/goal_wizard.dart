import 'package:flutter/material.dart';

import 'self_guided_store.dart';

Future<SelfGuidedGoal?> showGoalWizard(BuildContext context) {
  return showModalBottomSheet<SelfGuidedGoal>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => const _GoalWizardSheet(),
  );
}

class _GoalWizardSheet extends StatefulWidget {
  const _GoalWizardSheet();

  @override
  State<_GoalWizardSheet> createState() => _GoalWizardSheetState();
}

class _GoalWizardSheetState extends State<_GoalWizardSheet> {
  int _step = 0;
  String _domain = 'MIND';
  String? _outcome;
  String _difficulty = 'STEADY';
  int _targetPerWeek = 3;
  int _minutes = 20;
  final _titleCtrl = TextEditingController();
  final _actionCtrl = TextEditingController();
  bool _saving = false;
  GoalTemplate? _selectedTemplate;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _actionCtrl.dispose();
    super.dispose();
  }

  void _next() {
    if (_step == 0 && _titleCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Give your goal a title to continue.')));
      return;
    }
    if (_step < 2) {
      setState(() => _step += 1);
    } else {
      _save();
    }
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final goal = await SelfGuidedStore.createGoal(
        title: _titleCtrl.text.trim(),
        domain: _domain,
        outcome: _outcome,
        action: _actionCtrl.text.trim().isEmpty
            ? 'Work on ${_titleCtrl.text.trim()}'
            : _actionCtrl.text.trim(),
        targetPerWeek: _targetPerWeek,
        minutesPerTask: _minutes,
        difficulty: _difficulty,
      );
      if (!mounted) return;
      Navigator.pop(context, goal);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create goal: $e')));
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(12)),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('New self-guided goal',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
              Text('Step ${_step + 1} of 3',
                  style: Theme.of(context)
                      .textTheme
                      .labelMedium
                      ?.copyWith(color: Colors.black54)),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.55,
            child: IndexedStack(
              index: _step,
              children: [
                SingleChildScrollView(child: _stepIdentity()),
                SingleChildScrollView(child: _stepCadence()),
                SingleChildScrollView(child: _stepReview()),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (_step > 0)
                TextButton(
                    onPressed: () => setState(() => _step -= 1),
                    child: const Text('Back')),
              const Spacer(),
              FilledButton(
                  onPressed: _saving ? null : _next,
                  child: Text(_step == 2 ? 'Create' : 'Next')),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _stepIdentity() {
    final outcomes = _outcomesForDomain(_domain);
    final templates = _filteredTemplates();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('What do you want to achieve?'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final d in const [
              'MIND',
              'MONEY',
              'BODY',
              'RELATIONSHIPS',
              'GROWTH',
              'INTEGRATED',
              'CUSTOM'
            ])
              ChoiceChip(
                label: Text(_domainLabel(d)),
                selected: _domain == d,
                onSelected: (_) => _setDomain(d),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Text('Outcome focus',
            style: Theme.of(context)
                .textTheme
                .labelMedium
                ?.copyWith(color: Colors.black54)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ChoiceChip(
              label: const Text('All'),
              selected: _outcome == null,
              onSelected: (_) => setState(() => _outcome = null),
            ),
            for (final o in outcomes)
              ChoiceChip(
                label: Text(o),
                selected: _outcome == o,
                onSelected: (_) => setState(() => _outcome = o),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Text('Quick start templates',
            style: Theme.of(context)
                .textTheme
                .labelMedium
                ?.copyWith(color: Colors.black54)),
        const SizedBox(height: 6),
        if (templates.isEmpty)
          const Text('No templates for this filter. Try another outcome.'),
        for (final t in templates) _templateCard(t),
        const SizedBox(height: 12),
        TextField(
          controller: _titleCtrl,
          decoration: const InputDecoration(
              labelText: 'Goal title', border: OutlineInputBorder()),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _actionCtrl,
          decoration: const InputDecoration(
              labelText: 'Primary action',
              helperText: 'e.g., 10-minute breathing, 30-minute walk, budget review',
              border: OutlineInputBorder()),
        ),
      ],
    );
  }

  Widget _stepCadence() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('How often and how intense?'),
        const SizedBox(height: 12),
        Text('Sessions per week: $_targetPerWeek'),
        Slider(
          value: _targetPerWeek.toDouble(),
          min: 1,
          max: 7,
          divisions: 6,
          label: '$_targetPerWeek',
          onChanged: (v) => setState(() => _targetPerWeek = v.round()),
        ),
        const SizedBox(height: 12),
        Text('Minutes per session: $_minutes'),
        Slider(
          value: _minutes.toDouble(),
          min: 5,
          max: 60,
          divisions: 11,
          label: '$_minutes',
          onChanged: (v) => setState(() => _minutes = v.round()),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: [
            for (final d in const ['EASE', 'STEADY', 'STRETCH'])
              ChoiceChip(
                label: Text(d[0] + d.substring(1).toLowerCase()),
                selected: _difficulty == d,
                onSelected: (_) => setState(() => _difficulty = d),
              ),
          ],
        )
      ],
    );
  }

  Widget _stepReview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Review'),
        const SizedBox(height: 8),
        _summaryRow('Domain', _domainLabel(_domain)),
        if (_outcome != null) _summaryRow('Outcome', _outcome!),
        _summaryRow('Title', _titleCtrl.text.trim()),
        _summaryRow('Action',
            _actionCtrl.text.trim().isEmpty ? 'Work on goal' : _actionCtrl.text.trim()),
        _summaryRow('Cadence', '$_targetPerWeek x / week'),
        _summaryRow('Minutes', '$_minutes minutes'),
        _summaryRow('Difficulty',
            _difficulty[0] + _difficulty.substring(1).toLowerCase()),
        const SizedBox(height: 8),
        const Text(
            'We will auto-spread your sessions through the week and keep streaks with one soft skip per day.'),
      ],
    );
  }

  void _setDomain(String d) {
    final outcomes = _outcomesForDomain(d);
    setState(() {
      _domain = d;
      if (_outcome != null && !outcomes.contains(_outcome)) {
        _outcome = null;
      }
      if (_selectedTemplate != null &&
          _selectedTemplate!.domain != d &&
          d != 'CUSTOM') {
        _selectedTemplate = null;
      }
    });
  }

  List<String> _outcomesForDomain(String domain) {
    final filtered = _templates
        .where((t) => domain == 'CUSTOM' ? true : t.domain == domain)
        .map((t) => t.outcome)
        .toSet()
        .toList();
    filtered.sort();
    return filtered;
  }

  List<GoalTemplate> _filteredTemplates() {
    return _templates
        .where((t) {
          if (_domain != 'CUSTOM' && t.domain != _domain) return false;
          if (_outcome != null && t.outcome != _outcome) return false;
          return true;
        })
        .toList(growable: false);
  }

  void _applyTemplate(GoalTemplate t) {
    setState(() {
      _selectedTemplate = t;
      _domain = t.domain;
      _outcome = t.outcome;
      _difficulty = t.difficulty;
      _targetPerWeek = t.targetPerWeek;
      _minutes = t.minutes;
      _titleCtrl.text = t.title;
      _actionCtrl.text = t.action;
    });
  }

  Widget _templateCard(GoalTemplate t) {
    final isSelected = _selectedTemplate?.id == t.id;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: InkWell(
        onTap: () => _applyTemplate(t),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(t.title,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 15)),
                  ),
                  if (isSelected)
                    const Icon(Icons.check_circle, color: Colors.green),
                ],
              ),
              const SizedBox(height: 4),
              Text(t.action,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: Colors.black87)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  _miniChip(_domainLabel(t.domain)),
                  _miniChip(t.outcome),
                  _miniChip('${t.targetPerWeek}x/week'),
                  _miniChip('${t.minutes} min'),
                  _miniChip(_prettyDifficulty(t.difficulty)),
                ],
              )
            ],
          ),
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

  String _prettyDifficulty(String value) {
    if (value.isEmpty) return value;
    return value[0] + value.substring(1).toLowerCase();
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
              width: 120,
              child:
                  Text(label, style: const TextStyle(color: Colors.black54))),
          Expanded(
              child: Text(value,
                  style: const TextStyle(fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}

class GoalTemplate {
  final String id;
  final String domain;
  final String outcome;
  final String title;
  final String action;
  final int targetPerWeek;
  final int minutes;
  final String difficulty;

  const GoalTemplate({
    required this.id,
    required this.domain,
    required this.outcome,
    required this.title,
    required this.action,
    required this.targetPerWeek,
    required this.minutes,
    required this.difficulty,
  });
}

const List<GoalTemplate> _templates = [
  GoalTemplate(
    id: 'clarity_journal',
    domain: 'MIND',
    outcome: 'Find clarity',
    title: 'Find clarity through journaling',
    action: 'Clarity journal: 3 key thoughts + next step',
    targetPerWeek: 3,
    minutes: 20,
    difficulty: 'STEADY',
  ),
  GoalTemplate(
    id: 'reduce_stress',
    domain: 'MIND',
    outcome: 'Reduce stress',
    title: 'Reduce stress and anxiety',
    action: '10-minute breathing + stress log',
    targetPerWeek: 5,
    minutes: 10,
    difficulty: 'EASE',
  ),
  GoalTemplate(
    id: 'self_confidence',
    domain: 'GROWTH',
    outcome: 'Improve self-confidence',
    title: 'Build self-confidence',
    action: 'Confidence micro-challenge + reflection',
    targetPerWeek: 3,
    minutes: 15,
    difficulty: 'STEADY',
  ),
  GoalTemplate(
    id: 'heal_patterns',
    domain: 'MIND',
    outcome: 'Heal emotional patterns',
    title: 'Heal emotional patterns',
    action: 'Thought check-in + reframe exercise',
    targetPerWeek: 4,
    minutes: 15,
    difficulty: 'STEADY',
  ),
  GoalTemplate(
    id: 'mental_discipline',
    domain: 'MIND',
    outcome: 'Strengthen mental discipline',
    title: 'Strengthen mental discipline',
    action: 'Focus sprint + distraction log',
    targetPerWeek: 4,
    minutes: 25,
    difficulty: 'STRETCH',
  ),
  GoalTemplate(
    id: 'manage_money',
    domain: 'MONEY',
    outcome: 'Manage money better',
    title: 'Manage money better',
    action: 'Weekly budget review + savings check',
    targetPerWeek: 1,
    minutes: 30,
    difficulty: 'STEADY',
  ),
  GoalTemplate(
    id: 'grow_professionally',
    domain: 'MONEY',
    outcome: 'Grow professionally',
    title: 'Grow professionally',
    action: 'Career growth task (CV, skills, outreach)',
    targetPerWeek: 3,
    minutes: 30,
    difficulty: 'STEADY',
  ),
  GoalTemplate(
    id: 'healthy_habits',
    domain: 'BODY',
    outcome: 'Build healthy habits',
    title: 'Build healthy habits',
    action: 'Daily movement + hydration check',
    targetPerWeek: 5,
    minutes: 20,
    difficulty: 'STEADY',
  ),
  GoalTemplate(
    id: 'physical_energy',
    domain: 'BODY',
    outcome: 'Improve physical energy',
    title: 'Improve physical energy',
    action: 'Sleep routine + light movement',
    targetPerWeek: 4,
    minutes: 15,
    difficulty: 'EASE',
  ),
  GoalTemplate(
    id: 'relationships',
    domain: 'RELATIONSHIPS',
    outcome: 'Build healthier relationships',
    title: 'Build healthier relationships',
    action: 'Connection check-in + active listening',
    targetPerWeek: 2,
    minutes: 20,
    difficulty: 'STEADY',
  ),
  GoalTemplate(
    id: 'transitions',
    domain: 'INTEGRATED',
    outcome: 'Overcome transitions',
    title: 'Overcome life transitions',
    action: 'Grounding plan + next step',
    targetPerWeek: 2,
    minutes: 20,
    difficulty: 'STEADY',
  ),
  GoalTemplate(
    id: 'balanced_life',
    domain: 'INTEGRATED',
    outcome: 'Live a balanced, intentional life',
    title: 'Live a balanced, intentional life',
    action: 'Weekly life review + plan 3 small wins',
    targetPerWeek: 1,
    minutes: 30,
    difficulty: 'STEADY',
  ),
];
