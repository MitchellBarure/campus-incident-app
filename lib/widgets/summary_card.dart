import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/utils/incident_filters.dart';
import '../models/incident_status.dart';

/// Four summary cards in a 2 x 2 grid: total, submitted, in progress and
/// resolved. [totalLabel] is "My Reports" for students, "All Reports" for
/// staff.
class SummaryGrid extends StatelessWidget {
  const SummaryGrid({
    super.key,
    required this.counts,
    required this.totalLabel,
  });

  final IncidentCounts counts;
  final String totalLabel;

  @override
  Widget build(BuildContext context) {
    final cards = [
      SummaryCard(
        label: totalLabel,
        count: counts.total,
        icon: Icons.assignment_outlined,
        color: AppColors.primary,
        backgroundColor: AppColors.primaryLight,
      ),
      _statusCard(
        IncidentStatus.submitted,
        counts.submitted,
        Icons.schedule_outlined,
      ),
      _statusCard(
        IncidentStatus.inProgress,
        counts.inProgress,
        Icons.build_circle_outlined,
      ),
      _statusCard(
        IncidentStatus.resolved,
        counts.resolved,
        Icons.check_circle_outline,
      ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 2.1,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: cards,
    );
  }

  Widget _statusCard(IncidentStatus status, int count, IconData icon) {
    return SummaryCard(
      label: status.label,
      count: count,
      icon: icon,
      color: status.color,
      backgroundColor: status.backgroundColor,
    );
  }
}

/// A small card with an icon, a big number and a label,
/// e.g. "3 - In Progress". Used on Home and the Staff dashboard.
class SummaryCard extends StatelessWidget {
  const SummaryCard({
    super.key,
    required this.label,
    required this.count,
    required this.icon,
    required this.color,
    required this.backgroundColor,
  });

  final String label;
  final int count;
  final IconData icon;

  /// Colour of the icon.
  final Color color;

  /// Light colour behind the icon.
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$count',
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      height: 1.1,
                    ),
                  ),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.labelSmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
