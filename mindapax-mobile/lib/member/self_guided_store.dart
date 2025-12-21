import 'dart:convert';
import 'dart:io' show Platform;
import 'dart:math';

import 'package:flutter/material.dart';
import '../auth/authorized_client.dart';
import '../auth/token_storage.dart';
import '../env.dart';

class SelfGuidedGoal {
  final String id;
  final String title;
  final String domain; // MIND|MONEY|BODY|RELATIONSHIPS|GROWTH|INTEGRATED|CUSTOM
  final String? outcome; // Optional outcome category
  final String action;
  final int targetPerWeek; // 1-7
  final int minutesPerTask;
  final String difficulty; // EASE|STEADY|STRETCH
  final List<GoalTask> tasks;
  final int xp;
  final int streak;
  final DateTime? lastProgressDate;
  final DateTime createdAt;

  SelfGuidedGoal({
    required this.id,
    required this.title,
    required this.domain,
    this.outcome,
    required this.action,
    required this.targetPerWeek,
    required this.minutesPerTask,
    required this.difficulty,
    required this.tasks,
    required this.xp,
    required this.streak,
    required this.createdAt,
    this.lastProgressDate,
  });

  SelfGuidedGoal copyWith({
    String? id,
    String? title,
    String? domain,
    String? outcome,
    String? action,
    int? targetPerWeek,
    int? minutesPerTask,
    String? difficulty,
    List<GoalTask>? tasks,
    int? xp,
    int? streak,
    DateTime? lastProgressDate,
    DateTime? createdAt,
  }) {
    return SelfGuidedGoal(
      id: id ?? this.id,
      title: title ?? this.title,
      domain: domain ?? this.domain,
      outcome: outcome ?? this.outcome,
      action: action ?? this.action,
      targetPerWeek: targetPerWeek ?? this.targetPerWeek,
      minutesPerTask: minutesPerTask ?? this.minutesPerTask,
      difficulty: difficulty ?? this.difficulty,
      tasks: tasks ?? this.tasks,
      xp: xp ?? this.xp,
      streak: streak ?? this.streak,
      lastProgressDate: lastProgressDate ?? this.lastProgressDate,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory SelfGuidedGoal.fromJson(Map<String, dynamic> json) {
    return SelfGuidedGoal(
      id: json['id']?.toString() ?? _genId(),
      title: json['title']?.toString() ?? '',
      domain: (json['domain']?.toString() ?? 'CUSTOM').toUpperCase(),
      outcome: json['outcome']?.toString(),
      action: json['action']?.toString() ?? '',
      targetPerWeek: (json['targetPerWeek'] as num?)?.toInt() ?? 3,
      minutesPerTask: (json['minutesPerTask'] as num?)?.toInt() ?? 20,
      difficulty: (json['difficulty']?.toString() ?? 'STEADY').toUpperCase(),
      tasks: ((json['tasks'] as List<dynamic>?) ?? const [])
          .map((e) => GoalTask.fromJson(e as Map<String, dynamic>))
          .toList(growable: false),
      xp: (json['xp'] as num?)?.toInt() ?? 0,
      streak: (json['streak'] as num?)?.toInt() ?? 0,
      lastProgressDate: json['lastProgressDate'] != null
          ? DateTime.tryParse(json['lastProgressDate'].toString())
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ??
              DateTime.now().toUtc()
          : DateTime.now().toUtc(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'domain': domain,
      'outcome': outcome,
      'action': action,
      'targetPerWeek': targetPerWeek,
      'minutesPerTask': minutesPerTask,
      'difficulty': difficulty,
      'tasks': tasks.map((e) => e.toJson()).toList(growable: false),
      'xp': xp,
      'streak': streak,
      'lastProgressDate': lastProgressDate?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class GoalTask {
  final String id;
  final String goalId;
  final DateTime date;
  final String title;
  final int minutes;
  final TaskStatus status;
  final DateTime? completedAt;

  const GoalTask({
    required this.id,
    required this.goalId,
    required this.date,
    required this.title,
    required this.minutes,
    required this.status,
    this.completedAt,
  });

  GoalTask copyWith({
    String? id,
    String? goalId,
    DateTime? date,
    String? title,
    int? minutes,
    TaskStatus? status,
    DateTime? completedAt,
  }) {
    return GoalTask(
      id: id ?? this.id,
      goalId: goalId ?? this.goalId,
      date: date ?? this.date,
      title: title ?? this.title,
      minutes: minutes ?? this.minutes,
      status: status ?? this.status,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  factory GoalTask.fromJson(Map<String, dynamic> json) {
    return GoalTask(
      id: json['id']?.toString() ?? _genId(),
      goalId: json['goalId']?.toString() ?? '',
      date: DateTime.tryParse(json['date']?.toString() ?? '') ??
          DateTime.now(),
      title: json['title']?.toString() ?? '',
      minutes: (json['minutes'] as num?)?.toInt() ?? 15,
      status: TaskStatusX.fromString(json['status']?.toString() ?? ''),
      completedAt: json['completedAt'] != null
          ? DateTime.tryParse(json['completedAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'goalId': goalId,
      'date': _formatDate(date),
      'title': title,
      'minutes': minutes,
      'status': status.toApiValue(),
      'completedAt': completedAt?.toIso8601String(),
    };
  }
}

enum TaskStatus { pending, done, softSkipped, skipped }

extension TaskStatusX on TaskStatus {
  static TaskStatus fromString(String raw) {
    switch (raw.toLowerCase()) {
      case 'done':
        return TaskStatus.done;
      case 'softskipped':
      case 'soft_skipped':
      case 'soft-skipped':
        return TaskStatus.softSkipped;
      case 'skipped':
        return TaskStatus.skipped;
      case 'pending':
      default:
        return TaskStatus.pending;
    }
  }

  String get label {
    switch (this) {
      case TaskStatus.done:
        return 'Done';
      case TaskStatus.softSkipped:
        return 'Soft skip';
      case TaskStatus.skipped:
        return 'Skipped';
      case TaskStatus.pending:
      default:
        return 'Pending';
    }
  }

  Color get color {
    switch (this) {
      case TaskStatus.done:
        return Colors.green;
      case TaskStatus.softSkipped:
        return Colors.orange;
      case TaskStatus.skipped:
        return Colors.grey;
      case TaskStatus.pending:
      default:
        return Colors.blueGrey;
    }
  }

  String toApiValue() {
    switch (this) {
      case TaskStatus.done:
        return 'DONE';
      case TaskStatus.softSkipped:
        return 'SOFT_SKIPPED';
      case TaskStatus.skipped:
        return 'SKIPPED';
      case TaskStatus.pending:
      default:
        return 'PENDING';
    }
  }
}

class DailyCheckIn {
  final DateTime date;
  final int mood; // 1-5
  final int effort; // 1-5
  final String? note;

  const DailyCheckIn({
    required this.date,
    required this.mood,
    required this.effort,
    this.note,
  });

  factory DailyCheckIn.fromJson(Map<String, dynamic> json) {
    return DailyCheckIn(
      date: DateTime.tryParse(json['date']?.toString() ?? '') ??
          DateTime.now(),
      mood: (json['mood'] as num?)?.toInt() ?? 3,
      effort: (json['effort'] as num?)?.toInt() ?? 3,
      note: json['note']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': _formatDate(date),
      'mood': mood,
      'effort': effort,
      'note': note,
    };
  }
}

class SelfGuidedStore {
  static final TokenStorage _storage = TokenStorage();

  static Future<List<SelfGuidedGoal>> loadGoals(
      {bool ensureWeek = true, DateTime? now}) async {
    final client = AuthorizedHttpClient(_storage);
    final res = await client.get(_uri('/self-guided/goals'));
    if (res.statusCode == 204) return <SelfGuidedGoal>[];
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Failed to load goals (${res.statusCode})');
    }
    final list = (jsonDecode(res.body) as List<dynamic>)
        .map((e) => SelfGuidedGoal.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
    return list;
  }

  static Future<SelfGuidedGoal> createGoal({
    required String title,
    required String domain,
    String? outcome,
    required String action,
    required int targetPerWeek,
    required int minutesPerTask,
    required String difficulty,
    DateTime? now,
  }) async {
    final client = AuthorizedHttpClient(_storage);
    final body = jsonEncode({
      'title': title,
      'domain': domain.toUpperCase(),
      'outcome': outcome?.trim().isEmpty == true ? null : outcome,
      'action': action,
      'targetPerWeek': targetPerWeek,
      'minutesPerTask': minutesPerTask,
      'difficulty': difficulty.toUpperCase(),
    });
    final res = await client.post(_uri('/self-guided/goals'),
        headers: {'Content-Type': 'application/json'}, body: body);
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Failed to create goal (${res.statusCode})');
    }
    return SelfGuidedGoal.fromJson(
        jsonDecode(res.body) as Map<String, dynamic>);
  }

  static Future<SelfGuidedGoal?> updateTask(GoalTask updated) async {
    final client = AuthorizedHttpClient(_storage);
    final body = jsonEncode({
      'date': _formatDate(updated.date),
      'title': updated.title,
      'minutes': updated.minutes,
      'status': updated.status.toApiValue(),
    });
    final res = await client.patch(
        _uri('/self-guided/tasks/${updated.id}'),
        headers: {'Content-Type': 'application/json'},
        body: body);
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Failed to update task (${res.statusCode})');
    }
    return getGoal(updated.goalId);
  }

  static Future<SelfGuidedGoal?> rescheduleMissed(String goalId,
      {DateTime? now}) async {
    final client = AuthorizedHttpClient(_storage);
    final res = await client.post(
        _uri('/self-guided/goals/$goalId/tasks/reschedule-missed'));
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Failed to reschedule tasks (${res.statusCode})');
    }
    return getGoal(goalId);
  }

  static Future<SelfGuidedGoal?> updateTaskStatus({
    required String goalId,
    required String taskId,
    required TaskStatus status,
    DateTime? now,
  }) async {
    final client = AuthorizedHttpClient(_storage);
    final res = await client.patch(
        _uri('/self-guided/tasks/$taskId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'status': status.toApiValue()}));
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Failed to update task (${res.statusCode})');
    }
    return getGoal(goalId);
  }

  static Future<SelfGuidedGoal?> getGoal(String goalId) async {
    final client = AuthorizedHttpClient(_storage);
    final res = await client.get(_uri('/self-guided/goals/$goalId'));
    if (res.statusCode == 404) return null;
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Failed to load goal (${res.statusCode})');
    }
    return SelfGuidedGoal.fromJson(
        jsonDecode(res.body) as Map<String, dynamic>);
  }

  static Future<DailyCheckIn?> loadCheckIn(DateTime date) async {
    final client = AuthorizedHttpClient(_storage);
    final res = await client
        .get(_uri('/self-guided/check-ins', {'date': _formatDate(date)}));
    if (res.statusCode == 204) return null;
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Failed to load check-in (${res.statusCode})');
    }
    return DailyCheckIn.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  static Future<void> saveCheckIn(DailyCheckIn entry) async {
    final client = AuthorizedHttpClient(_storage);
    final date = _formatDate(entry.date);
    final res = await client.put(_uri('/self-guided/check-ins/$date'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'mood': entry.mood,
          'effort': entry.effort,
          'note': entry.note,
        }));
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Failed to save check-in (${res.statusCode})');
    }
  }

  static Uri _uri(String path, [Map<String, String>? query]) {
    final base = _normalizeBaseUrl(apiBaseUrl);
    final uri = Uri.parse('$base$path');
    return query == null ? uri : uri.replace(queryParameters: query);
  }

  static String _normalizeBaseUrl(String value) {
    final cleaned = value.replaceAll(RegExp(r'/+$'), '');
    try {
      final u = Uri.parse(cleaned);
      if (u.host == 'localhost' && Platform.isAndroid) {
        return cleaned.replaceFirst('localhost', '10.0.2.2');
      }
    } catch (_) {}
    return cleaned;
  }
}

String _genId() {
  final rnd = Random().nextInt(1 << 32);
  return '${DateTime.now().microsecondsSinceEpoch}-$rnd';
}

String _formatDate(DateTime date) {
  final d = DateUtils.dateOnly(date);
  return '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
