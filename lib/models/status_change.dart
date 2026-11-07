import 'package:cloud_firestore/cloud_firestore.dart';

import 'incident_status.dart';

/// One timeline entry, stored in the incident's statusHistory array.
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

  /// A real Timestamp: Firestore doesn't allow serverTimestamp() in arrays.
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
