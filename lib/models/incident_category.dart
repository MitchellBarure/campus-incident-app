import 'package:flutter/material.dart';

/// Issue categories. Each value carries its own label and icon
/// (an "enhanced enum").
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

  /// Parses the Firestore string. Unknown values become [other].
  static IncidentCategory fromString(String? value) {
    return IncidentCategory.values.firstWhere(
      (category) => category.name == value,
      orElse: () => IncidentCategory.other,
    );
  }
}
