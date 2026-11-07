import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

/// Submitted -> In Progress -> Resolved, each with its label and colours.
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

  /// Pre-selected in the Update Status sheet. Resolved suggests re-opening.
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

  /// Parses the Firestore string. Unknown values become [submitted].
  static IncidentStatus fromString(String? value) {
    return IncidentStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => IncidentStatus.submitted,
    );
  }
}
