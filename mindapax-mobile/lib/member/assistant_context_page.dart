import 'dart:convert';

import 'package:flutter/material.dart';
import '../auth/authorized_client.dart';
import '../auth/token_storage.dart';
import '../env.dart';
import 'dart:io' show Platform;

class AssistantContextPage extends StatefulWidget {
  const AssistantContextPage({super.key});

  @override
  State<AssistantContextPage> createState() => _AssistantContextPageState();
}

class _AssistantContextPageState extends State<AssistantContextPage> {
  final _prefsCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _storage = TokenStorage();
  bool _loading = false;
  String? _prefsError;
  // Guided fields (user-friendly)
  final Set<String> _focus = <String>{};
  final Set<String> _times = <String>{}; // morning/afternoon/evening
  double _sleepHours = 7;
  int _exerciseDays = 3; // per week
  String _reminders = 'WEEKLY'; // DAILY/WEEKLY/MONTHLY
  String _tone = 'SUPPORTIVE'; // SUPPORTIVE/COACHING/CONCISE
  final _primaryGoalCtrl = TextEditingController();
  bool _showAdvanced = false; // optionally show raw JSON

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _prefsCtrl.dispose();
    _notesCtrl.dispose();
    _primaryGoalCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final client = AuthorizedHttpClient(_storage);
      final uri =
          Uri.parse('${_normalizeBaseUrl(apiBaseUrl)}/assistant/context');
      final res = await client.get(uri);
      if (res.statusCode >= 200 && res.statusCode < 300) {
        if (res.body.isNotEmpty && res.body != 'null') {
          final json = jsonDecode(res.body) as Map<String, dynamic>;
          _prefsCtrl.text = (json['preferencesJson']?.toString() ?? '').trim();
          _notesCtrl.text = (json['notes']?.toString() ?? '').trim();
          _hydrateGuidedFromJson(_prefsCtrl.text);
        }
      }
    } catch (_) {
      // ignore load errors
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    // Build preferences JSON from guided inputs
    final prefsMap = _buildPrefsMap();
    final prefs = jsonEncode(prefsMap);
    _prefsCtrl.text = prefs;
    _prefsError = null;

    setState(() => _loading = true);
    try {
      final client = AuthorizedHttpClient(_storage);
      final uri =
          Uri.parse('${_normalizeBaseUrl(apiBaseUrl)}/assistant/context');
      final body = jsonEncode({
        'preferencesJson': prefs,
        'notes': _notesCtrl.text.trim(),
      });
      final res = await client.post(uri,
          headers: {'Content-Type': 'application/json'}, body: body);
      if (res.statusCode >= 200 && res.statusCode < 300) {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Context saved')));
        Navigator.pop(context, true);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Save failed (${res.statusCode})')));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
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

  void _hydrateGuidedFromJson(String raw) {
    if (raw.isEmpty) return;
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      final focus =
          (m['focus'] as List<dynamic>?)?.map((e) => e.toString()).toSet() ??
              <String>{};
      final times = (m['preferredTimes'] as List<dynamic>?)
              ?.map((e) => e.toString().toLowerCase())
              .toSet() ??
          <String>{};
      final sleep = (m['sleepHours'] as num?)?.toDouble() ?? 7.0;
      final ex = (m['exerciseDaysPerWeek'] as num?)?.toInt() ?? 3;
      final rem = (m['reminders']?.toString().toUpperCase()) ?? 'WEEKLY';
      final tone = (m['tone']?.toString().toUpperCase()) ?? 'SUPPORTIVE';
      final goal = m['primaryGoal']?.toString() ?? '';
      setState(() {
        _focus
          ..clear()
          ..addAll(focus);
        _times
          ..clear()
          ..addAll(times);
        _sleepHours = sleep.clamp(4.0, 12.0);
        _exerciseDays = ex.clamp(0, 7);
        _reminders = (rem == 'DAILY' || rem == 'MONTHLY') ? rem : 'WEEKLY';
        _tone = (tone == 'COACHING' || tone == 'CONCISE') ? tone : 'SUPPORTIVE';
        _primaryGoalCtrl.text = goal;
      });
    } catch (_) {
      // ignore parse errors; keep defaults
    }
  }

  Map<String, dynamic> _buildPrefsMap() {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assistant Context'),
        actions: [
          TextButton.icon(
            onPressed: _loading ? null : _save,
            icon: _loading
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.save),
            label: const Text('Save'),
          )
        ],
      ),
      body: AbsorbPointer(
        absorbing: _loading,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('Primary goal',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            TextField(
              controller: _primaryGoalCtrl,
              decoration: const InputDecoration(
                hintText: 'e.g., Reduce stress and sleep better',
                border: OutlineInputBorder(),
              ),
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
                    selected: _focus.contains(f),
                    onSelected: (v) => setState(() {
                      v ? _focus.add(f) : _focus.remove(f);
                    }),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Habits', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Sleep hours: ${_sleepHours.round()}'),
                      Slider(
                        value: _sleepHours,
                        min: 4,
                        max: 12,
                        divisions: 8,
                        label: _sleepHours.round().toString(),
                        onChanged: (v) => setState(() => _sleepHours = v),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Exercise days/week: $_exerciseDays'),
                      Slider(
                        value: _exerciseDays.toDouble(),
                        min: 0,
                        max: 7,
                        divisions: 7,
                        label: _exerciseDays.toString(),
                        onChanged: (v) =>
                            setState(() => _exerciseDays = v.round()),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _reminders,
                    decoration:
                        const InputDecoration(labelText: 'Reminders cadence'),
                    items: const [
                      DropdownMenuItem(value: 'DAILY', child: Text('Daily')),
                      DropdownMenuItem(value: 'WEEKLY', child: Text('Weekly')),
                      DropdownMenuItem(
                          value: 'MONTHLY', child: Text('Monthly')),
                    ],
                    onChanged: (v) =>
                        setState(() => _reminders = v ?? 'WEEKLY'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _tone,
                    decoration:
                        const InputDecoration(labelText: 'Assistant style'),
                    items: const [
                      DropdownMenuItem(
                          value: 'SUPPORTIVE', child: Text('Supportive')),
                      DropdownMenuItem(
                          value: 'COACHING', child: Text('Coaching')),
                      DropdownMenuItem(
                          value: 'CONCISE', child: Text('Concise')),
                    ],
                    onChanged: (v) => setState(() => _tone = v ?? 'SUPPORTIVE'),
                  ),
                ),
              ],
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
                    selected: _times.contains(t),
                    onSelected: (v) => setState(() {
                      v ? _times.add(t) : _times.remove(t);
                    }),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Notes', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            TextField(
              controller: _notesCtrl,
              minLines: 4,
              maxLines: 10,
              decoration: const InputDecoration(
                hintText: 'Anything helpful to personalize suggestions…',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            // Advanced (raw JSON) optional
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Advanced JSON',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                Switch(
                    value: _showAdvanced,
                    onChanged: (v) => setState(() => _showAdvanced = v)),
              ],
            ),
            if (_showAdvanced) ...[
              const SizedBox(height: 6),
              TextField(
                controller: _prefsCtrl,
                minLines: 4,
                maxLines: 10,
                decoration: InputDecoration(
                  hintText:
                      '{ "focus": ["sleep", "stress"], "reminders": "weekly" }',
                  border: const OutlineInputBorder(),
                  errorText: _prefsError,
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => _hydrateGuidedFromJson(_prefsCtrl.text),
                  icon: const Icon(Icons.download),
                  label: const Text('Load into form'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
