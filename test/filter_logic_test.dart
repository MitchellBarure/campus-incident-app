import 'package:campus_incident_app/core/utils/formatters.dart';
import 'package:campus_incident_app/core/utils/incident_filters.dart';
import 'package:campus_incident_app/models/incident.dart';
import 'package:campus_incident_app/models/incident_category.dart';
import 'package:campus_incident_app/models/incident_status.dart';
import 'package:flutter_test/flutter_test.dart';

/// Builds a test incident; only the fields the filters look at matter.
Incident makeIncident({
  required String id,
  IncidentStatus status = IncidentStatus.submitted,
  IncidentCategory category = IncidentCategory.other,
  String title = 'Issue',
  String description = 'Something is wrong',
  String location = 'Campus',
}) {
  return Incident(
    id: id,
    title: title,
    description: description,
    category: category,
    location: location,
    status: status,
    reporterId: 'u1',
    reporterName: 'Amina',
    hasImage: false,
    createdAt: DateTime(2026, 11, 6),
    updatedAt: DateTime(2026, 11, 6),
    statusHistory: const [],
  );
}

void main() {
  final incidents = [
    makeIncident(id: 'a', status: IncidentStatus.submitted),
    makeIncident(id: 'b', status: IncidentStatus.inProgress),
    makeIncident(id: 'c', status: IncidentStatus.inProgress),
    makeIncident(id: 'd', status: IncidentStatus.resolved),
  ];

  group('IncidentCounts', () {
    test('counts each status', () {
      final counts = IncidentCounts.from(incidents);

      expect(counts.total, 4);
      expect(counts.submitted, 1);
      expect(counts.inProgress, 2);
      expect(counts.resolved, 1);
    });

    test('is all zeros for an empty list', () {
      final counts = IncidentCounts.from([]);
      expect(counts.total, 0);
      expect(counts.resolved, 0);
    });
  });

  group('filterIncidents by status', () {
    test('null status keeps everything', () {
      expect(filterIncidents(incidents), hasLength(4));
    });

    test('keeps only the chosen status', () {
      final result =
          filterIncidents(incidents, status: IncidentStatus.inProgress);
      expect(result.map((i) => i.id), ['b', 'c']);
    });
  });

  group('filterIncidents search and category', () {
    final mixed = [
      makeIncident(
        id: 'tap',
        title: 'Leaking tap',
        location: 'Block B washroom',
        category: IncidentCategory.water,
      ),
      makeIncident(
        id: 'light',
        title: 'Flickering light',
        description: 'Corridor light keeps flickering',
        location: 'Library',
        category: IncidentCategory.electricity,
        status: IncidentStatus.resolved,
      ),
      makeIncident(
        id: 'chair',
        title: 'Broken chair',
        location: 'Block B - Room 204',
        category: IncidentCategory.furniture,
      ),
    ];

    test('search is case-insensitive and ignores surrounding spaces', () {
      final result = filterIncidents(mixed, query: '  LEAKING ');
      expect(result.map((i) => i.id), ['tap']);
    });

    test('search looks at location and description too', () {
      expect(
        filterIncidents(mixed, query: 'block b').map((i) => i.id),
        ['tap', 'chair'],
      );
      expect(
        filterIncidents(mixed, query: 'corridor').map((i) => i.id),
        ['light'],
      );
    });

    test('search matches the category label', () {
      final result = filterIncidents(mixed, query: 'furniture');
      expect(result.map((i) => i.id), ['chair']);
    });

    test('category filter keeps only that category', () {
      final result =
          filterIncidents(mixed, category: IncidentCategory.electricity);
      expect(result.map((i) => i.id), ['light']);
    });

    test('all filters combine (AND)', () {
      final result = filterIncidents(
        mixed,
        query: 'block b',
        status: IncidentStatus.submitted,
        category: IncidentCategory.furniture,
      );
      expect(result.map((i) => i.id), ['chair']);
    });

    test('returns an empty list when nothing matches', () {
      expect(filterIncidents(mixed, query: 'parking'), isEmpty);
    });
  });

  group('Formatters', () {
    test('firstName takes the first word', () {
      expect(Formatters.firstName('Amina Uwase'), 'Amina');
      expect(Formatters.firstName('  '), 'there');
    });

    test('shortDate formats day, month and year', () {
      expect(Formatters.shortDate(DateTime(2026, 11, 6)), '6 Nov 2026');
    });
  });
}
