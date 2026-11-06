import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/app_user.dart';
import '../models/incident.dart';
import '../models/incident_category.dart';
import '../models/incident_status.dart';
import '../models/status_change.dart';
import 'image_service.dart';

/// Thrown when the report was saved but its photo could not be.
/// The screen can still show "Report submitted" plus a warning.
class PhotoUploadFailure implements Exception {
  const PhotoUploadFailure(this.incidentId);

  final String incidentId;

  @override
  String toString() =>
      'Your report was submitted, but the photo could not be uploaded.';
}

/// All reads and writes for incidents go through this class.
class IncidentRepository {
  IncidentRepository({
    required this._firestore,
    required this._imageService,
  });

  final FirebaseFirestore _firestore;
  final ImageService _imageService;

  CollectionReference<Map<String, dynamic>> get _incidents =>
      _firestore.collection('incidents');

  /// Saves a new incident (and its photo, if any). Returns the new id.
  Future<String> createIncident({
    required String title,
    required String description,
    required IncidentCategory category,
    required String location,
    required AppUser reporter,
    CompressedImage? image,
  }) async {
    // doc() with no id creates a reference with a new random id.
    // Nothing is written until we call set().
    final docRef = _incidents.doc();
    final now = DateTime.now();

    final incident = Incident(
      id: docRef.id,
      title: title.trim(),
      description: description.trim(),
      category: category,
      location: location.trim(),
      status: IncidentStatus.submitted,
      reporterId: reporter.uid,
      reporterName: reporter.name,
      hasImage: image != null,
      thumbnailBase64: image?.thumbnailBase64,
      createdAt: now,
      updatedAt: now,
      statusHistory: [
        StatusChange(
          status: IncidentStatus.submitted,
          changedBy: reporter.uid,
          changedByName: reporter.name,
          at: now,
        ),
      ],
    );

    await docRef.set({
      ...incident.toMap(),
      // Use the server's clock for the top-level dates, so they are correct
      // even if the phone's clock is wrong.
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // The photo is saved after the incident, because the security rules
    // check that the photo's incident exists and belongs to this user.
    if (image != null) {
      try {
        await _imageService.uploadImage(
          incidentId: docRef.id,
          ownerId: reporter.uid,
          bytes: image.fullBytes,
        );
      } catch (_) {
        throw PhotoUploadFailure(docRef.id);
      }
    }

    return docRef.id;
  }

  /// Every incident, newest first. Updates live when anything changes.
  Stream<List<Incident>> watchAllIncidents() {
    return _incidents
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(_toIncidents);
  }

  /// Incidents reported by one user, newest first.
  ///
  /// Needs a composite index (reporterId + createdAt). The first time it
  /// runs, Firestore throws an error containing a link that creates it.
  Stream<List<Incident>> watchMyIncidents(String uid) {
    return _incidents
        .where('reporterId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(_toIncidents);
  }

  /// One incident, or null if it doesn't exist.
  Stream<Incident?> watchIncident(String id) {
    return _incidents.doc(id).snapshots().map((snapshot) {
      final data = snapshot.data();
      if (data == null) return null;
      return Incident.fromMap(snapshot.id, data);
    });
  }

  /// Staff only (enforced by security rules): moves an incident to a new
  /// status and adds an entry to its timeline.
  Future<void> updateStatus({
    required String incidentId,
    required IncidentStatus newStatus,
    required AppUser changedBy,
    String? note,
  }) {
    final trimmedNote = note?.trim();

    final change = StatusChange(
      status: newStatus,
      changedBy: changedBy.uid,
      changedByName: changedBy.name,
      // Store "no note" as null rather than an empty string.
      note: (trimmedNote == null || trimmedNote.isEmpty) ? null : trimmedNote,
      at: DateTime.now(),
    );

    return _incidents.doc(incidentId).update({
      'status': newStatus.name,
      'updatedAt': FieldValue.serverTimestamp(),
      // arrayUnion adds to the end of the list without replacing it.
      'statusHistory': FieldValue.arrayUnion([change.toMap()]),
    });
  }

  List<Incident> _toIncidents(QuerySnapshot<Map<String, dynamic>> snapshot) {
    return snapshot.docs
        .map((doc) => Incident.fromMap(doc.id, doc.data()))
        .toList();
  }
}
