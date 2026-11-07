import 'dart:typed_data';

import 'package:campus_incident_app/core/router/app_router.dart';
import 'package:campus_incident_app/models/app_user.dart';
import 'package:campus_incident_app/models/incident.dart';
import 'package:campus_incident_app/models/incident_category.dart';
import 'package:campus_incident_app/models/incident_status.dart';
import 'package:campus_incident_app/providers/auth_providers.dart';
import 'package:campus_incident_app/providers/incident_providers.dart';
import 'package:campus_incident_app/screens/student/report_incident_screen.dart';
import 'package:campus_incident_app/services/image_service.dart';
import 'package:campus_incident_app/services/incident_repository.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// An image service that never touches a camera or Firebase.
class FakeImageService extends ImageService {
  @override
  Future<void> deleteImage(String incidentId) async {}

  @override
  Future<String> uploadImage({
    required String incidentId,
    required String ownerId,
    required Uint8List bytes,
  }) async => 'fake/$incidentId';

  @override
  Future<Uint8List?> loadImage(String incidentId) async => null;
}

const student = AppUser(
  uid: 'student-1',
  name: 'Amina',
  email: 'amina@alustudent.com',
  role: UserRole.student,
);

void main() {
  late FakeFirebaseFirestore firestore;

  /// Shows the Report screen with fakes.
  /// The default theme avoids downloading Google Fonts.
  Future<void> pumpReportScreen(
    WidgetTester tester, {
    Incident? existing,
  }) async {
    firestore = FakeFirebaseFirestore();

    // Tall screen so the ListView builds the whole form.
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final router = GoRouter(
      initialLocation: AppRoutes.reportIncident,
      routes: [
        GoRoute(
          path: AppRoutes.home,
          builder: (context, state) => const Scaffold(body: Text('Home page')),
        ),
        GoRoute(
          path: AppRoutes.reportIncident,
          builder: (context, state) => ReportIncidentScreen(existing: existing),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserProfileProvider.overrideWith(
            (ref) => Stream.value(student),
          ),
          incidentRepositoryProvider.overrideWithValue(
            IncidentRepository(
              firestore: firestore,
              imageService: FakeImageService(),
            ),
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// The Submit button is at the bottom of a scrolling form.
  Future<void> tapSubmit(WidgetTester tester) async {
    final submit = find.text('Submit Report');
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pumpAndSettle();
  }

  testWidgets('shows every error when submitting an empty form', (
    tester,
  ) async {
    await pumpReportScreen(tester);

    await tapSubmit(tester);

    expect(find.text('Please choose a category'), findsOneWidget);
    expect(find.text('Please enter a title'), findsOneWidget);
    expect(find.text('Please describe the issue'), findsOneWidget);
    expect(find.text('Please say where the issue is'), findsOneWidget);
    expect(firestore.dump(), isNot(contains('incidents')));
  });

  testWidgets('submits a valid report and returns home', (tester) async {
    await pumpReportScreen(tester);

    await tester.tap(find.text('Water'));
    await tester.enterText(
      find.widgetWithText(TextFormField, 'e.g. Leaking tap in washroom'),
      'Leaking tap',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'What is wrong? Since when?'),
      'The tap has been running since Monday.',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'e.g. Block B - Room 204'),
      'Block B washroom',
    );
    await tapSubmit(tester);

    final saved = await firestore.collection('incidents').get();
    expect(saved.docs, hasLength(1));
    expect(saved.docs.single.data()['category'], 'water');
    expect(saved.docs.single.data()['reporterName'], 'Amina');
    expect(find.text('Home page'), findsOneWidget);
    expect(find.text('Report submitted. Thank you!'), findsOneWidget);
  });

  testWidgets('edit mode fills in the report and hides the photo', (
    tester,
  ) async {
    final now = DateTime(2026, 11, 7);
    final existing = Incident(
      id: 'abc',
      title: 'Leaking tap',
      description: 'Water everywhere in the washroom',
      category: IncidentCategory.water,
      location: 'Block B',
      status: IncidentStatus.submitted,
      reporterId: student.uid,
      reporterName: student.name,
      hasImage: false,
      createdAt: now,
      updatedAt: now,
      statusHistory: const [],
    );

    await pumpReportScreen(tester, existing: existing);

    expect(find.text('Edit Report'), findsOneWidget);
    expect(find.text('Leaking tap'), findsOneWidget);
    expect(find.text('Block B'), findsOneWidget);
    expect(find.text('Save Changes'), findsOneWidget);
    expect(find.text('Photo'), findsNothing);
  });
}
