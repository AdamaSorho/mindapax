import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindapax_mobile/member/schedule_session_page.dart';
import 'package:mindapax_mobile/sessions/models.dart';
import 'package:mindapax_mobile/sessions/sessions_api.dart';
import 'package:mindapax_mobile/user/user_api.dart';

class _FakeSessionsApi extends SessionsApi {
  int? lastUserId;
  String? lastStartIso;
  int? lastDuration;
  SessionMode? lastMode;
  String? lastNotes;

  @override
  Future<Session> scheduleSessionByProfessional({
    required int userId,
    required String startTimeIso,
    required int durationMinutes,
    required SessionMode mode,
    String? notes,
  }) async {
    lastUserId = userId;
    lastStartIso = startTimeIso;
    lastDuration = durationMinutes;
    lastMode = mode;
    lastNotes = notes;
    // Return a basic session based on the payload
    return Session.fromJson({
      'id': 1,
      'userId': userId,
      'professionalId': 10,
      'professionalName': 'Dr. Test',
      'professionalSpecialization': 'Mental Health',
      'startTime': startTimeIso,
      'durationMinutes': durationMinutes,
      'mode': sessionModeToString(mode),
      'notes': notes ?? '',
      'status': 'SCHEDULED',
    });
  }
}

void main() {
  testWidgets('renders schedule session UI and shows client dropdown for professionals', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: ScheduleSessionPage(
        isProfessionalOverride: true,
        initialUsers: [UserBasic(id: 1, firstName: 'Jane', lastName: 'Doe')],
      ),
    ));

    expect(find.text('Schedule Session'), findsOneWidget);
    // Client dropdown hint
    expect(find.text('Select client'), findsOneWidget);
  });

  testWidgets('schedules a session with provided initial values', (tester) async {
    final api = _FakeSessionsApi();
    final date = DateTime(2030, 1, 15);
    final time = const TimeOfDay(hour: 14, minute: 30);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ScheduleSessionPage(
          api: api,
          isProfessionalOverride: true,
          initialUsers: [UserBasic(id: 7, firstName: 'John', lastName: 'Smith')],
          initialSelectedUserId: 7,
          initialDate: date,
          initialTime: time,
        ),
      ),
    ));

    // Tap schedule button
    final scheduleBtn = find.widgetWithText(FilledButton, 'Schedule Session');
    expect(scheduleBtn, findsOneWidget);
    await tester.tap(scheduleBtn);
    await tester.pump();

    // API captured the call
    expect(api.lastUserId, 7);
    expect(api.lastDuration, 30); // default
    expect(api.lastMode, SessionMode.VIDEO); // default
    expect(api.lastStartIso, isNotNull);
  });

  testWidgets('non-professionals see error when scheduling', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: ScheduleSessionPage(isProfessionalOverride: false)),
    ));
    final scheduleBtn = find.widgetWithText(FilledButton, 'Schedule Session');
    await tester.tap(scheduleBtn);
    await tester.pump();
    expect(find.textContaining('Only professionals'), findsOneWidget);
  });
}

