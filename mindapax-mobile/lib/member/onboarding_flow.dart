import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/material.dart';

import '../auth/authorized_client.dart';
import '../auth/token_storage.dart';
import '../env.dart';
import 'onboarding_prefs.dart';

class OnboardingFlowPage extends StatefulWidget {
  const OnboardingFlowPage({super.key});

  @override
  State<OnboardingFlowPage> createState() => _OnboardingFlowPageState();
}

class _OnboardingFlowPageState extends State<OnboardingFlowPage> {
  final _page = PageController();
  int _index = 0;

  // Guided inputs
  final Set<String> _focus = <String>{};
  final _primaryGoalCtrl = TextEditingController();
  double _sleepHours = 7;
  int _exerciseDays = 3;
  final Set<String> _times = <String>{};
  String _reminders = 'WEEKLY';
  String _tone = 'SUPPORTIVE';
  final _notesCtrl = TextEditingController();

  bool _saving = false;
  final _storage = TokenStorage();

  @override
  void dispose() {
    _page.dispose();
    _primaryGoalCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Map<String, dynamic> _prefsMap() {
    return {
      'focus': _focus.toList(growable: false),
      'primaryGoal': _primaryGoalCtrl.text.trim(),
      'reminders': _reminders,
      'sleepHours': _sleepHours.round(),
      'exerciseDaysPerWeek': _exerciseDays,
      'preferredTimes': _times.toList(growable: false),
      'tone': _tone,
    };
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

  Future<void> _saveAndFinish() async {
    setState(() => _saving = true);
    try {
      final prefs = jsonEncode(_prefsMap());
      final client = AuthorizedHttpClient(_storage);
      final uri =
          Uri.parse('${_normalizeBaseUrl(apiBaseUrl)}/assistant/context');
      final body = jsonEncode(
          {'preferencesJson': prefs, 'notes': _notesCtrl.text.trim()});
      final res = await client.post(uri,
          headers: {'Content-Type': 'application/json'}, body: body);
      if (res.statusCode >= 200 && res.statusCode < 300) {
        await OnboardingPrefs.setCompleted(true);
        if (!mounted) return;
        final messenger = ScaffoldMessenger.of(context);
        final navigator = Navigator.of(context);
        messenger.showSnackBar(const SnackBar(
            content: Text('Thanks! Your preferences are saved.')));
        navigator.pushNamedAndRemoveUntil('/member/dashboard', (r) => false);
      } else {
        if (!mounted) return;
        final messenger = ScaffoldMessenger.of(context);
        messenger.showSnackBar(
            SnackBar(content: Text('Save failed (${res.statusCode})')));
      }
    } catch (e) {
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      messenger.showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _next() {
    if (_index < 3) {
      _page.nextPage(
          duration: const Duration(milliseconds: 250), curve: Curves.easeInOut);
    } else {
      _saveAndFinish();
    }
  }

  void _back() {
    if (_index > 0) {
      _page.previousPage(
          duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: _index > 0
            ? IconButton(onPressed: _back, icon: const Icon(Icons.arrow_back))
            : null,
        title: const Text("Let's get to know each other"),
        actions: [
          TextButton(
            onPressed: _saving
                ? null
                : () async {
                    await OnboardingPrefs.setCompleted(true);
                    if (!context.mounted) return;
                    Navigator.of(context).pushNamedAndRemoveUntil(
                        '/member/dashboard', (r) => false);
                  },
            child: const Text('Skip'),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            LinearProgressIndicator(value: (_index + 1) / 4),
            Expanded(
              child: PageView(
                controller: _page,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _index = i),
                children: [
                  _IntroPage(onNext: _next),
                  _GoalFocusPage(
                    focus: _focus,
                    primaryGoalCtrl: _primaryGoalCtrl,
                  ),
                  _HabitsTimesPage(
                    sleepHours: _sleepHours,
                    onSleepChanged: (v) => setState(() => _sleepHours = v),
                    exerciseDays: _exerciseDays,
                    onExerciseChanged: (v) => setState(() => _exerciseDays = v),
                    times: _times,
                  ),
                  _ToneRemindersPage(
                    reminders: _reminders,
                    onRemindersChanged: (v) => setState(() => _reminders = v),
                    tone: _tone,
                    onToneChanged: (v) => setState(() => _tone = v),
                    notesCtrl: _notesCtrl,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                children: [
                  if (_index > 0)
                    OutlinedButton.icon(
                      onPressed: _saving ? null : _back,
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Back'),
                    ),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: _saving ? null : _next,
                    icon: _saving
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : Icon(_index < 3 ? Icons.arrow_forward : Icons.check),
                    label: Text(_index < 3 ? 'Continue' : 'Finish'),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

class _IntroPage extends StatelessWidget {
  final VoidCallback onNext;
  const _IntroPage({required this.onNext});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          const Text(
            "Let's get to know each other",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          const Text(
            'A few quick questions will help personalize your AI Assistant recommendations.',
          ),
          const Spacer(),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: onNext,
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Start'),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _GoalFocusPage extends StatelessWidget {
  final Set<String> focus;
  final TextEditingController primaryGoalCtrl;
  const _GoalFocusPage({required this.focus, required this.primaryGoalCtrl});
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Primary goal',
            style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextField(
          controller: primaryGoalCtrl,
          decoration: const InputDecoration(
              hintText: 'e.g., Reduce stress and sleep better',
              border: OutlineInputBorder()),
        ),
        const SizedBox(height: 16),
        const Text('Focus areas',
            style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            for (final f in const [
              'sleep',
              'stress',
              'productivity',
              'nutrition',
              'exercise',
              'mindfulness',
              'finance',
              'relationships',
              'time-management'
            ])
              FilterChip(
                label: Text(f),
                selected: focus.contains(f),
                onSelected: (v) {
                  if (v) {
                    focus.add(f);
                  } else {
                    focus.remove(f);
                  }
                },
              ),
          ],
        ),
      ],
    );
  }
}

class _HabitsTimesPage extends StatelessWidget {
  final double sleepHours;
  final ValueChanged<double> onSleepChanged;
  final int exerciseDays;
  final ValueChanged<int> onExerciseChanged;
  final Set<String> times;
  const _HabitsTimesPage({
    required this.sleepHours,
    required this.onSleepChanged,
    required this.exerciseDays,
    required this.onExerciseChanged,
    required this.times,
  });
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Habits', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Text('Sleep hours: ${sleepHours.round()}'),
        Slider(
          value: sleepHours,
          min: 4,
          max: 12,
          divisions: 8,
          label: sleepHours.round().toString(),
          onChanged: onSleepChanged,
        ),
        const SizedBox(height: 8),
        Text('Exercise days/week: $exerciseDays'),
        Slider(
          value: exerciseDays.toDouble(),
          min: 0,
          max: 7,
          divisions: 7,
          label: exerciseDays.toString(),
          onChanged: (v) => onExerciseChanged(v.round()),
        ),
        const SizedBox(height: 16),
        const Text('Preferred times',
            style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          children: [
            for (final t in const ['morning', 'afternoon', 'evening'])
              FilterChip(
                label: Text(t),
                selected: times.contains(t),
                onSelected: (v) {
                  if (v) {
                    times.add(t);
                  } else {
                    times.remove(t);
                  }
                },
              ),
          ],
        ),
      ],
    );
  }
}

class _ToneRemindersPage extends StatelessWidget {
  final String reminders;
  final ValueChanged<String> onRemindersChanged;
  final String tone;
  final ValueChanged<String> onToneChanged;
  final TextEditingController notesCtrl;
  const _ToneRemindersPage({
    required this.reminders,
    required this.onRemindersChanged,
    required this.tone,
    required this.onToneChanged,
    required this.notesCtrl,
  });
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: reminders,
                decoration:
                    const InputDecoration(labelText: 'Reminders cadence'),
                items: const [
                  DropdownMenuItem(value: 'DAILY', child: Text('Daily')),
                  DropdownMenuItem(value: 'WEEKLY', child: Text('Weekly')),
                  DropdownMenuItem(value: 'MONTHLY', child: Text('Monthly')),
                ],
                onChanged: (v) => onRemindersChanged(v ?? 'WEEKLY'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: tone,
                decoration: const InputDecoration(labelText: 'Assistant style'),
                items: const [
                  DropdownMenuItem(
                      value: 'SUPPORTIVE', child: Text('Supportive')),
                  DropdownMenuItem(value: 'COACHING', child: Text('Coaching')),
                  DropdownMenuItem(value: 'CONCISE', child: Text('Concise')),
                ],
                onChanged: (v) => onToneChanged(v ?? 'SUPPORTIVE'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text('Notes', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextField(
          controller: notesCtrl,
          minLines: 4,
          maxLines: 10,
          decoration: const InputDecoration(
            hintText: 'Anything helpful to personalize suggestions…',
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }
}
