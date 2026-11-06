import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants.dart';
import '../models/incident.dart';
import '../services/image_service.dart';
import '../services/incident_repository.dart';
import 'auth_providers.dart';

/// Chooses where photos are stored, based on the useFirebaseStorage flag.
/// The rest of the app never needs to know which one is active.
final imageServiceProvider = Provider<ImageService>((ref) {
  if (useFirebaseStorage) {
    return FirebaseStorageImageService(storage: FirebaseStorage.instance);
  }
  return FirestoreImageService(firestore: ref.watch(firestoreProvider));
});

final incidentRepositoryProvider = Provider<IncidentRepository>((ref) {
  return IncidentRepository(
    firestore: ref.watch(firestoreProvider),
    imageService: ref.watch(imageServiceProvider),
  );
});

/// Every incident, newest first (Browse screen and Staff dashboard).
final allIncidentsProvider = StreamProvider<List<Incident>>((ref) {
  return ref.watch(incidentRepositoryProvider).watchAllIncidents();
});

/// The signed-in student's own incidents (Home and My Reports).
final myIncidentsProvider = StreamProvider<List<Incident>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) {
    return Stream.value([]);
  }
  return ref.watch(incidentRepositoryProvider).watchMyIncidents(user.uid);
});
