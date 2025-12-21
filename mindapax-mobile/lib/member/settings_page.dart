import 'dart:convert';
import 'dart:io' show File, Platform;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:local_auth/local_auth.dart';

import '../auth/authorized_client.dart';
import '../auth/biometric_auth.dart';
import '../auth/biometric_prefs.dart';
import '../auth/jwt.dart';
import '../auth/token_storage.dart';
import '../env.dart';
import '../member/assistant_prefs.dart' as ap;
import '../member/notification_prefs.dart' as np;
import '../member/onboarding_prefs.dart';
import '../user/user_api.dart';
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

  bool _biometricSupported = false;
  bool _biometricEnrolled = false;
  bool _biometricEnabled = false;
  bool _biometricLoading = false;
  List<BiometricType> _availableBiometrics = const [];

  bool _twoFactorEnabled = false;
  bool _twoFactorLoading = false;

  final _userApi = UserApi();
  final ImagePicker _imagePicker = ImagePicker();

  final TextEditingController _firstNameCtrl = TextEditingController();
  final TextEditingController _lastNameCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();
  final TextEditingController _locationCtrl = TextEditingController();

  String? _email;
  String? _avatarUrl;
  File? _avatarFile;
  bool _removeAvatar = false;
  bool _profileSaving = false;
  int? _userId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _phoneCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final token = await _storage.getAccessToken();
    final payload = token != null ? decodeJwtPayload(token) : null;
    final roles = _extractRoles(payload?['roles']);
    final isProfessional = roles.contains('ROLE_PROFESSIONAL');
    final userId = (payload?['id'] as num?)?.toInt();
    final email = payload?['sub']?.toString();

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
      _userId = userId;
      _email = email ?? _email;
    });

    final client = AuthorizedHttpClient(_storage);

    try {
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

    await _loadProfile(userId);

    await _fetchTwoFactorStatus(client);
    await _refreshBiometricState();

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
    final widgets = <Widget>[];
    widgets.addAll(_profileSection());
    widgets.add(const Divider(height: 32));
    widgets.add(const ListTile(
      title: Text('Notifications'),
      subtitle: Text('Push, reminders, and quiet hours'),
    ));
    widgets.addAll([
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
    ]);
    widgets.add(const Divider(height: 32));
    widgets.add(const ListTile(
      title: Text('Security'),
      subtitle: Text('Add extra protection to your account'),
    ));
    widgets.add(
      Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(
                _biometricEnabled
                    ? Icons.lock_open_rounded
                    : Icons.lock_outline,
                color: _biometricEnabled
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quick unlock',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _biometricStatusMessage(),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              _biometricLoading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : TextButton(
                      onPressed: !_biometricSupported
                          ? null
                          : _biometricEnabled
                              ? _disableBiometrics
                              : _enableBiometrics,
                      child: Text(_biometricEnabled ? 'Disable' : 'Enable'),
                    ),
            ],
          ),
        ),
      ),
    );

    widgets.add(const SizedBox(height: 12));
    widgets.add(
      Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(
                _twoFactorEnabled
                    ? Icons.verified_user
                    : Icons.verified_user_outlined,
                color: _twoFactorEnabled
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _twoFactorEnabled
                          ? 'Two-factor authentication is on'
                          : 'Two-factor authentication is off',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _twoFactorEnabled
                          ? 'Logging in requires a code from your authenticator app.'
                          : 'Use an authenticator app for an extra verification step at sign-in.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              _twoFactorLoading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : TextButton(
                      onPressed: _twoFactorEnabled
                          ? _promptDisableTwoFactor
                          : _beginTwoFactorSetup,
                      child: Text(_twoFactorEnabled ? 'Disable' : 'Enable'),
                    ),
            ],
          ),
        ),
      ),
    );

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
        // ignore: deprecated_member_use
        groupValue: _method,
        // ignore: deprecated_member_use
        onChanged: (v) => v != null ? _update(v) : null,
        title: const Text('Open in Zoom app (default)'),
        subtitle: const Text(
            'Launch the native Zoom app when joining a video session'),
      ),
      RadioListTile<SessionJoinMethod>(
        value: SessionJoinMethod.webView,
        // ignore: deprecated_member_use
        groupValue: _method,
        // ignore: deprecated_member_use
        onChanged: (v) => v != null ? _update(v) : null,
        title: const Text('Open inside app (WebView)'),
        subtitle: const Text('Use in-app browser to run the Zoom Web SDK'),
      ),
    ]);
    return widgets;
  }

  List<Widget> _profileSection() {
    final theme = Theme.of(context);
    final image = _avatarImageProvider();
    final hasAvatar = image != null;
    final initials = _profileInitials();

    return [
      const ListTile(
        title: Text('Profile'),
        subtitle: Text('Update your personal information'),
      ),
      Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 44,
            backgroundImage: image,
            backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.15),
            child: image == null
                ? Text(
                    initials,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextButton.icon(
                  onPressed: _profileSaving ? null : _pickAvatar,
                  icon: const Icon(Icons.photo_camera_outlined),
                  label: const Text('Change photo'),
                ),
                if (hasAvatar)
                  TextButton.icon(
                    onPressed: _profileSaving ? null : _removeAvatarLocally,
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Remove photo'),
                  ),
              ],
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),
      TextField(
        controller: _firstNameCtrl,
        decoration: const InputDecoration(labelText: 'First name'),
        textInputAction: TextInputAction.next,
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _lastNameCtrl,
        decoration: const InputDecoration(labelText: 'Last name'),
        textInputAction: TextInputAction.next,
      ),
      const SizedBox(height: 12),
      ListTile(
        contentPadding: EdgeInsets.zero,
        title: const Text('Email'),
        subtitle: Text(_email ?? '—'),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _phoneCtrl,
        decoration: const InputDecoration(labelText: 'Phone'),
        keyboardType: TextInputType.phone,
        textInputAction: TextInputAction.next,
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _locationCtrl,
        decoration: const InputDecoration(labelText: 'Location'),
        textInputAction: TextInputAction.done,
      ),
      const SizedBox(height: 16),
      FilledButton.icon(
        onPressed: _profileSaving ? null : _saveProfile,
        icon: _profileSaving
            ? const SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.save_outlined),
        label: Text(_profileSaving ? 'Saving…' : 'Save profile'),
      ),
    ];
  }

  ImageProvider<Object>? _avatarImageProvider() {
    if (_avatarFile != null) {
      return FileImage(_avatarFile!);
    }
    final value = _avatarUrl;
    if (value == null || value.isEmpty) return null;
    return NetworkImage(_resolveAvatarUrl(value));
  }

  String _profileInitials() {
    final first = _firstNameCtrl.text.trim();
    final last = _lastNameCtrl.text.trim();
    if (first.isNotEmpty && last.isNotEmpty) {
      return '${first[0]}${last[0]}'.toUpperCase();
    }
    if (first.isNotEmpty) return first[0].toUpperCase();
    if (last.isNotEmpty) return last[0].toUpperCase();
    if (_email != null && _email!.isNotEmpty) return _email![0].toUpperCase();
    return 'U';
  }

  static const int _maxAvatarBytes = 2 * 1024 * 1024; // 2MB
  static const String _maxAvatarLabel = '2 MB';

  Future<void> _pickAvatar() async {
    try {
      final picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (picked == null) return;
      final file = File(picked.path);
      final size = await file.length();
      if (size > _maxAvatarBytes) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Avatar is too large. Max allowed is $_maxAvatarLabel.'),
          ),
        );
        return;
      }
      setState(() {
        _avatarFile = file;
        _removeAvatar = false;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not select image: $e')),
      );
    }
  }

  void _removeAvatarLocally() {
    setState(() {
      _avatarFile = null;
      _avatarUrl = null;
      _removeAvatar = true;
    });
  }

  Future<void> _saveProfile() async {
    if (_userId == null) return;
    setState(() => _profileSaving = true);
    try {
      final first = _firstNameCtrl.text.trim();
      final last = _lastNameCtrl.text.trim();
      final phone = _phoneCtrl.text.trim();
      final location = _locationCtrl.text.trim();
      final response = await _userApi.updateProfile(
        id: _userId!,
        firstName: first.isEmpty ? null : first,
        lastName: last.isEmpty ? null : last,
        phone: phone.isEmpty ? null : phone,
        location: location.isEmpty ? null : location,
        avatarFile: _avatarFile,
        removeAvatar: _removeAvatar,
      );
      _firstNameCtrl.text = response['firstName']?.toString() ?? first;
      _lastNameCtrl.text = response['lastName']?.toString() ?? last;
      final updatedPhone = response['phone']?.toString() ?? '';
      _phoneCtrl.text = updatedPhone;
      final updatedLocation = response['location']?.toString() ?? '';
      _locationCtrl.text = updatedLocation;
      final newEmail = response['email']?.toString();
      final avatar = response['avatarUrl']?.toString();
      if (!mounted) return;
      setState(() {
        _email = newEmail ?? _email;
        _avatarUrl = (avatar != null && avatar.isNotEmpty) ? avatar : null;
        _avatarFile = null;
        _removeAvatar = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update profile: $e')),
      );
    } finally {
      if (mounted) setState(() => _profileSaving = false);
    }
  }

  Future<void> _loadProfile(int? userId) async {
    if (userId == null) return;
    try {
      final data = await _userApi.getUserById(userId);
      final first = data['firstName']?.toString() ?? '';
      final last = data['lastName']?.toString() ?? '';
      final phone = data['phone']?.toString() ?? '';
      final location = data['location']?.toString() ?? '';
      final email = data['email']?.toString();
      final avatar = data['avatarUrl']?.toString();
      _firstNameCtrl.text = first;
      _lastNameCtrl.text = last;
      _phoneCtrl.text = phone;
      _locationCtrl.text = location;
      if (!mounted) return;
      setState(() {
        _email = email ?? _email;
        _avatarUrl = (avatar != null && avatar.isNotEmpty) ? avatar : null;
        _avatarFile = null;
        _removeAvatar = false;
      });
    } catch (_) {}
  }

  String _resolveAvatarUrl(String value) {
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return value;
    }
    if (value.startsWith('/')) {
      return '${_normalizeBaseUrl(apiBaseUrl)}$value';
    }
    return '${_normalizeBaseUrl(apiBaseUrl)}/$value';
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

  Future<void> _fetchTwoFactorStatus(AuthorizedHttpClient client) async {
    try {
      final uri = Uri.parse('${_normalizeBaseUrl(apiBaseUrl)}/auth/2fa/status');
      final res = await client.get(uri);
      if (res.statusCode >= 200 &&
          res.statusCode < 300 &&
          res.body.isNotEmpty) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        if (mounted) {
          setState(() {
            _twoFactorEnabled = body['enabled'] == true;
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _refreshBiometricState() async {
    final supported = await BiometricAuth.isSupported();
    final available = supported
        ? await BiometricAuth.getAvailableBiometrics()
        : const <BiometricType>[];
    final enrolled = supported &&
        available.isNotEmpty &&
        await BiometricAuth.canCheckBiometrics();
    var enabledPreference = await BiometricPrefs.isEnabled();
    if (!enrolled && enabledPreference) {
      await BiometricPrefs.setEnabled(false);
      enabledPreference = false;
    }
    if (!mounted) return;
    setState(() {
      _biometricSupported = supported;
      _biometricEnrolled = enrolled;
      _availableBiometrics = available;
      _biometricEnabled = enabledPreference && enrolled;
    });
  }

  Future<void> _enableBiometrics() async {
    if (_biometricLoading) return;
    if (!_biometricSupported) {
      _showSnack('Biometric unlock is not available on this device.');
      return;
    }
    if (!_biometricEnrolled) {
      _showSnack(
          'Set up Face ID or fingerprint in your device settings first.');
      return;
    }
    setState(() => _biometricLoading = true);
    final success = await BiometricAuth.authenticate(
      reason: 'Authenticate to enable quick unlock',
    );
    if (!mounted) return;
    if (success) {
      await BiometricPrefs.setEnabled(true);
      await _storage.setRemembered(true);
      await _refreshBiometricState();
      _showSnack('Quick unlock enabled.');
    } else {
      final reason = BiometricAuth.lastError;
      _showSnack(reason == null || reason.trim().isEmpty
          ? 'Biometric authentication was cancelled.'
          : reason.trim());
    }
    if (mounted) setState(() => _biometricLoading = false);
  }

  Future<void> _disableBiometrics() async {
    if (_biometricLoading) return;
    setState(() => _biometricLoading = true);
    final confirmed = await BiometricAuth.authenticate(
      reason: 'Confirm to disable quick unlock',
    );
    if (!mounted) return;
    if (confirmed) {
      await BiometricPrefs.setEnabled(false);
      await _storage.setRemembered(false);
      await _refreshBiometricState();
      _showSnack('Quick unlock disabled.');
    } else {
      final reason = BiometricAuth.lastError;
      _showSnack(reason == null || reason.trim().isEmpty
          ? 'Biometric authentication was cancelled.'
          : reason.trim());
    }
    if (mounted) setState(() => _biometricLoading = false);
  }

  String _biometricStatusMessage() {
    if (!_biometricSupported) {
      return 'Biometric unlock is not supported on this device.';
    }
    if (!_biometricEnrolled) {
      return 'Set up Face ID or fingerprint in your device settings to enable quick unlock.';
    }
    final label = _biometricMethodLabel();
    if (_biometricEnabled) {
      return 'Use $label to unlock the app quickly.';
    }
    return 'Enable $label to unlock your account without entering your password.';
  }

  String _biometricMethodLabel() {
    final types = _availableBiometrics.toSet();
    if (types.contains(BiometricType.face)) {
      return 'Face ID';
    }
    if (types.contains(BiometricType.fingerprint)) {
      return 'your fingerprint';
    }
    if (types.contains(BiometricType.iris)) {
      return 'your device biometrics';
    }
    if (types.contains(BiometricType.strong)) {
      return 'your device biometrics';
    }
    return 'biometrics';
  }

  Future<void> _beginTwoFactorSetup() async {
    setState(() => _twoFactorLoading = true);
    final client = AuthorizedHttpClient(_storage);
    try {
      final uri = Uri.parse('${_normalizeBaseUrl(apiBaseUrl)}/auth/2fa/setup');
      final res = await client.post(uri);
      if (res.statusCode < 200 || res.statusCode >= 300) {
        throw Exception(_readErrorBody(res.body));
      }
      final payload = jsonDecode(res.body) as Map<String, dynamic>;
      if (!mounted) return;
      setState(() => _twoFactorLoading = false);
      await _showTwoFactorSetupSheet(
        secret: payload['secret'] as String? ?? '',
        otpauthUrl: payload['otpauthUrl'] as String? ?? '',
      );
      final code = await _requestTwoFactorCode(
        title: 'Verify two-factor authentication',
        description:
            'Enter the 6-digit code from your authenticator app to finish setup.',
      );
      if (code != null) {
        await _completeEnableTwoFactor(code);
      }
    } catch (e) {
      if (!mounted) return;
      _showSnack('Unable to start two-factor setup: ${_friendlyError(e)}');
      setState(() => _twoFactorLoading = false);
    } finally {
      if (mounted) {
        setState(() => _twoFactorLoading = false);
      }
    }
  }

  Future<void> _completeEnableTwoFactor(String code) async {
    setState(() => _twoFactorLoading = true);
    final client = AuthorizedHttpClient(_storage);
    try {
      final uri = Uri.parse('${_normalizeBaseUrl(apiBaseUrl)}/auth/2fa/enable');
      final res = await client.post(uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'code': code}));
      if (res.statusCode >= 200 && res.statusCode < 300) {
        await _fetchTwoFactorStatus(client);
        if (mounted) {
          _showSnack('Two-factor authentication enabled.');
        }
      } else {
        throw Exception(_readErrorBody(res.body));
      }
    } catch (e) {
      if (mounted) {
        _showSnack(
            'Could not enable two-factor authentication: ${_friendlyError(e)}');
      }
    } finally {
      if (mounted) {
        setState(() => _twoFactorLoading = false);
      }
    }
  }

  Future<void> _promptDisableTwoFactor() async {
    final code = await _requestTwoFactorCode(
      title: 'Disable two-factor authentication',
      description:
          'Enter the 6-digit code from your authenticator app to disable protection.',
    );
    if (code == null) return;
    await _disableTwoFactor(code);
  }

  Future<void> _disableTwoFactor(String code) async {
    setState(() => _twoFactorLoading = true);
    final client = AuthorizedHttpClient(_storage);
    try {
      final uri =
          Uri.parse('${_normalizeBaseUrl(apiBaseUrl)}/auth/2fa/disable');
      final res = await client.post(uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'code': code}));
      if (res.statusCode >= 200 && res.statusCode < 300) {
        await _fetchTwoFactorStatus(client);
        if (mounted) {
          _showSnack('Two-factor authentication disabled.');
        }
      } else {
        throw Exception(_readErrorBody(res.body));
      }
    } catch (e) {
      if (mounted) {
        _showSnack(
            'Could not disable two-factor authentication: ${_friendlyError(e)}');
      }
    } finally {
      if (mounted) {
        setState(() => _twoFactorLoading = false);
      }
    }
  }

  Future<void> _showTwoFactorSetupSheet(
      {required String secret, required String otpauthUrl}) async {
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            24,
            24,
            24 + MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Set up two-factor authentication',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Text(
                'Add Mindapax to your authenticator app using the secret below. '
                'After scanning or entering it manually, return here to verify the setup.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              _TwoFactorValueTile(
                label: 'Secret key',
                value: secret,
                onCopy: () => _copyToClipboard(secret, 'Secret key copied'),
              ),
              const SizedBox(height: 12),
              _TwoFactorValueTile(
                label: 'otpauth URL',
                value: otpauthUrl,
                onCopy: () => _copyToClipboard(otpauthUrl, 'Setup URL copied'),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('I\'m ready to verify'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<String?> _requestTwoFactorCode({
    required String title,
    required String description,
  }) async {
    if (!mounted) return null;
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) {
        String? error;
        return StatefulBuilder(
          builder: (ctx, setState) => AlertDialog(
            title: Text(title),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(description),
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: 'Two-factor code',
                    counterText: '',
                    errorText: error,
                  ),
                  onChanged: (_) => setState(() => error = null),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  final value = controller.text.trim();
                  if (value.length != 6) {
                    setState(() => error = 'Enter the 6-digit code');
                    return;
                  }
                  Navigator.of(ctx).pop(value);
                },
                child: const Text('Confirm'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _copyToClipboard(String value, String message) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!mounted) return;
    _showSnack(message);
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String _friendlyError(Object error) {
    final text = error.toString();
    return text.replaceFirst('Exception: ', '');
  }

  String _readErrorBody(String body) {
    if (body.isEmpty) return 'Request failed';
    try {
      final map = jsonDecode(body) as Map<String, dynamic>;
      return (map['message'] ?? map['error'] ?? body).toString();
    } catch (_) {
      return body;
    }
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

class _TwoFactorValueTile extends StatelessWidget {
  const _TwoFactorValueTile({
    required this.label,
    required this.value,
    required this.onCopy,
  });

  final String label;
  final String value;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 6),
          SelectableText(
            value,
            style:
                theme.textTheme.titleSmall?.copyWith(fontFamily: 'monospace'),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onCopy,
              icon: const Icon(Icons.copy, size: 18),
              label: const Text('Copy'),
            ),
          )
        ],
      ),
    );
  }
}
