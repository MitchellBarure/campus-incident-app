import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

/// Where an incident is in its life: Submitted -> In Progress -> Resolved.
///
/// Each value carries its label and colours so status chips and the
/// timeline look the same everywhere in the app.
enum IncidentStatus {
  submitted('Submitted', AppColors.submitted, AppColors.submittedBg),
  inProgress('In Progress', AppColors.inProgress, AppColors.inProgressBg),
  resolved('Resolved', AppColors.resolved, AppColors.resolvedBg);

  const IncidentStatus(this.label, this.color, this.backgroundColor);

  final String label;

  /// Text and icon colour.
  final Color color;

  /// Light background colour for pill-shaped chips.
  final Color backgroundColor;

  /// The status staff most likely want next, pre-selected in the Update
  /// Status sheet: Submitted -> In Progress -> Resolved. A resolved
  /// incident suggests In Progress (re-opening it).
  IncidentStatus get suggestedNext {
    switch (this) {
      case IncidentStatus.submitted:
        return IncidentStatus.inProgress;
      case IncidentStatus.inProgress:
        return IncidentStatus.resolved;
      case IncidentStatus.resolved:
        return IncidentStatus.inProgress;
    }
  }

  /// Turns the string stored in Firestore (e.g. "inProgress") back into a
  /// value. Unknown values become [submitted].
  static IncidentStatus fromString(String? value) {
    return IncidentStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => IncidentStatus.submitted,
    );
  }
}
