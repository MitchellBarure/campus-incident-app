import 'dart:typed_data';

import 'package:campus_incident_app/models/app_user.dart';
import 'package:campus_incident_app/models/incident_status.dart';
import 'package:campus_incident_app/services/image_service.dart';
import 'package:campus_incident_app/services/incident_repository.dart';
import 'package:campus_incident_app/services/seed_data.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeImageService extends ImageService {
  @override
  Future<String> uploadImage({
    required String incidentId,
    required String ownerId,
    required Uint8List bytes,
  }) async => 'fake/$incidentId';

  @override
  Future<Uint8List?> loadImage(String incidentId) async => null;
}

void main() {
  late IncidentRepository repository;

  setUp(() {
    repository = IncidentRepository(
      firestore: FakeFirebaseFirestore(),
      imageService: FakeImageService(),
    );
  });

  test('a student seeds 8 reports, all submitted', () async {
    const student = AppUser(
      uid: 's1',
      name: 'Amina',
      email: 'a@alustudent.com',
      role: UserRole.student,
    );

    final count = await seedSampleIncidents(repository, student);
    final all = await repository.watchAllIncidents().first;

    expect(count, 8);
    expect(all, hasLength(8));
    expect(all.every((i) => i.status == IncidentStatus.submitted), isTrue);
  });

  test('staff seeding produces every status with a full timeline', () async {
    const staff = AppUser(
      uid: 'staff-1',
      name: 'Mr. Kamau',
      email: 'k@alu.edu',
      role: UserRole.staff,
    );

    await seedSampleIncidents(repository, staff);
    final all = await repository.watchAllIncidents().first;
    final statuses = all.map((i) => i.status).toSet();

    expect(statuses, IncidentStatus.values.toSet());
    final resolved = all.firstWhere((i) => i.status == IncidentStatus.resolved);
    // Submitted -> In Progress -> Resolved.
    expect(resolved.statusHistory, hasLength(3));
  });
}
