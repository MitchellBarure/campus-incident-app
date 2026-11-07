import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../models/incident_category.dart';

/// A scrollable row of category chips with icons, plus "All categories".
///
/// [selected] is null when "All categories" is chosen.
class CategoryFilterChips extends StatelessWidget {
  const CategoryFilterChips({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final IncidentCategory? selected;
  final ValueChanged<IncidentCategory?> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _chip(label: 'All categories', icon: Icons.apps, value: null),
          for (final category in IncidentCategory.values)
            _chip(label: category.label, icon: category.icon, value: category),
        ],
      ),
    );
  }

  Widget _chip({
    required String label,
    required IconData icon,
    required IncidentCategory? value,
  }) {
    final isSelected = selected == value;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        avatar: Icon(
          icon,
          size: 18,
          color: isSelected ? AppColors.primary : AppColors.textSecondary,
        ),
        label: Text(label),
        selected: isSelected,
        showCheckmark: false,
        onSelected: (_) => onChanged(value),
      ),
    );
  }
}
