import 'package:flutter/material.dart';
import 'member_scaffold.dart';
import 'settings_prefs.dart';
import '../auth/authorized_client.dart';
import '../auth/token_storage.dart';
import '../env.dart';
import 'dart:convert';
import 'dart:io' show Platform;
import '../member/onboarding_prefs.dart';
import '../member/assistant_prefs.dart' as ap;
import '../member/notification_prefs.dart' as np;

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  SessionJoinMethod _method = SessionJoinMethod.zoomApp;
  bool _loading = true;
  // Assistant prefs
  bool _useContext = true;
  bool _includeProgress = true;
  bool _suggestGoals = true;
  final _storage = TokenStorage();
  // Notification prefs
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
    final m = await SettingsPrefs.getJoinMethod();
    // Load assistant prefs: local first
    final use = await ap.AssistantPrefs.getUseContext();
    final prog = await ap.AssistantPrefs.getIncludeProgress();
    final sug = await ap.AssistantPrefs.getSuggestGoals();
    // Load notification prefs
    final push = await np.NotificationPrefs.getPushEnabled();
    final goal = await np.NotificationPrefs.getGoalReminders();
    final sess = await np.NotificationPrefs.getSessionReminders();
    final msg = await np.NotificationPrefs.getMessageAlerts();
    final qEn = await np.NotificationPrefs.getQuietEnabled();
    final qStart = _parseHm(await np.NotificationPrefs.getQuietStart()) ?? const TimeOfDay(hour: 22, minute: 0);
    final qEnd = _parseHm(await np.NotificationPrefs.getQuietEnd()) ?? const TimeOfDay(hour: 7, minute: 0);
    if (!mounted) return;
    setState(() {
      _method = m;
      _useContext = use;
      _includeProgress = prog;
      _suggestGoals = sug;
      _pushEnabled = push;
      _goalReminders = goal;
      _sessionReminders = sess;
      _messageAlerts = msg;
      _quietEnabled = qEn;
      _quietStart = qStart;
      _quietEnd = qEnd;
    });
    // Try to fetch from server and reconcile
    try {
      final client = AuthorizedHttpClient(_storage);
      final uri = Uri.parse('${_normalizeBaseUrl(apiBaseUrl)}/assistant/prefs');
      final res = await client.get(uri);
      if (res.statusCode >= 200 && res.statusCode < 300 && res.body.isNotEmpty) {
        final mm = jsonDecode(res.body) as Map<String, dynamic>;
        final sUse = mm['useContext'] == true;
        final sProg = mm['includeProgress'] == true;
        final sSug = mm['suggestGoals'] == true;
        if (mounted) {
          setState(() {
            _useContext = sUse;
            _includeProgress = sProg;
            _suggestGoals = sSug;
          });
        }
        await ap.AssistantPrefs.setUseContext(sUse);
        await ap.AssistantPrefs.setIncludeProgress(sProg);
        await ap.AssistantPrefs.setSuggestGoals(sSug);
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
              children: [
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
                if (_quietEnabled)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final picked = await showTimePicker(context: context, initialTime: _quietStart);
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
                              final picked = await showTimePicker(context: context, initialTime: _quietEnd);
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
                        onPressed: () => Navigator.pushNamed(context, '/member/assistant-context'),
                        icon: const Icon(Icons.tune),
                        label: const Text('Manage context'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => Navigator.pushNamed(context, '/member/onboarding'),
                        icon: const Icon(Icons.play_circle_outline),
                        label: const Text('Start onboarding now'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () async {
                          await OnboardingPrefs.setCompleted(false);
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Onboarding will show next sign-in')),
                          );
                        },
                        icon: const Icon(Icons.restart_alt),
                        label: const Text('Reset onboarding'),
                      ),
                    ],
                  ),
                 ),
                const Divider(height: 32),
                const ListTile(
                  title: Text('Sessions'),
                  subtitle: Text('Choose how to join your video sessions'),
                ),
                RadioListTile<SessionJoinMethod>(
                  value: SessionJoinMethod.zoomApp,
                  groupValue: _method,
                  onChanged: (v) => v != null ? _update(v) : null,
                  title: const Text('Open in Zoom app (default)'),
                  subtitle: const Text('Launch the native Zoom app when joining a video session'),
                ),
                RadioListTile<SessionJoinMethod>(
                  value: SessionJoinMethod.webView,
                  groupValue: _method,
                  onChanged: (v) => v != null ? _update(v) : null,
                  title: const Text('Open inside app (WebView)'),
                  subtitle: const Text('Use in-app browser to run the Zoom Web SDK'),
                ),
             ],
            ),
    );
  }

  Future<void> _saveAssistantPrefs() async {
    try {
      final client = AuthorizedHttpClient(_storage);
      final uri = Uri.parse('${_normalizeBaseUrl(apiBaseUrl)}/assistant/prefs');
      final body = jsonEncode({
        'useContext': _useContext,
        'includeProgress': _includeProgress,
        'suggestGoals': _suggestGoals,
      });
      await client.post(uri, headers: {'Content-Type': 'application/json'}, body: body);
    } catch (_) {}
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

  // Helpers for HH:MM formatting and parsing
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
}
