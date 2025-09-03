import 'package:flutter/material.dart';
import '../auth/token_storage.dart';
import '../auth/jwt.dart';
import '../sessions/models.dart';
import '../sessions/sessions_api.dart';
import '../user/user_api.dart';

class ScheduleSessionPage extends StatefulWidget {
  final SessionsApi? api;
  final UserApi? userApi;
  const ScheduleSessionPage({super.key, this.api, this.userApi});

  @override
  State<ScheduleSessionPage> createState() => _ScheduleSessionPageState();
}

class _ScheduleSessionPageState extends State<ScheduleSessionPage> {
  late final SessionsApi _api = widget.api ?? SessionsApi();
  late final UserApi _userApi = widget.userApi ?? UserApi();
  final _storage = TokenStorage();

  final _formKey = GlobalKey<FormState>();

  // Form state
  int? _selectedUserId; // required when PRO
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  int _durationMinutes = 30;
  SessionMode _mode = SessionMode.VIDEO;
  final _notesCtrl = TextEditingController();

  bool _loading = false;
  String? _error;
  List<UserBasic> _connectedUsers = const [];
  bool _isProfessional = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final token = await _storage.getAccessToken();
    final payload = token != null ? decodeJwtPayload(token) : null;
    List<String> roles = [];
    final raw = payload?['roles'];
    if (raw is List) {
      roles = raw.map((e) => e.toString()).toList();
    } else if (raw is String) {
      roles = raw
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    roles = roles
        .map((r) => r.startsWith('ROLE_') ? r : 'ROLE_${r.toUpperCase()}')
        .toList();
    _isProfessional = roles.contains('ROLE_PROFESSIONAL');
    if (_isProfessional) {
      await _loadConnectedUsers();
    }
    setState(() {});
  }

  Future<void> _loadConnectedUsers() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await _userApi.getConnectedUsers(page: 0, size: 50);
      setState(() => _connectedUsers = res);
    } catch (e) {
      setState(() => _error = 'Failed to load users: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (d != null) setState(() => _selectedDate = d);
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (t != null) setState(() => _selectedTime = t);
  }

  DateTime? _composeStartDateTimeLocal() {
    if (_selectedDate == null || _selectedTime == null) return null;
    final d = _selectedDate!;
    final t = _selectedTime!;
    return DateTime(d.year, d.month, d.day, t.hour, t.minute);
  }

  Future<void> _submit() async {
    setState(() {
      _error = null;
    });
    if (!_isProfessional) {
      setState(() {
        _error = 'Only professionals can schedule via mobile right now.';
      });
      return;
    }
    if (_selectedUserId == null) {
      setState(() => _error = 'Please select a client');
      return;
    }
    final localStart = _composeStartDateTimeLocal();
    if (localStart == null) {
      setState(() => _error = 'Please pick date and time');
      return;
    }
    if (_durationMinutes < 15) {
      setState(() => _error = 'Duration must be at least 15 minutes');
      return;
    }

    final startIsoUtc = (localStart.isUtc ? localStart : localStart.toUtc()).toIso8601String();

    setState(() => _loading = true);
    try {
      await _api.scheduleSessionByProfessional(
        userId: _selectedUserId!,
        startTimeIso: startIsoUtc,
        durationMinutes: _durationMinutes,
        mode: _mode,
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Session scheduled successfully')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      setState(() => _error = 'Failed to schedule: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Schedule Session')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(_error!, style: const TextStyle(color: Colors.red)),
                  ),
                if (_isProfessional) ...[
                  const Text('Client', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int>(
                    value: _selectedUserId,
                    items: _connectedUsers
                        .map((u) => DropdownMenuItem<int>(
                              value: u.id,
                              child: Text('${u.firstName} ${u.lastName}'),
                            ))
                        .toList(),
                    onChanged: _loading ? null : (v) => setState(() => _selectedUserId = v),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Select client',
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                const Text('Date & Time', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _loading ? null : _pickDate,
                        icon: const Icon(Icons.today),
                        label: Text(_selectedDate == null
                            ? 'Pick date'
                            : '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _loading ? null : _pickTime,
                        icon: const Icon(Icons.access_time),
                        label: Text(_selectedTime == null
                            ? 'Pick time'
                            : _selectedTime!.format(context)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('Duration (minutes)', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  value: _durationMinutes,
                  items: const [15, 30, 45, 60, 90]
                      .map((m) => DropdownMenuItem<int>(value: m, child: Text('$m')))
                      .toList(),
                  onChanged: _loading ? null : (v) => setState(() => _durationMinutes = v ?? 30),
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),
                const Text('Mode', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                DropdownButtonFormField<SessionMode>(
                  value: _mode,
                  items: SessionMode.values
                      .map((m) => DropdownMenuItem<SessionMode>(
                            value: m,
                            child: Text(sessionModeToString(m) ?? m.toString().split('.').last),
                          ))
                      .toList(),
                  onChanged: _loading ? null : (v) => setState(() => _mode = v ?? SessionMode.VIDEO),
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),
                const Text('Notes'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _notesCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Optional notes for the session',
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Schedule Session'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Using UserBasic from user_api.dart
