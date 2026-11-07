import '../../models/incident.dart';
import '../../models/incident_category.dart';
import '../../models/incident_status.dart';

/// Applies the search and filters. Null [status] or [category] means All.
/// Runs on the phone because Firestore has no full-text search.
List<Incident> filterIncidents(
  List<Incident> incidents, {
  String query = '',
  IncidentStatus? status,
  IncidentCategory? category,
}) {
  final search = query.trim().toLowerCase();

  return incidents.where((incident) {
    if (status != null && incident.status != status) return false;
    if (category != null && incident.category != category) return false;
    if (search.isEmpty) return true;
    return _matchesSearch(incident, search);
  }).toList();
}

bool _matchesSearch(Incident incident, String search) {
  final searchableText = [
    incident.title,
    incident.description,
    incident.location,
    incident.reporterName,
    incident.category.label,
  ].join(' ').toLowerCase();

  return searchableText.contains(search);
}

/// How many incidents are in each status. Used by the summary cards.
class IncidentCounts {
  const IncidentCounts({
    required this.total,
    required this.submitted,
    required this.inProgress,
    required this.resolved,
  });

  factory IncidentCounts.from(List<Incident> incidents) {
    int countOf(IncidentStatus status) =>
        incidents.where((incident) => incident.status == status).length;

    return IncidentCounts(
      total: incidents.length,
      submitted: countOf(IncidentStatus.submitted),
      inProgress: countOf(IncidentStatus.inProgress),
      resolved: countOf(IncidentStatus.resolved),
    );
  }

  final int total;
  final int submitted;
  final int inProgress;
  final int resolved;
}
