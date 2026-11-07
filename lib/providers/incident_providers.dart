import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants.dart';
import '../models/incident.dart';
import '../services/image_service.dart';
import '../services/incident_repository.dart';
import 'auth_providers.dart';

/// Picks the photo storage from the useFirebaseStorage flag.
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

/// Every incident, newest first. Watches the user so it restarts on login
/// instead of keeping a signed-out "permission denied" error.
final allIncidentsProvider = StreamProvider<List<Incident>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) {
    return Stream.value([]);
  }
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

// .family makes one provider per argument, here one per incident id.

/// One incident, live. Emits null if the incident doesn't exist.
final incidentByIdProvider = StreamProvider.family<Incident?, String>((
  ref,
  incidentId,
) {
  // Restarts on login, like allIncidentsProvider.
  final user = ref.watch(authStateProvider).value;
  if (user == null) {
    return Stream.value(null);
  }
  return ref.watch(incidentRepositoryProvider).watchIncident(incidentId);
});

/// The full-size photo, loaded only on the details screen.
final incidentImageProvider = FutureProvider.family<Uint8List?, String>((
  ref,
  incidentId,
) {
  return ref.watch(imageServiceProvider).loadImage(incidentId);
});
