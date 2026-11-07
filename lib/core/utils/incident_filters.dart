import '../../models/incident.dart';
import '../../models/incident_status.dart';

/// Returns only the incidents that match [status].
/// A null [status] means "All", so everything is kept.
List<Incident> filterIncidents(
  List<Incident> incidents, {
  IncidentStatus? status,
}) {
  return incidents.where((incident) {
    return status == null || incident.status == status;
  }).toList();
}

/// How many incidents are in each status. Used by the summary cards.
class IncidentCounts {
  const IncidentCounts({
    required this.total,
    required this.submitted,
    required this.inProgress,
    required this.resolved,
  });

  /// Counts a list of incidents. A plain function, so it is easy to test.
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
