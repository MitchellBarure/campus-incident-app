import '../models/app_user.dart';
import '../models/incident_category.dart';
import '../models/incident_status.dart';
import 'incident_repository.dart';

/// One sample report, plus where staff should move it to (if anywhere).
class _SampleIncident {
  const _SampleIncident({
    required this.title,
    required this.description,
    required this.category,
    required this.location,
    this.moveTo,
    this.note,
  });

  final String title;
  final String description;
  final IncidentCategory category;
  final String location;
  final IncidentStatus? moveTo;
  final String? note;
}

const _samples = [
  _SampleIncident(
    title: 'Leaking tap in ground floor washroom',
    description:
        'The left tap keeps running even when closed. '
        'Water is pooling on the floor.',
    category: IncidentCategory.water,
    location: 'Block A - Ground floor washroom',
    moveTo: IncidentStatus.inProgress,
    note: 'Plumber booked for tomorrow morning.',
  ),
  _SampleIncident(
    title: 'Flickering lights in study room',
    description:
        'Two ceiling lights flicker constantly, '
        'making it hard to study in the evening.',
    category: IncidentCategory.electricity,
    location: 'Library - Study room 3',
    moveTo: IncidentStatus.resolved,
    note: 'Replaced both light tubes.',
  ),
  _SampleIncident(
    title: 'Broken chair in lecture hall',
    description:
        'One of the chairs in the third row has a cracked '
        'leg and wobbles badly.',
    category: IncidentCategory.furniture,
    location: 'Block B - Room 204',
  ),
  _SampleIncident(
    title: 'Overflowing bins near cafeteria',
    description:
        'The rubbish bins outside the cafeteria have not been '
        'emptied and are attracting flies.',
    category: IncidentCategory.sanitation,
    location: 'Cafeteria - Outdoor seating',
    moveTo: IncidentStatus.resolved,
    note: 'Bins emptied; collection schedule increased to daily.',
  ),
  _SampleIncident(
    title: 'Exit sign not lit',
    description:
        'The emergency exit sign at the end of the corridor '
        'is completely dark.',
    category: IncidentCategory.safety,
    location: 'Residence Hall C - 2nd floor corridor',
    moveTo: IncidentStatus.inProgress,
    note: 'Electrician checking the backup battery.',
  ),
  _SampleIncident(
    title: 'Air conditioner not cooling',
    description:
        'The AC runs but only blows warm air. '
        'The room gets very hot after midday.',
    category: IncidentCategory.facilities,
    location: 'Block C - Computer lab',
  ),
  _SampleIncident(
    title: 'No water pressure in showers',
    description:
        'Showers on the top floor only produce a trickle '
        'of water in the mornings.',
    category: IncidentCategory.water,
    location: 'Residence Hall A - 3rd floor',
  ),
  _SampleIncident(
    title: 'Wi-Fi router blinking red',
    description:
        'The router in the common room has a red light and '
        'nobody can connect.',
    category: IncidentCategory.other,
    location: 'Student Centre - Common room',
    moveTo: IncidentStatus.inProgress,
  ),
];

/// Debug only: creates 8 sample reports as [user]. If [user] is staff,
/// some are moved on so every status has data. Returns how many.
Future<int> seedSampleIncidents(
  IncidentRepository repository,
  AppUser user,
) async {
  for (final sample in _samples) {
    final id = await repository.createIncident(
      title: sample.title,
      description: sample.description,
      category: sample.category,
      location: sample.location,
      reporter: user,
    );

    final moveTo = sample.moveTo;
    if (user.isStaff && moveTo != null) {
      // Resolved reports go through In Progress first, like real ones.
      if (moveTo == IncidentStatus.resolved) {
        await repository.updateStatus(
          incidentId: id,
          newStatus: IncidentStatus.inProgress,
          changedBy: user,
          note: 'Looking into it.',
        );
      }
      await repository.updateStatus(
        incidentId: id,
        newStatus: moveTo,
        changedBy: user,
        note: sample.note,
      );
    }
  }
  return _samples.length;
}
