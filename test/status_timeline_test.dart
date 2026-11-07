import 'package:campus_incident_app/models/incident.dart';
import 'package:campus_incident_app/models/incident_category.dart';
import 'package:campus_incident_app/models/incident_status.dart';
import 'package:campus_incident_app/models/status_change.dart';
import 'package:campus_incident_app/widgets/status_timeline.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

StatusChange change(IncidentStatus status, {String? note, int day = 6}) {
  return StatusChange(
    status: status,
    changedBy: status == IncidentStatus.submitted ? 'student-1' : 'staff-1',
    changedByName:
        status == IncidentStatus.submitted ? 'Amina' : 'Mr. Kamau',
    note: note,
    at: DateTime(2026, 11, day, 10),
  );
}

Incident incidentWith(IncidentStatus status, List<StatusChange> history) {
  return Incident(
    id: 'inc-1',
    title: 'Leaking tap',
    description: 'Water everywhere',
    category: IncidentCategory.water,
    location: 'Block B',
    status: status,
    reporterId: 'student-1',
    reporterName: 'Amina',
    hasImage: false,
    createdAt: DateTime(2026, 11, 6),
    updatedAt: DateTime(2026, 11, 6),
    statusHistory: history,
  );
}

void main() {
  group('buildTimelineSteps', () {
    test('a new incident has only the first step reached', () {
      final steps = buildTimelineSteps(
        incidentWith(IncidentStatus.submitted,
            [change(IncidentStatus.submitted)]),
      );

      expect(steps.map((s) => s.isReached), [true, false, false]);
      expect(steps.first.change?.changedByName, 'Amina');
      expect(steps[1].change, isNull);
    });

    test('a resolved incident has every step reached', () {
      final steps = buildTimelineSteps(
        incidentWith(IncidentStatus.resolved, [
          change(IncidentStatus.submitted),
          change(IncidentStatus.inProgress, day: 7),
          change(IncidentStatus.resolved, note: 'Fixed', day: 8),
        ]),
      );

      expect(steps.every((s) => s.isReached), isTrue);
      expect(steps.last.change?.note, 'Fixed');
    });

    test('a skipped step is reached but has no history entry', () {
      final steps = buildTimelineSteps(
        incidentWith(IncidentStatus.resolved, [
          change(IncidentStatus.submitted),
          change(IncidentStatus.resolved, day: 7),
        ]),
      );

      expect(steps[1].isReached, isTrue);
      expect(steps[1].change, isNull);
    });

    test('uses the latest entry when a status was set twice', () {
      final steps = buildTimelineSteps(
        incidentWith(IncidentStatus.inProgress, [
          change(IncidentStatus.submitted),
          change(IncidentStatus.inProgress, note: 'First', day: 7),
          change(IncidentStatus.inProgress, note: 'Second', day: 8),
        ]),
      );

      expect(steps[1].change?.note, 'Second');
    });
  });

  testWidgets('StatusTimeline shows labels, reporter and notes',
      (tester) async {
    final incident = incidentWith(IncidentStatus.inProgress, [
      change(IncidentStatus.submitted),
      change(IncidentStatus.inProgress, note: 'Plumber booked', day: 7),
    ]);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: StatusTimeline(incident: incident)),
      ),
    );

    expect(find.text('Submitted'), findsOneWidget);
    expect(find.text('In Progress'), findsOneWidget);
    expect(find.text('Resolved'), findsOneWidget);
    expect(find.text('Pending'), findsOneWidget);
    expect(find.text('Plumber booked'), findsOneWidget);
    expect(find.textContaining('by Mr. Kamau'), findsOneWidget);
  });
}
