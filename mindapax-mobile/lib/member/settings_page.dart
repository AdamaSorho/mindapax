import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/material.dart';

import '../auth/authorized_client.dart';
import '../auth/jwt.dart';
import '../auth/token_storage.dart';
import '../env.dart';
import '../member/assistant_prefs.dart' as ap;
import '../member/notification_prefs.dart' as np;
import '../member/onboarding_prefs.dart';
import 'member_scaffold.dart';
import 'settings_prefs.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _storage = TokenStorage();

  SessionJoinMethod _method = SessionJoinMethod.zoomApp;
  bool _loading = true;
  bool _isProfessional = false;

  bool _useContext = true;
  bool _includeProgress = true;
  bool _suggestGoals = true;

  bool _pushEnabled = true;
  bool _goalReminders = true;
  bool _sessionReminders = true;
  bool _messageAlerts = true;
  bool _quietEnabled = false;
  TimeOfDay _quietStart = const TimeOfDay(hour: 22, minute: 0);
  TimeOfDay _quietEnd = const TimeOfDay(hour: 7, minute: 0);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final token = await _storage.getAccessToken();
    final payload = token != null ? decodeJwtPayload(token) : null;
    final roles = _extractRoles(payload?['roles']);
    final isProfessional = roles.contains('ROLE_PROFESSIONAL');

    final joinMethod = await SettingsPrefs.getJoinMethod();
    final useContext = await ap.AssistantPrefs.getUseContext();
    final includeProgress = await ap.AssistantPrefs.getIncludeProgress();
    final suggestGoals = await ap.AssistantPrefs.getSuggestGoals();
    final push = await np.NotificationPrefs.getPushEnabled();
    final goal = await np.NotificationPrefs.getGoalReminders();
    final sess = await np.NotificationPrefs.getSessionReminders();
    final msg = await np.NotificationPrefs.getMessageAlerts();
    final quietEnabled = await np.NotificationPrefs.getQuietEnabled();
    final quietStart = _parseHm(await np.NotificationPrefs.getQuietStart()) ??
        const TimeOfDay(hour: 22, minute: 0);
    final quietEnd = _parseHm(await np.NotificationPrefs.getQuietEnd()) ??
        const TimeOfDay(hour: 7, minute: 0);

    if (!mounted) return;
    setState(() {
      _isProfessional = isProfessional;
      _method = joinMethod;
      _useContext = useContext;
      _includeProgress = includeProgress;
      _suggestGoals = suggestGoals;
      _pushEnabled = push;
      _goalReminders = goal;
      _sessionReminders = sess;
      _messageAlerts = msg;
      _quietEnabled = quietEnabled;
      _quietStart = quietStart;
      _quietEnd = quietEnd;
    });

    try {
      final client = AuthorizedHttpClient(_storage);
      final uri = Uri.parse('${_normalizeBaseUrl(apiBaseUrl)}/assistant/prefs');
      final res = await client.get(uri);
      if (res.statusCode >= 200 &&
          res.statusCode < 300 &&
          res.body.isNotEmpty) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        final remoteUse = body['useContext'] == true;
        final remoteProgress = body['includeProgress'] == true;
        final remoteSuggest = body['suggestGoals'] == true;
        if (mounted) {
          setState(() {
            _useContext = remoteUse;
            _includeProgress = remoteProgress;
            _suggestGoals = remoteSuggest;
          });
        }
        await ap.AssistantPrefs.setUseContext(remoteUse);
        await ap.AssistantPrefs.setIncludeProgress(remoteProgress);
        await ap.AssistantPrefs.setSuggestGoals(remoteSuggest);
      }
    } catch (_) {}

    if (mounted) setState(() => _loading = false);
  }

  Future<void> _update(SessionJoinMethod value) async {
    setState(() => _method = value);
    await SettingsPrefs.setJoinMethod(value);
  }

  @override
  Widget build(BuildContext context) {
    return MemberScaffold(
      title: 'Settings',
      currentRoute: '/member/settings',
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(12),
              children: _buildContent(),
            ),
    );
  }

  List<Widget> _buildContent() {
    final widgets = <Widget>[
      const ListTile(
        title: Text('Notifications'),
        subtitle: Text('Push, reminders, and quiet hours'),
      ),
      SwitchListTile(
        title: const Text('Push notifications'),
        value: _pushEnabled,
        onChanged: (v) async {
          setState(() => _pushEnabled = v);
          await np.NotificationPrefs.setPushEnabled(v);
        },
      ),
      if (!_isProfessional)
        SwitchListTile(
          title: const Text('Goal reminders'),
          value: _goalReminders,
          onChanged: (v) async {
            setState(() => _goalReminders = v);
            await np.NotificationPrefs.setGoalReminders(v);
          },
        ),
      SwitchListTile(
        title: const Text('Session reminders'),
        value: _sessionReminders,
        onChanged: (v) async {
          setState(() => _sessionReminders = v);
          await np.NotificationPrefs.setSessionReminders(v);
        },
      ),
      SwitchListTile(
        title: const Text('Message alerts'),
        value: _messageAlerts,
        onChanged: (v) async {
          setState(() => _messageAlerts = v);
          await np.NotificationPrefs.setMessageAlerts(v);
        },
      ),
      SwitchListTile(
        title: const Text('Quiet hours'),
        subtitle: Text('${_fmtTime(_quietStart)} – ${_fmtTime(_quietEnd)}'),
        value: _quietEnabled,
        onChanged: (v) async {
          setState(() => _quietEnabled = v);
          await np.NotificationPrefs.setQuietEnabled(v);
        },
      ),
    ];

    if (_quietEnabled) {
      widgets.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await showTimePicker(
                        context: context, initialTime: _quietStart);
                    if (picked != null) {
                      setState(() => _quietStart = picked);
                      await np.NotificationPrefs.setQuietStart(_toHm(picked));
                    }
                  },
                  icon: const Icon(Icons.schedule),
                  label: Text('Start ${_fmtTime(_quietStart)}'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await showTimePicker(
                        context: context, initialTime: _quietEnd);
                    if (picked != null) {
                      setState(() => _quietEnd = picked);
                      await np.NotificationPrefs.setQuietEnd(_toHm(picked));
                    }
                  },
                  icon: const Icon(Icons.schedule_outlined),
                  label: Text('End ${_fmtTime(_quietEnd)}'),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_isProfessional) {
      widgets.addAll(_professionalPracticeNotes());
    } else {
      widgets.addAll(_memberAssistantSettings());
    }

    widgets.add(const Divider(height: 32));
    widgets.add(ListTile(
      title: Text(_isProfessional ? 'Session join method' : 'Sessions'),
      subtitle: Text(_isProfessional
          ? 'Choose how you join client video sessions'
          : 'Choose how to join your video sessions'),
    ));
    widgets.addAll([
      RadioListTile<SessionJoinMethod>(
        value: SessionJoinMethod.zoomApp,
        groupValue: _method,
        onChanged: (v) => v != null ? _update(v) : null,
        title: const Text('Open in Zoom app (default)'),
        subtitle: const Text(
            'Launch the native Zoom app when joining a video session'),
      ),
      RadioListTile<SessionJoinMethod>(
        value: SessionJoinMethod.webView,
        groupValue: _method,
        onChanged: (v) => v != null ? _update(v) : null,
        title: const Text('Open inside app (WebView)'),
        subtitle: const Text('Use in-app browser to run the Zoom Web SDK'),
      ),
    ]);
    return widgets;
  }

  List<Widget> _memberAssistantSettings() {
    return [
      const Divider(height: 32),
      const ListTile(
        title: Text('Assistant'),
        subtitle: Text('Control AI personalization and suggestions'),
      ),
      SwitchListTile(
        title: const Text('Use my context'),
        subtitle: const Text('Personalize suggestions with your preferences'),
        value: _useContext,
        onChanged: (v) async {
          setState(() => _useContext = v);
          await ap.AssistantPrefs.setUseContext(v);
          _saveAssistantPrefs();
        },
      ),
      SwitchListTile(
        title: const Text('Include my progress'),
        subtitle: const Text('Factor in your goal progress when suggesting'),
        value: _includeProgress,
        onChanged: (v) async {
          setState(() => _includeProgress = v);
          await ap.AssistantPrefs.setIncludeProgress(v);
          _saveAssistantPrefs();
        },
      ),
      SwitchListTile(
        title: const Text('Suggest goals for me'),
        value: _suggestGoals,
        onChanged: (v) async {
          setState(() => _suggestGoals = v);
          await ap.AssistantPrefs.setSuggestGoals(v);
          _saveAssistantPrefs();
        },
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Wrap(
          spacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: () =>
                  Navigator.pushNamed(context, '/member/assistant-context'),
              icon: const Icon(Icons.tune),
              label: const Text('Manage context'),
            ),
            OutlinedButton.icon(
              onPressed: () =>
                  Navigator.pushNamed(context, '/member/onboarding'),
              icon: const Icon(Icons.play_circle_outline),
              label: const Text('Start onboarding now'),
            ),
            OutlinedButton.icon(
              onPressed: () async {
                await OnboardingPrefs.setCompleted(false);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Onboarding will show next sign-in')),
                );
              },
              icon: const Icon(Icons.restart_alt),
              label: const Text('Reset onboarding'),
            ),
          ],
        ),
      ),
    ];
  }

  List<Widget> _professionalPracticeNotes() {
    final scheme = Theme.of(context).colorScheme;
    return [
      const SizedBox(height: 16),
      Card(
        elevation: 0,
        color: scheme.surfaceContainerHighest,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Practice settings',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text(
                'Manage how you receive session reminders and client notifications. '
                'Member onboarding and assistant personalization are hidden for professional accounts.',
                style: TextStyle(color: scheme.onSurfaceVariant, height: 1.3),
              ),
            ],
          ),
        ),
      ),
    ];
  }

  Future<void> _saveAssistantPrefs() async {
    if (_isProfessional) return;
    try {
      final client = AuthorizedHttpClient(_storage);
      final uri = Uri.parse('${_normalizeBaseUrl(apiBaseUrl)}/assistant/prefs');
      final body = jsonEncode({
        'useContext': _useContext,
        'includeProgress': _includeProgress,
        'suggestGoals': _suggestGoals,
      });
      await client.post(uri,
          headers: {'Content-Type': 'application/json'}, body: body);
    } catch (_) {}
  }

  String _normalizeBaseUrl(String value) {
    final cleaned = value.replaceAll(RegExp(r'/+$'), '');
    try {
      final uri = Uri.parse(cleaned);
      if (uri.host == 'localhost' && Platform.isAndroid) {
        return cleaned.replaceFirst('localhost', '10.0.2.2');
      }
    } catch (_) {}
    return cleaned;
  }

  String _fmtTime(TimeOfDay t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _toHm(TimeOfDay t) => _fmtTime(t);

  TimeOfDay? _parseHm(String s) {
    final parts = s.split(':');
    if (parts.length != 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return TimeOfDay(hour: h.clamp(0, 23), minute: m.clamp(0, 59));
  }

  List<String> _extractRoles(dynamic raw) {
    if (raw is List) {
      return raw
          .map((e) => e.toString())
          .where((e) => e.isNotEmpty)
          .map((r) => r.startsWith('ROLE_') ? r : 'ROLE_${r.toUpperCase()}')
          .toList(growable: false);
    }
    if (raw is String) {
      return raw
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .map((r) => r.startsWith('ROLE_') ? r : 'ROLE_${r.toUpperCase()}')
          .toList(growable: false);
    }
    return const [];
  }
}
