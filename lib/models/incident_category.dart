import 'package:flutter/material.dart';

/// The kinds of campus issue a student can report.
///
/// This is an "enhanced enum": each value carries its own label and icon,
/// so the UI never needs a separate switch statement to look them up.
enum IncidentCategory {
  facilities('Facilities', Icons.apartment_outlined),
  water('Water', Icons.water_drop_outlined),
  electricity('Electricity', Icons.bolt_outlined),
  furniture('Furniture', Icons.chair_outlined),
  sanitation('Sanitation', Icons.cleaning_services_outlined),
  safety('Safety', Icons.health_and_safety_outlined),
  other('Other', Icons.more_horiz);

  const IncidentCategory(this.label, this.icon);

  final String label;
  final IconData icon;

  /// Turns the string stored in Firestore (e.g. "water") back into a value.
  /// Unknown values become [other], so old or bad data never crashes the app.
  static IncidentCategory fromString(String? value) {
    return IncidentCategory.values.firstWhere(
      (category) => category.name == value,
      orElse: () => IncidentCategory.other,
    );
  }
}
