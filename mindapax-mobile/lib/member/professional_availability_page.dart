import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../auth/jwt.dart';
import '../auth/token_storage.dart';
import '../dev/role_override.dart';
import '../professional/availability_api.dart';
import '../professional/models.dart';
import '../professional/professional_api.dart';
import 'member_scaffold.dart';

class ProfessionalAvailabilityPage extends StatefulWidget {
  const ProfessionalAvailabilityPage({super.key});

  @override
  State<ProfessionalAvailabilityPage> createState() =>
      _ProfessionalAvailabilityPageState();
}

class _ProfessionalAvailabilityPageState
    extends State<ProfessionalAvailabilityPage> {
  final _storage = TokenStorage();
  final _availabilityApi = AvailabilityApi();
  final _professionalApi = ProfessionalApi();

  bool _loading = true;
  bool _saving = false;
  bool _isProfessional = false;
  int? _professionalId;
  List<AvailabilitySlot> _slots = const [];
  DateTime _selectedDate = DateTime.now();
  String? _error;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      List<String> roles = [];
      final token = await _storage.getAccessToken();
      final payload = token != null ? decodeJwtPayload(token) : null;
      final rawRoles = payload?['roles'];
      if (rawRoles is List) {
        roles = rawRoles.map((e) => e.toString()).toList();
      } else if (rawRoles is String) {
        roles = rawRoles
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
      }
      if (RoleOverride.roles != null) {
        roles = RoleOverride.roles!;
      }
      roles = roles
          .map((r) => r.startsWith('ROLE_') ? r : 'ROLE_${r.toUpperCase()}')
          .toList();
      final isProfessional = roles.contains('ROLE_PROFESSIONAL');
      _isProfessional = isProfessional;
      if (!isProfessional) {
        return;
      }
      final me = await _professionalApi.getMe();
      _professionalId = me.id;
      await _loadSlots();
    } catch (e) {
      _error = 'Failed to load availability: $e';
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _loadSlots() async {
    if (_professionalId == null) return;
    try {
      final slots = await _availabilityApi.fetchSlots(_professionalId!);
      slots.sort((a, b) => a.startTime.compareTo(b.startTime));
      if (mounted) {
        setState(() {
          _slots = slots;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Failed to load availability: $e');
      }
    }
  }

  List<DateTime> get _daysWithSlots {
    final seen = <String>{};
    final days = <DateTime>[];
    for (final slot in _slots) {
      final dayKey = _keyForDate(slot.date);
      if (seen.add(dayKey)) {
        days.add(DateTime(slot.date.year, slot.date.month, slot.date.day));
      }
    }
    days.sort();
    return days;
  }

  List<AvailabilitySlot> get _slotsForSelected {
    return _slots
        .where((slot) => slot.isSameDay(_selectedDate))
        .toList(growable: false);
  }

  String _keyForDate(DateTime date) =>
      '${date.year}-${date.month}-${date.day}';

  Future<void> _openAddSlot() async {
    if (_professionalId == null) return;
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate.isBefore(now) ? now : _selectedDate,
      firstDate: now.subtract(const Duration(days: 0)),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date == null) return;

    final startPick = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
    );
    if (startPick == null) return;

    final endPick = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: (startPick.hour + 1).clamp(0, 23),
        minute: startPick.minute,
      ),
    );
    if (endPick == null) return;

    final start = DateTime(
        date.year, date.month, date.day, startPick.hour, startPick.minute);
    final end =
        DateTime(date.year, date.month, date.day, endPick.hour, endPick.minute);

    if (!end.isAfter(start)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('End time must be after the start time')));
      }
      return;
    }

    setState(() => _saving = true);
    try {
      await _availabilityApi.createSlot(
        professionalId: _professionalId!,
        date: date,
        startTime: start,
        endTime: end,
      );
      await _loadSlots();
      if (mounted) {
        setState(() => _selectedDate = date);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Availability saved')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save availability: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MemberScaffold(
      title: 'Availability',
      currentRoute: '/member/availability',
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : !_isProfessional
              ? _nonProfessionalView()
              : Column(
                  children: [
                    if (_saving)
                      const LinearProgressIndicator(minHeight: 2),
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: _errorBanner(_error!),
                      ),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _loadSlots,
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(16),
                          children: [
                            _calendarCard(),
                            const SizedBox(height: 12),
                            _slotsCard(),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _calendarCard() {
    final today = DateTime.now();
    final firstDate =
        DateTime(today.year, today.month, today.day).subtract(const Duration(days: 30));
    final lastDate = today.add(const Duration(days: 365));
    final days = _daysWithSlots;
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.event_available),
                const SizedBox(width: 8),
                Text(
                  'Availability calendar',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            CalendarDatePicker(
              initialDate: _selectedDate,
              firstDate: firstDate,
              lastDate: lastDate,
              currentDate: today,
              onDateChanged: (value) => setState(() => _selectedDate = value),
            ),
            if (days.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final day in days.take(8))
                    ChoiceChip(
                      label: Text(DateFormat('MMM d').format(day)),
                      selected: _isSameDay(day, _selectedDate),
                      onSelected: (_) => setState(() => _selectedDate = day),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _openAddSlot,
              icon: const Icon(Icons.add),
              label: const Text('Add availability'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _slotsCard() {
    final slots = _slotsForSelected;
    final dateLabel = DateFormat('EEEE, MMM d').format(_selectedDate);
    if (slots.isEmpty) {
      return Card(
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'No availability on $dateLabel',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                'Add a slot to allow clients to book this day.',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Theme.of(context).colorScheme.outline),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _openAddSlot,
                icon: const Icon(Icons.add),
                label: const Text('Add availability'),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Slots for $dateLabel',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            for (var i = 0; i < slots.length; i++) ...[
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading:
                    const Icon(Icons.schedule, color: Colors.indigoAccent),
                title: Text(_formatSlot(slots[i])),
              ),
              if (i != slots.length - 1)
                Divider(
                    color: Theme.of(context).colorScheme.outlineVariant,
                    height: 8),
            ],
          ],
        ),
      ),
    );
  }

  Widget _errorBanner(String message) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: scheme.onErrorContainer),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: scheme.onErrorContainer),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _nonProfessionalView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'Availability calendar is only available to professionals.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  String _formatSlot(AvailabilitySlot slot) {
    final timeRange =
        '${DateFormat('h:mm a').format(slot.startTime)} — ${DateFormat('h:mm a').format(slot.endTime)}';
    return timeRange;
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
