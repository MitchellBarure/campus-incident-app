import 'package:cloud_firestore/cloud_firestore.dart';

import 'incident_category.dart';
import 'incident_status.dart';
import 'status_change.dart';

/// A reported campus issue at incidents/{id}.
class Incident {
  const Incident({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.location,
    required this.status,
    required this.reporterId,
    required this.reporterName,
    required this.hasImage,
    required this.createdAt,
    required this.updatedAt,
    required this.statusHistory,
    this.thumbnailBase64,
  });

  final String id;
  final String title;
  final String description;
  final IncidentCategory category;

  final String location;
  final IncidentStatus status;
  final String reporterId;
  final String reporterName;

  /// True when a full-size photo exists in incident_images/{id}.
  final bool hasImage;

  /// A tiny JPEG preview (base64) shown on list cards. Null if no photo.
  final String? thumbnailBase64;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Every status change, oldest first. Drives the details timeline.
  final List<StatusChange> statusHistory;

  factory Incident.fromMap(String id, Map<String, dynamic> map) {
    final history = map['statusHistory'] as List<dynamic>? ?? [];

    return Incident(
      id: id,
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      category: IncidentCategory.fromString(map['category'] as String?),
      location: map['location'] as String? ?? '',
      status: IncidentStatus.fromString(map['status'] as String?),
      reporterId: map['reporterId'] as String? ?? '',
      reporterName: map['reporterName'] as String? ?? '',
      hasImage: map['hasImage'] as bool? ?? false,
      thumbnailBase64: map['thumbnailBase64'] as String?,
      createdAt: _readDate(map['createdAt']),
      updatedAt: _readDate(map['updatedAt']),
      statusHistory: history
          .map(
            (entry) =>
                StatusChange.fromMap(Map<String, dynamic>.from(entry as Map)),
          )
          .toList(),
    );
  }

  /// Excludes id (the doc id). The repository sets the dates on create.
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'category': category.name,
      'location': location,
      'status': status.name,
      'reporterId': reporterId,
      'reporterName': reporterName,
      'hasImage': hasImage,
      'thumbnailBase64': thumbnailBase64,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'statusHistory': statusHistory.map((change) => change.toMap()).toList(),
    };
  }
}

/// Server timestamps are briefly null after a write, so fall back to now.
DateTime _readDate(Object? value) {
  if (value is Timestamp) return value.toDate();
  return DateTime.now();
}
