import 'package:flutter/material.dart';

import '../models/incident_status.dart';

/// A small pill showing an incident's status in its own colour.
class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status});

  final IncidentStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: status.backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: status.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            status.label,
            style: Theme.of(context).textTheme.labelSmall
                ?.copyWith(color: status.color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
