import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'member_scaffold.dart';
import '../professional/professional_api.dart';
import '../professional/models.dart';

class FindProfessionalPage extends StatefulWidget {
  const FindProfessionalPage({super.key});

  @override
  State<FindProfessionalPage> createState() => _FindProfessionalPageState();
}

class _FindProfessionalPageState extends State<FindProfessionalPage> {
  final _api = ProfessionalApi();

  final _searchController = TextEditingController();
  Specialization? _specialization;
  int? _experience;
  DateTime? _availabilityDate;

  bool _loading = false;
  String? _error;
  List<Professional> _items = const [];
  int _page = 0;
  int _totalPages = 0;

  @override
  void initState() {
    super.initState();
    _fetch(resetPage: true);
  }

  Future<void> _fetch({bool resetPage = false}) async {
    setState(() {
      _loading = true;
      _error = null;
      if (resetPage) _page = 0;
    });
    try {
      final dateFilter = _availabilityDate?.toIso8601String().split('T').first;
      final filters = ProfessionalFilterParams(
        firstName: _searchController.text.trim().isEmpty
            ? null
            : _searchController.text.trim(),
        specialization: _specialization,
        experience: _experience,
        availabilityDate: dateFilter,
        availableOnly: true,
        excludeConnected: true,
        status: 'ACTIVE',
        page: _page,
        size: 20,
        sort: 'user.lastName,asc',
      );
      final res = await _api.search(filters);
      setState(() {
        _items = res.content
            .where((p) => p.availabilities.isNotEmpty)
            .toList(growable: false);
        _totalPages = res.totalPages;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _reset() {
    _searchController.clear();
    _specialization = null;
    _experience = null;
    _availabilityDate = null;
    _fetch(resetPage: true);
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: now.subtract(const Duration(days: 0)),
      lastDate: now.add(const Duration(days: 365)),
      initialDate: _availabilityDate ?? now,
    );
    if (picked != null) {
      setState(() => _availabilityDate = picked);
    }
  }

  void _viewProfessional(Professional p) {
    final parentContext = context;
    final messenger = ScaffoldMessenger.of(parentContext);
    showModalBottomSheet(
      context: parentContext,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => _ProfessionalSheet(
        professional: p,
        onConnect: () async {
          Navigator.of(parentContext).pop();
          try {
            await _api.connectWithProfessional(p.id);
            if (!mounted) return;
            messenger.showSnackBar(
              const SnackBar(content: Text('Connection request sent')),
            );
          } catch (e) {
            if (!mounted) return;
            messenger.showSnackBar(
              SnackBar(content: Text('Failed to connect: $e')),
            );
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MemberScaffold(
      title: 'Find a Professional',
      currentRoute: '/member/find-professional',
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            _buildFilters(),
            const SizedBox(height: 8),
            if (_loading) const LinearProgressIndicator(minHeight: 2),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => _fetch(resetPage: true),
                child: _items.isEmpty && !_loading
                    ? const Center(child: Text('No professionals found'))
                    : ListView.builder(
                        itemCount: _items.length,
                        itemBuilder: (context, index) {
                          final p = _items[index];
                          return _ProfessionalCard(
                            professional: p,
                            onView: () => _viewProfessional(p),
                          );
                        },
                      ),
              ),
            ),
            _buildPager(),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                labelText: 'Search by first name',
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<Specialization?>(
                    initialValue: _specialization,
                    decoration:
                        const InputDecoration(labelText: 'Specialization'),
                    items: [
                      const DropdownMenuItem<Specialization?>(
                        value: null,
                        child: Text('Any'),
                      ),
                      for (final s in Specialization.values)
                        DropdownMenuItem<Specialization?>(
                          value: s,
                          child: Text(specializationLabels[s] ?? s.toString()),
                        )
                    ],
                    onChanged: (v) => setState(() => _specialization = v),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<int?>(
                    initialValue: _experience,
                    decoration:
                        const InputDecoration(labelText: 'Experience (years)'),
                    items: const [
                      DropdownMenuItem<int?>(value: null, child: Text('Any')),
                      DropdownMenuItem<int?>(value: 0, child: Text('0')),
                      DropdownMenuItem<int?>(value: 1, child: Text('1')),
                      DropdownMenuItem<int?>(value: 2, child: Text('2')),
                      DropdownMenuItem<int?>(value: 3, child: Text('3')),
                      DropdownMenuItem<int?>(value: 4, child: Text('4')),
                      DropdownMenuItem<int?>(value: 5, child: Text('5')),
                      DropdownMenuItem<int?>(value: 6, child: Text('6')),
                      DropdownMenuItem<int?>(value: 7, child: Text('7')),
                      DropdownMenuItem<int?>(value: 8, child: Text('8')),
                      DropdownMenuItem<int?>(value: 9, child: Text('9')),
                      DropdownMenuItem<int?>(value: 10, child: Text('10')),
                    ],
                    onChanged: (v) => setState(() => _experience = v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: InputDecorator(
                    decoration:
                        const InputDecoration(labelText: 'Availability date'),
                    child: Row(
                      children: [
                        Text(_availabilityDate == null
                            ? 'Any'
                            : _availabilityDate!
                                .toLocal()
                                .toString()
                                .split(' ')
                                .first),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.calendar_today),
                          onPressed: _pickDate,
                        ),
                        if (_availabilityDate != null)
                          IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () =>
                                setState(() => _availabilityDate = null),
                          )
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: () => _fetch(resetPage: true),
                    child: const Text('Apply Filters'),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(onPressed: _reset, child: const Text('Reset')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPager() {
    if (_totalPages <= 1) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: _page > 0 && !_loading
                ? () {
                    setState(() => _page -= 1);
                    _fetch();
                  }
                : null,
            icon: const Icon(Icons.chevron_left),
          ),
          Text('Page ${_page + 1} of $_totalPages'),
          IconButton(
            onPressed: _page + 1 < _totalPages && !_loading
                ? () {
                    setState(() => _page += 1);
                    _fetch();
                  }
                : null,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }
}

class _ProfessionalCard extends StatelessWidget {
  final Professional professional;
  final VoidCallback onView;
  const _ProfessionalCard({required this.professional, required this.onView});

  @override
  Widget build(BuildContext context) {
    final nextSlot = professional.availabilities.isNotEmpty
        ? professional.availabilities.first
        : null;
    final nextSlotLabel = nextSlot != null
        ? DateFormat('EEE, MMM d · h:mm a').format(nextSlot.startTime)
        : null;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundImage: NetworkImage(
                professional.user.avatar ??
                    'https://placehold.co/200x200?text=Profile',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${professional.user.firstName} ${professional.user.lastName}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    specializationLabels[professional.specialization] ??
                        professional.specialization.toString(),
                    style: const TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 16),
                      const SizedBox(width: 4),
                      Text((professional.rating ?? 0).toStringAsFixed(1)),
                    ],
                  ),
                  if (nextSlotLabel != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.event_available,
                            color: Colors.green, size: 16),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            nextSlotLabel,
                            style: const TextStyle(color: Colors.black54),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            FilledButton(onPressed: onView, child: const Text('View')),
          ],
        ),
      ),
    );
  }
}

class _ProfessionalSheet extends StatelessWidget {
  final Professional professional;
  final VoidCallback onConnect;
  const _ProfessionalSheet(
      {required this.professional, required this.onConnect});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, controller) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundImage: NetworkImage(
                      professional.user.avatar ??
                          'https://placehold.co/200x200?text=Profile',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${professional.user.firstName} ${professional.user.lastName}',
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w600),
                        ),
                        Text(
                          specializationLabels[professional.specialization] ??
                              professional.specialization.toString(),
                          style: const TextStyle(color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView(
                  controller: controller,
                  children: [
                    const Text('About',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(professional.bio.isEmpty
                        ? 'No bio provided'
                        : professional.bio),
                    const SizedBox(height: 12),
                    if ((professional.certifications ?? const [])
                        .isNotEmpty) ...[
                      const Text('Experience & Certifications',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      for (final c in professional.certifications!)
                        ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading:
                              const Icon(Icons.verified, color: Colors.green),
                          title: Text(c.name),
                          subtitle: Text(c.issuingOrganization ?? ''),
                        ),
                      const SizedBox(height: 12),
                    ],
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 18),
                        const SizedBox(width: 4),
                        Text(
                            'Rating: ${(professional.rating ?? 0).toStringAsFixed(1)}'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (professional.availabilities.isNotEmpty) ...[
                      const Text('Availability'),
                      Wrap(
                        spacing: 8,
                        children: [
                          for (final slot in professional.availabilities)
                            Chip(
                                avatar: const Icon(Icons.schedule, size: 16),
                                label: Text(slot.formatLabel()))
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: onConnect,
                      child:
                          Text('Connect with ${professional.user.firstName}'),
                    ),
                  ),
                ],
              )
            ],
          ),
        );
      },
    );
  }
}
