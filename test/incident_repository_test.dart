import 'dart:typed_data';

import 'package:campus_incident_app/models/app_user.dart';
import 'package:campus_incident_app/models/incident_category.dart';
import 'package:campus_incident_app/models/incident_status.dart';
import 'package:campus_incident_app/services/image_service.dart';
import 'package:campus_incident_app/services/incident_repository.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

/// Fake photo storage. [shouldFail] simulates an upload error.
class FakeImageService extends ImageService {
  bool shouldFail = false;
  final Map<String, Uint8List> saved = {};

  @override
  Future<String> uploadImage({
    required String incidentId,
    required String ownerId,
    required Uint8List bytes,
  }) async {
    if (shouldFail) throw Exception('upload failed');
    saved[incidentId] = bytes;
    return 'fake/$incidentId';
  }

  @override
  Future<Uint8List?> loadImage(String incidentId) async => saved[incidentId];

  @override
  Future<void> deleteImage(String incidentId) async => saved.remove(incidentId);
}

void main() {
  const student = AppUser(
    uid: 'student-1',
    name: 'Amina',
    email: 'amina@alustudent.com',
    role: UserRole.student,
  );
  const otherStudent = AppUser(
    uid: 'student-2',
    name: 'Kofi',
    email: 'kofi@alustudent.com',
    role: UserRole.student,
  );
  const staff = AppUser(
    uid: 'staff-1',
    name: 'Mr. Kamau',
    email: 'kamau@alu.edu',
    role: UserRole.staff,
  );

  late FakeFirebaseFirestore firestore;
  late FakeImageService imageService;
  late IncidentRepository repository;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    imageService = FakeImageService();
    repository = IncidentRepository(
      firestore: firestore,
      imageService: imageService,
    );
  });

  Future<String> createSample({
    AppUser reporter = student,
    String title = 'Leaking tap',
    CompressedImage? image,
  }) {
    return repository.createIncident(
      title: title,
      description: 'Water everywhere',
      category: IncidentCategory.water,
      location: 'Block B',
      reporter: reporter,
      image: image,
    );
  }

  test(
    'createIncident saves a submitted incident with one history entry',
    () async {
      final id = await createSample(title: '  Leaking tap  ');

      final doc = await firestore.collection('incidents').doc(id).get();
      final data = doc.data()!;

      expect(data['title'], 'Leaking tap'); // trimmed
      expect(data['status'], 'submitted');
      expect(data['category'], 'water');
      expect(data['reporterId'], 'student-1');
      expect(data['hasImage'], isFalse);
      expect(data['statusHistory'], hasLength(1));
      expect(data['statusHistory'][0]['status'], 'submitted');
    },
  );

  test('createIncident saves the photo and thumbnail when given one', () async {
    final image = CompressedImage(
      fullBytes: Uint8List.fromList([1, 2, 3]),
      thumbnailBytes: Uint8List.fromList([4, 5]),
    );

    final id = await createSample(image: image);

    final doc = await firestore.collection('incidents').doc(id).get();
    expect(doc.data()!['hasImage'], isTrue);
    expect(doc.data()!['thumbnailBase64'], image.thumbnailBase64);
    expect(imageService.saved[id], image.fullBytes);
  });

  test(
    'createIncident keeps the report but reports a failed photo upload',
    () async {
      imageService.shouldFail = true;
      final image = CompressedImage(
        fullBytes: Uint8List.fromList([1]),
        thumbnailBytes: Uint8List.fromList([2]),
      );

      await expectLater(
        createSample(image: image),
        throwsA(isA<PhotoUploadFailure>()),
      );

      final incidents = await firestore.collection('incidents').get();
      expect(incidents.docs, hasLength(1));
    },
  );

  test('watchMyIncidents only returns the given user\'s reports', () async {
    await createSample(reporter: student, title: 'Mine');
    await createSample(reporter: otherStudent, title: 'Not mine');

    final mine = await repository.watchMyIncidents(student.uid).first;

    expect(mine, hasLength(1));
    expect(mine.single.title, 'Mine');
  });

  test('watchAllIncidents returns everyone\'s reports', () async {
    await createSample(reporter: student);
    await createSample(reporter: otherStudent);

    final all = await repository.watchAllIncidents().first;

    expect(all, hasLength(2));
  });

  test('updateStatus changes the status and adds to the timeline', () async {
    final id = await createSample();

    await repository.updateStatus(
      incidentId: id,
      newStatus: IncidentStatus.inProgress,
      changedBy: staff,
      note: '  Plumber booked  ',
    );

    final incident = await repository.watchIncident(id).first;

    expect(incident!.status, IncidentStatus.inProgress);
    expect(incident.statusHistory, hasLength(2));
    expect(incident.statusHistory.last.status, IncidentStatus.inProgress);
    expect(incident.statusHistory.last.changedByName, 'Mr. Kamau');
    expect(incident.statusHistory.last.note, 'Plumber booked');
  });

  test('updateStatus stores an empty note as null', () async {
    final id = await createSample();

    await repository.updateStatus(
      incidentId: id,
      newStatus: IncidentStatus.resolved,
      changedBy: staff,
      note: '   ',
    );

    final incident = await repository.watchIncident(id).first;
    expect(incident!.statusHistory.last.note, isNull);
  });

  test('watchIncident emits null for a missing incident', () async {
    final incident = await repository.watchIncident('does-not-exist').first;
    expect(incident, isNull);
  });

  test('updateIncidentDetails edits the text fields only', () async {
    final id = await createSample();

    await repository.updateIncidentDetails(
      incidentId: id,
      title: '  Burst pipe  ',
      description: 'Water is now flooding the corridor',
      category: IncidentCategory.facilities,
      location: 'Block C',
    );

    final incident = await repository.watchIncident(id).first;
    expect(incident!.title, 'Burst pipe');
    expect(incident.category, IncidentCategory.facilities);
    expect(incident.location, 'Block C');
    expect(incident.status, IncidentStatus.submitted);
    expect(incident.reporterId, student.uid);
  });

  test('deleteIncident removes the report and its photo', () async {
    final image = CompressedImage(
      fullBytes: Uint8List.fromList([1, 2, 3]),
      thumbnailBytes: Uint8List.fromList([4, 5]),
    );
    final id = await createSample(image: image);
    final incident = await repository.watchIncident(id).first;

    await repository.deleteIncident(incident!);

    expect(await repository.watchIncident(id).first, isNull);
    expect(imageService.saved.containsKey(id), isFalse);
  });
}
