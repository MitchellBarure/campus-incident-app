import 'dart:typed_data';

import 'package:campus_incident_app/models/app_user.dart';
import 'package:campus_incident_app/models/incident_category.dart';
import 'package:campus_incident_app/models/incident_status.dart';
import 'package:campus_incident_app/providers/auth_providers.dart';
import 'package:campus_incident_app/providers/incident_providers.dart';
import 'package:campus_incident_app/screens/shared/incident_details_screen.dart';
import 'package:campus_incident_app/services/image_service.dart';
import 'package:campus_incident_app/services/incident_repository.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeImageService extends ImageService {
  @override
  Future<String> uploadImage({
    required String incidentId,
    required String ownerId,
    required Uint8List bytes,
  }) async =>
      'fake/$incidentId';

  @override
  Future<Uint8List?> loadImage(String incidentId) async => null;
}

const student = AppUser(
  uid: 'student-1',
  name: 'Amina',
  email: 'amina@alustudent.com',
  role: UserRole.student,
);

const staff = AppUser(
  uid: 'staff-1',
  name: 'Mr. Kamau',
  email: 'kamau@alu.edu',
  role: UserRole.staff,
);

void main() {
  group('IncidentStatus.suggestedNext', () {
    test('moves forward through the workflow', () {
      expect(IncidentStatus.submitted.suggestedNext, IncidentStatus.inProgress);
      expect(IncidentStatus.inProgress.suggestedNext, IncidentStatus.resolved);
    });

    test('suggests re-opening a resolved incident', () {
      expect(IncidentStatus.resolved.suggestedNext, IncidentStatus.inProgress);
    });
  });

  late IncidentRepository repository;
  late String incidentId;

  /// Opens the details screen for a fresh incident, logged in as [user].
  Future<void> pumpDetails(WidgetTester tester, AppUser user) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    repository = IncidentRepository(
      firestore: FakeFirebaseFirestore(),
      imageService: FakeImageService(),
    );
    incidentId = await repository.createIncident(
      title: 'Leaking tap',
      description: 'Water everywhere in the washroom',
      category: IncidentCategory.water,
      location: 'Block B',
      reporter: student,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserProfileProvider.overrideWith((ref) => Stream.value(user)),
          incidentRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp(home: IncidentDetailsScreen(incidentId: incidentId)),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('students never see the Update Status button', (tester) async {
    await pumpDetails(tester, student);

    expect(find.text('Leaking tap'), findsOneWidget);
    expect(find.text('Update Status'), findsNothing);
  });

  testWidgets('staff can move an incident to In Progress with a note',
      (tester) async {
    await pumpDetails(tester, staff);

    await tester.tap(find.text('Update Status'));
    await tester.pumpAndSettle();

    // In Progress is pre-selected for a submitted incident.
    await tester.enterText(find.byType(TextField), 'Plumber booked');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    // Widget tests run on a fake clock; runAsync lets this real Firestore
    // read finish instead of waiting forever.
    final updated = await tester.runAsync(
      () => repository.watchIncident(incidentId).first,
    );
    expect(updated!.status, IncidentStatus.inProgress);
    expect(updated.statusHistory.last.note, 'Plumber booked');
    expect(updated.statusHistory.last.changedByName, 'Mr. Kamau');
    expect(find.text('Status updated to In Progress'), findsOneWidget);
    // The new note shows up in the Staff Notes section.
    expect(find.text('Plumber booked'), findsWidgets);
  });
}
