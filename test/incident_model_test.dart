import 'package:campus_incident_app/models/incident.dart';
import 'package:campus_incident_app/models/incident_category.dart';
import 'package:campus_incident_app/models/incident_status.dart';
import 'package:campus_incident_app/models/status_change.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('IncidentCategory.fromString', () {
    test('reads every stored value', () {
      for (final category in IncidentCategory.values) {
        expect(IncidentCategory.fromString(category.name), category);
      }
    });

    test('falls back to other for unknown or missing values', () {
      expect(IncidentCategory.fromString('parking'), IncidentCategory.other);
      expect(IncidentCategory.fromString(null), IncidentCategory.other);
    });

    test('has the seven required categories', () {
      expect(
        IncidentCategory.values.map((c) => c.label),
        [
          'Facilities',
          'Water',
          'Electricity',
          'Furniture',
          'Sanitation',
          'Safety',
          'Other',
        ],
      );
    });
  });

  group('IncidentStatus.fromString', () {
    test('reads the camelCase value used in Firestore', () {
      expect(IncidentStatus.fromString('inProgress'), IncidentStatus.inProgress);
      expect(IncidentStatus.inProgress.label, 'In Progress');
    });

    test('falls back to submitted for unknown values', () {
      expect(IncidentStatus.fromString('closed'), IncidentStatus.submitted);
    });
  });

  group('StatusChange', () {
    test('survives a toMap -> fromMap round trip', () {
      final change = StatusChange(
        status: IncidentStatus.resolved,
        changedBy: 'staff-1',
        changedByName: 'Mr. Kamau',
        note: 'Tap replaced',
        at: DateTime(2026, 11, 6, 14),
      );

      final copy = StatusChange.fromMap(change.toMap());

      expect(copy.status, IncidentStatus.resolved);
      expect(copy.changedBy, 'staff-1');
      expect(copy.changedByName, 'Mr. Kamau');
      expect(copy.note, 'Tap replaced');
      expect(copy.at, DateTime(2026, 11, 6, 14));
    });

    test('stores the date as a Firestore Timestamp', () {
      final change = StatusChange(
        status: IncidentStatus.submitted,
        changedBy: 'u1',
        changedByName: 'Amina',
        at: DateTime(2026, 11, 6),
      );

      expect(change.toMap()['at'], isA<Timestamp>());
      expect(change.toMap()['note'], isNull);
    });
  });

  group('Incident', () {
    final created = DateTime(2026, 11, 5, 9, 15);
    final updated = DateTime(2026, 11, 6, 11, 0);

    Map<String, dynamic> sampleMap() => {
          'title': 'Leaking tap',
          'description': 'The tap in the 2nd floor washroom keeps running.',
          'category': 'water',
          'location': 'Block B - 2nd floor',
          'status': 'inProgress',
          'reporterId': 'student-1',
          'reporterName': 'Amina',
          'hasImage': true,
          'thumbnailBase64': 'abc123',
          'createdAt': Timestamp.fromDate(created),
          'updatedAt': Timestamp.fromDate(updated),
          'statusHistory': [
            {
              'status': 'submitted',
              'changedBy': 'student-1',
              'changedByName': 'Amina',
              'note': null,
              'at': Timestamp.fromDate(created),
            },
            {
              'status': 'inProgress',
              'changedBy': 'staff-1',
              'changedByName': 'Mr. Kamau',
              'note': 'Plumber booked',
              'at': Timestamp.fromDate(updated),
            },
          ],
        };

    test('fromMap reads every field', () {
      final incident = Incident.fromMap('inc-1', sampleMap());

      expect(incident.id, 'inc-1');
      expect(incident.title, 'Leaking tap');
      expect(incident.category, IncidentCategory.water);
      expect(incident.location, 'Block B - 2nd floor');
      expect(incident.status, IncidentStatus.inProgress);
      expect(incident.reporterId, 'student-1');
      expect(incident.reporterName, 'Amina');
      expect(incident.hasImage, isTrue);
      expect(incident.thumbnailBase64, 'abc123');
      expect(incident.createdAt, created);
      expect(incident.updatedAt, updated);
      expect(incident.statusHistory, hasLength(2));
      expect(incident.statusHistory.last.note, 'Plumber booked');
    });

    test('toMap produces the same data fromMap reads', () {
      final incident = Incident.fromMap('inc-1', sampleMap());
      final copy = Incident.fromMap('inc-1', incident.toMap());

      expect(copy.title, incident.title);
      expect(copy.status, incident.status);
      expect(copy.category, incident.category);
      expect(copy.createdAt, incident.createdAt);
      expect(copy.statusHistory, hasLength(2));
      // The id lives in the document id, not inside the data.
      expect(incident.toMap().containsKey('id'), isFalse);
    });

    test('fromMap copes with missing optional data', () {
      final incident = Incident.fromMap('inc-2', {
        'title': 'Broken chair',
        'createdAt': null, // pending serverTimestamp
      });

      expect(incident.hasImage, isFalse);
      expect(incident.thumbnailBase64, isNull);
      expect(incident.statusHistory, isEmpty);
      expect(incident.category, IncidentCategory.other);
      expect(incident.status, IncidentStatus.submitted);
    });
  });
}
