import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/utils/formatters.dart';
import '../models/incident.dart';
import '../models/incident_status.dart';
import '../models/status_change.dart';

/// One step of the timeline: Submitted, In Progress or Resolved.
class TimelineStep {
  const TimelineStep({
    required this.status,
    required this.isReached,
    this.change,
  });

  final IncidentStatus status;

  /// True if the incident has got to this step (or past it).
  final bool isReached;

  /// The most recent history entry for this step, if there is one.
  /// It can be null for a reached step that staff skipped over
  /// (e.g. moved straight from Submitted to Resolved).
  final StatusChange? change;
}

/// Works out the three timeline steps for an incident.
///
/// A plain function (no widgets), so it can be unit tested.
List<TimelineStep> buildTimelineSteps(Incident incident) {
  final currentIndex = IncidentStatus.values.indexOf(incident.status);

  return [
    for (final status in IncidentStatus.values)
      TimelineStep(
        status: status,
        isReached: IncidentStatus.values.indexOf(status) <= currentIndex,
        change: _latestChangeFor(incident.statusHistory, status),
      ),
  ];
}

StatusChange? _latestChangeFor(
  List<StatusChange> history,
  IncidentStatus status,
) {
  StatusChange? latest;
  for (final change in history) {
    if (change.status == status) latest = change;
  }
  return latest;
}

/// Vertical timeline: Submitted -> In Progress -> Resolved, with dates,
/// who made each change, and any note.
class StatusTimeline extends StatelessWidget {
  const StatusTimeline({super.key, required this.incident});

  final Incident incident;

  @override
  Widget build(BuildContext context) {
    final steps = buildTimelineSteps(incident);

    return Column(
      children: [
        for (var i = 0; i < steps.length; i++)
          _TimelineRow(
            step: steps[i],
            isLast: i == steps.length - 1,
            // The line below a step is coloured if the next step is reached.
            isNextReached: i < steps.length - 1 && steps[i + 1].isReached,
          ),
      ],
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.step,
    required this.isLast,
    required this.isNextReached,
  });

  final TimelineStep step;
  final bool isLast;
  final bool isNextReached;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final color = step.isReached ? step.status.color : AppColors.border;
    final change = step.change;

    // IntrinsicHeight lets the connecting line stretch to match the text.
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 28,
            child: Column(
              children: [
                _Dot(color: color, isReached: step.isReached),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: isNextReached ? color : AppColors.border,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.status.label,
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: step.isReached
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _subtitle(change),
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (change?.note != null) ...[
                    const SizedBox(height: 6),
                    _NoteBubble(note: change!.note!),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _subtitle(StatusChange? change) {
    if (change != null) {
      return '${Formatters.dateTime(change.at)} · by ${change.changedByName}';
    }
    return step.isReached ? 'Done' : 'Pending';
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color, required this.isReached});

  final Color color;
  final bool isReached;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isReached ? color : AppColors.surface,
        border: Border.all(color: color, width: 2),
      ),
      child: isReached
          ? const Icon(Icons.check, size: 14, color: AppColors.surface)
          : null,
    );
  }
}

class _NoteBubble extends StatelessWidget {
  const _NoteBubble({required this.note});

  final String note;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(note, style: Theme.of(context).textTheme.bodySmall),
    );
  }
}
