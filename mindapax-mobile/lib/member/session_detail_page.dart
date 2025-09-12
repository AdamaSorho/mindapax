import 'package:flutter/material.dart';
import '../sessions/models.dart';

class SessionDetailPage extends StatelessWidget {
  final Session session;
  final bool joinable;
  final VoidCallback? onJoin;
  final String title;
  final String subtitle;
  final String avatarText;

  const SessionDetailPage({
    super.key,
    required this.session,
    required this.joinable,
    this.onJoin,
    required this.title,
    required this.subtitle,
    required this.avatarText,
  });

  @override
  Widget build(BuildContext context) {
    final end = DateTime.tryParse(session.startTime
        .add(Duration(minutes: session.durationMinutes))
        .toIso8601String());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Session Details'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 28,
                child: Text(avatarText),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    if (subtitle.trim().isNotEmpty)
                      Text(
                        subtitle,
                        style: const TextStyle(color: Colors.black54),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          _InfoRow(icon: Icons.today, label: _dateLabel(session.startTime)),
          const SizedBox(height: 8),
          _InfoRow(
            icon: Icons.schedule,
            label: '${_timeOf(session.startTime)} - ${end != null ? _timeOf(end) : ''} (${session.durationMinutes} mins)'
          ),
          const SizedBox(height: 8),
          _InfoRow(icon: _modeIcon(session.mode), label: '${sessionModeToString(session.mode)} session'),
          const SizedBox(height: 8),
          if (session.status != null)
            _InfoRow(icon: Icons.flag_outlined, label: sessionStatusToString(session.status!) ?? 'Scheduled'),

          if ((session.notes ?? '').isNotEmpty) ...[
            const SizedBox(height: 20),
            const Text('Notes', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(
              session.notes!,
              style: const TextStyle(color: Colors.black87),
            ),
          ],

          const SizedBox(height: 24),
          if (joinable)
            FilledButton.icon(
              onPressed: onJoin,
              icon: const Icon(Icons.video_call_outlined),
              label: const Text('Join Session'),
            )
          else
            OutlinedButton.icon(
              onPressed: null,
              icon: const Icon(Icons.video_call_outlined),
              label: const Text('Join Session'),
            ),
        ],
      ),
    );
  }

  static String _dateLabel(DateTime d) {
    final now = DateTime.now();
    final a = DateTime(d.year, d.month, d.day);
    final b = DateTime(now.year, now.month, now.day);
    final diffDays = a.difference(b).inDays;
    if (diffDays == 0) return 'Today';
    if (diffDays == 1) return 'Tomorrow';
    if (diffDays == -1) return 'Yesterday';
    if (diffDays.abs() < 7) {
      const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return names[d.weekday - 1];
    }
    return '${d.month}/${d.day}/${d.year}';
  }

  static String _timeOf(DateTime d) {
    final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final m = d.minute.toString().padLeft(2, '0');
    final ampm = d.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $ampm';
  }

  static IconData _modeIcon(SessionMode mode) {
    switch (mode) {
      case SessionMode.VIDEO:
        return Icons.videocam_outlined;
      case SessionMode.CHAT:
        return Icons.chat_bubble_outline;
      case SessionMode.MESSAGE:
        return Icons.mail_outline;
    }
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, size: 18, color: Colors.black54),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
