import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindapax_mobile/member/sessions_page.dart';
import 'package:mindapax_mobile/professional/models.dart' show PagedResponse;
import 'package:mindapax_mobile/sessions/models.dart';
import 'package:mindapax_mobile/sessions/sessions_api.dart';

class _FakeSessionsApi extends SessionsApi {
  @override
  Future<PagedResponse<Session>> getSessions(SessionQueryParams params) async {
    final now = DateTime.now();
    final s = Session(
      id: 1,
      userId: params.userId,
      professionalId: 10,
      professionalName: 'Dr. Test',
      professionalSpecialization: 'Mental Health',
      startTime: now.add(const Duration(hours: 1)),
      durationMinutes: 30,
      mode: SessionMode.VIDEO,
      notes: 'Test session',
      status: SessionStatus.SCHEDULED,
    );
    return PagedResponse(
      totalPages: 1,
      totalElements: 1,
      page: 0,
      size: 10,
      content: [s],
      empty: false,
      isLast: true,
    );
  }
}

void main() {
  testWidgets('renders sessions list with one item', (tester) async {
    await tester.pumpWidget(MaterialApp(home: SessionsPage(api: _FakeSessionsApi())));
    // Initial frame
    await tester.pump();
    // Allow async loads
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('My Sessions'), findsOneWidget);
    expect(find.text('Dr. Test'), findsOneWidget);
    expect(find.text('Join'), findsWidgets);
  });
}
