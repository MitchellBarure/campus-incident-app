import 'package:cloud_firestore/cloud_firestore.dart';

import 'incident_status.dart';

/// One step in an incident's timeline, e.g. "Moved to In Progress by
/// Mr. Kamau on 6 Nov, note: Plumber booked for Friday".
///
/// Stored inside the incident's statusHistory array.
class StatusChange {
  const StatusChange({
    required this.status,
    required this.changedBy,
    required this.changedByName,
    required this.at,
    this.note,
  });

  final IncidentStatus status;

  /// uid of the person who made the change.
  final String changedBy;
  final String changedByName;

  /// Optional message, usually from staff.
  final String? note;
  final DateTime at;

  factory StatusChange.fromMap(Map<String, dynamic> map) {
    final at = map['at'];

    return StatusChange(
      status: IncidentStatus.fromString(map['status'] as String?),
      changedBy: map['changedBy'] as String? ?? '',
      changedByName: map['changedByName'] as String? ?? '',
      note: map['note'] as String?,
      at: at is Timestamp ? at.toDate() : DateTime.now(),
    );
  }

  /// Uses a real Timestamp (not serverTimestamp), because Firestore does
  /// not allow serverTimestamp() inside arrays.
  Map<String, dynamic> toMap() {
    return {
      'status': status.name,
      'changedBy': changedBy,
      'changedByName': changedByName,
      'note': note,
      'at': Timestamp.fromDate(at),
    };
  }
}
