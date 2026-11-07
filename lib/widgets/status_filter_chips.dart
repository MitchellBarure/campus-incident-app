import 'package:flutter/material.dart';

import '../models/incident_status.dart';

/// Status filter chips. [selected] is null for All.
class StatusFilterChips extends StatelessWidget {
  const StatusFilterChips({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final IncidentStatus? selected;
  final ValueChanged<IncidentStatus?> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _chip(label: 'All', value: null),
          for (final status in IncidentStatus.values)
            _chip(label: status.label, value: status),
        ],
      ),
    );
  }

  Widget _chip({required String label, required IncidentStatus? value}) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected == value,
        showCheckmark: false,
        onSelected: (_) => onChanged(value),
      ),
    );
  }
}
