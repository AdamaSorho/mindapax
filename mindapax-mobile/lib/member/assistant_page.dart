import 'dart:convert';

import 'package:flutter/material.dart';
import '../auth/authorized_client.dart';
import '../auth/token_storage.dart';
import '../env.dart';
import 'dart:io' show Platform;
import 'assistant_prefs.dart';

class AssistantPage extends StatefulWidget {
  const AssistantPage({super.key});

  @override
  State<AssistantPage> createState() => _AssistantPageState();
}

class _AssistantPageState extends State<AssistantPage> {
  final _controller = TextEditingController();
  final _storage = TokenStorage();
  final List<_Msg> _messages = [];
  bool _loading = false;
  bool _useContext = true;
  bool _askSuggestions = true;
  bool _includeProgress = true;
  String? _contextPrefs;
  String? _contextNotes;
  final Set<String> _accepted = {};
  int _activeGoals = 0;
  bool _hasContext = false;

  @override
  void initState() {
    super.initState();
    _loadContext();
    _loadGoalsCount();
    _loadTogglePrefs();
  }

  Future<void> _loadTogglePrefs() async {
    // Load local defaults first for snappy UI
    final use = await AssistantPrefs.getUseContext();
    final prog = await AssistantPrefs.getIncludeProgress();
    final sugg = await AssistantPrefs.getSuggestGoals();
    if (mounted) {
      setState(() {
        _useContext = use;
        _includeProgress = prog;
        _askSuggestions = sugg;
      });
    }
    // Try to load from server and reconcile
    try {
      final client = AuthorizedHttpClient(_storage);
      final uri = Uri.parse('${_normalizeBaseUrl(apiBaseUrl)}/assistant/prefs');
      final res = await client.get(uri);
      if (res.statusCode >= 200 &&
          res.statusCode < 300 &&
          res.body.isNotEmpty) {
        final m = jsonDecode(res.body) as Map<String, dynamic>;
        final sUse = m['useContext'] == true;
        final sProg = m['includeProgress'] == true;
        final sSug = m['suggestGoals'] == true;
        if (mounted) {
          setState(() {
            _useContext = sUse;
            _includeProgress = sProg;
            _askSuggestions = sSug;
          });
        }
        // Save locally
        await AssistantPrefs.setUseContext(sUse);
        await AssistantPrefs.setIncludeProgress(sProg);
        await AssistantPrefs.setSuggestGoals(sSug);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadContext() async {
    try {
      final client = AuthorizedHttpClient(_storage);
      final base = _normalizeBaseUrl(apiBaseUrl);
      // Lightweight status endpoint for banner/indicator
      try {
        final resStatus =
            await client.get(Uri.parse('$base/assistant/context/completed'));
        if (resStatus.statusCode >= 200 &&
            resStatus.statusCode < 300 &&
            resStatus.body.isNotEmpty) {
          final m = jsonDecode(resStatus.body) as Map<String, dynamic>;
          if (mounted) setState(() => _hasContext = (m['completed'] == true));
        }
      } catch (_) {}
      // Fetch full context only for preview text (optional)
      try {
        final res = await client.get(Uri.parse('$base/assistant/context'));
        if (res.statusCode >= 200 &&
            res.statusCode < 300 &&
            res.body.isNotEmpty &&
            res.body != 'null') {
          final json = jsonDecode(res.body) as Map<String, dynamic>;
          if (mounted) {
            setState(() {
              _contextPrefs =
                  (json['preferencesJson']?.toString() ?? '').trim();
              _contextNotes = (json['notes']?.toString() ?? '').trim();
            });
          }
        }
      } catch (_) {}
    } catch (_) {}
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _loading) return;
    setState(() {
      _messages.add(_Msg(role: 'user', text: text));
      _loading = true;
      _controller.clear();
    });
    try {
      final client = AuthorizedHttpClient(_storage);
      final uri = Uri.parse('${_normalizeBaseUrl(apiBaseUrl)}/assistant');
      final res = await client.post(uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'message': text,
            'requestRecommendations': _askSuggestions,
            'useContext': _useContext,
            'includeProgress': _includeProgress,
          }));
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        final reply = (json['reply']?.toString() ?? '').trim();
        final suggestions = (json['suggestions'] as List<dynamic>?) ?? const [];
        setState(() {
          if (reply.isNotEmpty) {
            _messages.add(_Msg(role: 'assistant', text: reply));
          } else {
            _messages.add(_Msg(role: 'assistant', text: '')); // keep order
          }
          if (suggestions.isNotEmpty) {
            final list = suggestions.map((s) {
              final m = s as Map<String, dynamic>;
              final title = m['title']?.toString() ?? '';
              final freq = m['frequency']?.toString() ?? '';
              return GoalSuggestion(title: title, frequency: freq);
            }).toList(growable: false);
            _messages.add(_Msg(
                role: 'assistant', text: 'Suggested goals', suggestions: list));
          }
        });
      } else {
        setState(() {
          _messages.add(_Msg(
              role: 'assistant',
              text: 'Sorry, I could not reply (status ${res.statusCode}).'));
        });
      }
    } catch (e) {
      setState(() {
        _messages.add(_Msg(role: 'assistant', text: 'Error: $e'));
      });
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

  String _keyFor(GoalSuggestion s) => '${s.title}|${s.frequency}'.toUpperCase();

  Future<void> _acceptSuggestion(GoalSuggestion s) async {
    final key = _keyFor(s);
    if (_accepted.contains(key)) return;
    try {
      final client = AuthorizedHttpClient(_storage);
      final uri =
          Uri.parse('${_normalizeBaseUrl(apiBaseUrl)}/assistant/goals/accept');
      final body = jsonEncode([
        {'title': s.title, 'frequency': s.frequency.toUpperCase()}
      ]);
      final res = await client.post(uri,
          headers: {'Content-Type': 'application/json'}, body: body);
      if (res.statusCode >= 200 && res.statusCode < 300) {
        if (!mounted) return;
        setState(() {
          _accepted.add(key);
          _activeGoals += 1;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Goal accepted'),
            action: SnackBarAction(
              label: 'View goals',
              onPressed: () {
                Navigator.of(context).pushNamed('/member/goals');
              },
            ),
          ),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Accept failed (${res.statusCode})')));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Widget _suggestionTile(GoalSuggestion s) {
    final accepted = _accepted.contains(_keyFor(s));
    return _suggestionTileBuilder(
        context, s, accepted, () => _acceptSuggestion(s));
  }

  Future<void> _loadGoalsCount() async {
    try {
      final client = AuthorizedHttpClient(_storage);
      final uri = Uri.parse('${_normalizeBaseUrl(apiBaseUrl)}/assistant/goals');
      final res = await client.get(uri);
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final list = (jsonDecode(res.body) as List<dynamic>);
        int count = 0;
        for (final e in list) {
          final m = e as Map<String, dynamic>;
          final status = (m['status']?.toString() ?? '').toUpperCase();
          if (status == 'ACTIVE') count++;
        }
        if (mounted) setState(() => _activeGoals = count);
      }
    } catch (_) {}
  }

  Widget _goalsActionButton() {
    return InkWell(
      onTap: () async {
        await Navigator.of(context).pushNamed('/member/goals');
        await _loadGoalsCount();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            const Icon(Icons.flag_outlined),
            if (_activeGoals > 0)
              Positioned(
                right: -6,
                top: -6,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  constraints:
                      const BoxConstraints(minWidth: 18, minHeight: 16),
                  child: Text(
                    _activeGoals.toString(),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveServerPrefs() async {
    try {
      final client = AuthorizedHttpClient(_storage);
      final uri = Uri.parse('${_normalizeBaseUrl(apiBaseUrl)}/assistant/prefs');
      final body = jsonEncode({
        'useContext': _useContext,
        'includeProgress': _includeProgress,
        'suggestGoals': _askSuggestions,
      });
      await client.post(uri,
          headers: {'Content-Type': 'application/json'}, body: body);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Wrap(
          spacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            const Text('AI Assistant'),
            if (_hasContext)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.check_circle, size: 14, color: Colors.green),
                    SizedBox(width: 4),
                    Text('Using context',
                        style: TextStyle(fontSize: 12, color: Colors.green)),
                  ],
                ),
              ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            final nav = Navigator.of(context);
            if (nav.canPop()) {
              nav.pop();
            } else {
              nav.pushReplacementNamed('/member/dashboard');
            }
          },
          tooltip: 'Back',
        ),
        actions: [
          _goalsActionButton(),
          IconButton(
            icon: const Icon(Icons.tune),
            tooltip: 'Context',
            onPressed: () async {
              final saved = await Navigator.of(context)
                  .pushNamed('/member/assistant-context');
              if (saved == true) {
                await _loadContext();
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (!_hasContext)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(12, 12, 12, 6),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7E6), // light amber
                border: Border.all(color: const Color(0xFFFFE08A)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, color: Colors.amber),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Personalize your assistant',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        const Text(
                            'Set your goals and preferences so the AI can tailor its guidance to you.'),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            OutlinedButton.icon(
                              onPressed: () async {
                                final saved = await Navigator.of(context)
                                    .pushNamed('/member/assistant-context');
                                if (saved == true) {
                                  await _loadContext();
                                }
                              },
                              icon: const Icon(Icons.tune),
                              label: const Text('Update Context'),
                            ),
                            TextButton(
                              onPressed: _showWhyContextDialog,
                              child: const Text('Why this matters'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          if ((_contextPrefs?.isNotEmpty ?? false) ||
              (_contextNotes?.isNotEmpty ?? false))
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Card(
                elevation: 0,
                color: Colors.blueGrey.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.tune, size: 16),
                          const SizedBox(width: 6),
                          const Text('Using context',
                              style: TextStyle(fontWeight: FontWeight.w600)),
                        ],
                      ),
                      if ((_contextPrefs?.isNotEmpty ?? false)) ...[
                        const SizedBox(height: 6),
                        Text(
                          'Your preferences are saved and will be used to personalize suggestions.',
                          style: const TextStyle(color: Colors.black87),
                        ),
                      ],
                      if ((_contextNotes?.isNotEmpty ?? false)) ...[
                        const SizedBox(height: 6),
                        Text(_shorten(_contextNotes!, 160),
                            style: const TextStyle(color: Colors.black54)),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _messages.length,
              itemBuilder: (context, i) {
                final m = _messages[i];
                final isUser = m.role == 'user';
                return Align(
                  alignment:
                      isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.8),
                    decoration: BoxDecoration(
                      color: isUser
                          ? Theme.of(context).colorScheme.primaryContainer
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(m.text.isEmpty ? '…' : m.text,
                            style: TextStyle(
                                color: isUser ? null : Colors.black87)),
                        if (!isUser &&
                            (m.suggestions?.isNotEmpty ?? false)) ...[
                          const SizedBox(height: 8),
                          for (final s in m.suggestions!) _suggestionTile(s),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Column(
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilterChip(
                        label: const Text('Use context'),
                        selected: _useContext,
                        onSelected: (v) async {
                          setState(() => _useContext = v);
                          await AssistantPrefs.setUseContext(v);
                          _saveServerPrefs();
                        },
                      ),
                      FilterChip(
                        label: const Text('Include progress'),
                        selected: _includeProgress,
                        onSelected: (v) async {
                          setState(() => _includeProgress = v);
                          await AssistantPrefs.setIncludeProgress(v);
                          _saveServerPrefs();
                        },
                      ),
                      FilterChip(
                        label: const Text('Suggest goals'),
                        selected: _askSuggestions,
                        onSelected: (v) async {
                          setState(() => _askSuggestions = v);
                          await AssistantPrefs.setSuggestGoals(v);
                          _saveServerPrefs();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          minLines: 1,
                          maxLines: 4,
                          decoration: const InputDecoration(
                              hintText: 'Type your message…'),
                          onSubmitted: (_) => _send(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        onPressed: _loading ? null : _send,
                        icon: _loading
                            ? const SizedBox(
                                height: 16,
                                width: 16,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.send),
                        label: const Text('Send'),
                      )
                    ],
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  void _showWhyContextDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Why personalize?'),
        content: const Text(
            'Sharing your goals and preferences helps the assistant tailor guidance to you. '
            'For example, if improving sleep is a focus, suggestions can factor your bedtime, '
            'preferred times, and reminder cadence. You can edit this anytime and only what you choose to share is used.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close')),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              final saved = await Navigator.of(context)
                  .pushNamed('/member/assistant-context');
              if (saved == true) {
                await _loadContext();
              }
            },
            child: const Text('Update Context'),
          ),
        ],
      ),
    );
  }
}

class _Msg {
  final String role; // 'user' | 'assistant'
  final String text;
  final bool isNote;
  final List<GoalSuggestion>? suggestions;
  _Msg({
    required this.role,
    required this.text,
    this.isNote = false,
    this.suggestions,
  });
}

class GoalSuggestion {
  final String title;
  final String frequency; // DAILY|WEEKLY|MONTHLY
  GoalSuggestion({required this.title, required this.frequency});
}

Widget _suggestionTileBuilder(BuildContext context, GoalSuggestion s,
    bool accepted, VoidCallback onAccept) {
  return Container(
    margin: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Icon(Icons.bolt, size: 16, color: Colors.black54),
        const SizedBox(width: 6),
        Expanded(
          child: Text('[${s.frequency}] ${s.title}',
              maxLines: 3, overflow: TextOverflow.ellipsis),
        ),
        const SizedBox(width: 8),
        accepted
            ? const Text('Accepted', style: TextStyle(color: Colors.green))
            : OutlinedButton(onPressed: onAccept, child: const Text('Accept')),
      ],
    ),
  );
}

String _shorten(String s, int max) {
  if (s.length <= max) return s;
  return '${s.substring(0, max - 1)}…';
}
