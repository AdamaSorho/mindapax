import 'package:flutter/material.dart';
import 'member_scaffold.dart';
import 'settings_prefs.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  SessionJoinMethod _method = SessionJoinMethod.zoomApp;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final m = await SettingsPrefs.getJoinMethod();
    if (!mounted) return;
    setState(() {
      _method = m;
      _loading = false;
    });
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
}

